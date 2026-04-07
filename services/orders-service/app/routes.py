# Маршруты API сервиса заказов

from decimal import Decimal
from typing import Any, Optional
from uuid import UUID

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import check_field_permissions, get_current_user
from app.config import settings
from app.database import get_db
from app.models import Order, OrderClient, OrderItem, OrderStatus
from app.schemas import (
    OrderClientCreate,
    OrderClientResponse,
    OrderCreate,
    OrderItemCreate,
    OrderItemResponse,
    OrderListResponse,
    OrderResponse,
    OrderUpdate,
    WorkspaceTask,
)

router = APIRouter(prefix="/orders", tags=["orders"])

# Внутренний роутер для межсервисных вызовов (без аутентификации)
# Доступен только внутри Docker-сети, внешний доступ заблокирован на уровне nginx
internal_router = APIRouter(prefix="/orders/internal", tags=["Internal"])


# === Вспомогательные функции для обращения к внешним сервисам ===

async def fetch_service_info(service_id: UUID) -> dict[str, Any]:
    """Получает информацию об услуге из services-service."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.SERVICES_SERVICE_URL}/services/{service_id}",
                timeout=10.0,
            )
        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Сервис услуг недоступен",
            )

    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Услуга {service_id} не найдена",
        )

    return response.json()


async def fetch_client_info(client_id: UUID) -> dict[str, Any]:
    """Получает информацию о клиенте из clients-service (через внутренний эндпоинт без auth)."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.CLIENTS_SERVICE_URL}/clients/internal/{client_id}",
                timeout=10.0,
            )
        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Сервис клиентов недоступен",
            )

    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Клиент {client_id} не найден",
        )

    return response.json()


async def fetch_paid_amount(order_id: UUID) -> Decimal:
    """Получает сумму оплат по заказу из payments-service."""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.PAYMENTS_SERVICE_URL}/payments/summary/{order_id}",
                timeout=10.0,
            )
        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Сервис оплат недоступен",
            )

    if response.status_code != 200:
        # Если платежей нет — возвращаем 0
        return Decimal("0")

    data = response.json()
    return Decimal(str(data.get("paid_amount", 0)))


async def get_order_or_404(order_id: UUID, db: AsyncSession) -> Order:
    """Получает заказ по ID или выбрасывает 404."""
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ {order_id} не найден",
        )
    return order


def get_client_names(order: Order) -> str:
    """Формирует строку с именами клиентов через запятую."""
    return ", ".join(c.client_name for c in order.clients) if order.clients else ""


# === Эндпоинты ===

@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    data: OrderCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Создать новый заказ. Загружает данные услуг и клиентов из внешних сервисов."""

    # Создаём заказ
    order = Order(
        requires_travel=data.requires_travel,
        created_by=UUID(current_user["id"]),
    )
    db.add(order)
    await db.flush()  # Получаем ID заказа

    total = Decimal("0")

    # Добавляем позиции заказа
    for item_data in data.items:
        service_info = await fetch_service_info(item_data.service_id)
        price = Decimal(str(service_info.get("base_price", 0) or 0))

        order_item = OrderItem(
            order_id=order.id,
            service_id=item_data.service_id,
            service_name=service_info.get("name", "Неизвестная услуга"),
            price=price,
            quantity=item_data.quantity,
        )
        db.add(order_item)
        total += price * item_data.quantity

    # Добавляем клиентов
    for i, client_id in enumerate(data.client_ids):
        client_info = await fetch_client_info(client_id)
        client_name = f"{client_info.get('first_name', '')} {client_info.get('last_name', '')}".strip() or "Неизвестный клиент"

        order_client = OrderClient(
            order_id=order.id,
            client_id=client_id,
            client_name=client_name,
            is_primary=(i == 0),  # Первый клиент считается основным
        )
        db.add(order_client)

    # Обновляем общую сумму
    order.total_amount = total
    await db.flush()
    await db.refresh(order)

    return order


@router.get("/", response_model=list[OrderListResponse])
async def list_orders(
    status_filter: Optional[OrderStatus] = Query(None, alias="status"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Получить список всех заказов с пагинацией и фильтрацией по статусу."""
    query = select(Order).offset(skip).limit(limit).order_by(Order.created_at.desc())

    if status_filter:
        query = query.where(Order.status == status_filter)

    result = await db.execute(query)
    orders = result.scalars().all()

    # Формируем упрощённый ответ для мастер-панели
    return [
        OrderListResponse(
            id=order.id,
            status=order.status,
            requires_travel=order.requires_travel,
            flight_id=order.flight_id,
            hotel_id=order.hotel_id,
            clinic_id=order.clinic_id,
            doctor_id=order.doctor_id,
            visa_id=order.visa_id,
            excursion_confirmed=order.excursion_confirmed,
            total_amount=order.total_amount,
            paid_amount=order.paid_amount,
            client_names=get_client_names(order),
            service_names=", ".join(i.service_name for i in order.items) if order.items else "",
            created_at=order.created_at,
        )
        for order in orders
    ]



# === Рабочее пространство (workspace) ===
# ВАЖНО: этот маршрут ДОЛЖЕН быть определён ДО /{order_id}, иначе
# FastAPI попытается распарсить "workspace" как UUID

# Маппинг роли на условия фильтрации незаполненных полей
WORKSPACE_ROLE_MAP: dict[str, dict[str, Any]] = {
    "FLIGHTS_MANAGER": {"field": "flight_id", "requires_travel": True},
    "HOTELS_MANAGER": {"field": "hotel_id", "requires_travel": True},
    "CLINICS_MANAGER": {"field": "clinic_id", "requires_travel": True},
    "DOCTORS_MANAGER": {"field": "doctor_id", "requires_travel": True},
    "VISAS_MANAGER": {"field": "visa_id", "requires_travel": True},
    "EXCURSIONS_MANAGER": {"field": "excursion_confirmed", "requires_travel": True},
}


@router.get("/workspace/{role}", response_model=list[WorkspaceTask])
async def get_workspace_tasks(
    role: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Получить список задач для рабочего пространства менеджера.
    Возвращает заказы, в которых поле, соответствующее роли, ещё не заполнено.
    """
    role_config = WORKSPACE_ROLE_MAP.get(role.upper())
    if not role_config:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Неизвестная роль: {role}. Доступные: {', '.join(WORKSPACE_ROLE_MAP.keys())}",
        )

    field_name = role_config["field"]
    needs_travel = role_config["requires_travel"]

    # Формируем запрос: активные (не отменённые) заказы с незаполненным полем
    query = select(Order).where(Order.status != OrderStatus.CANCELLED)

    # Для менеджеров путешествий — только заказы с requires_travel=True
    if needs_travel:
        query = query.where(Order.requires_travel.is_(True))

    # Фильтруем по незаполненному полю
    if field_name == "excursion_confirmed":
        query = query.where(Order.excursion_confirmed.is_(False))
    else:
        column = getattr(Order, field_name)
        query = query.where(column.is_(None))

    query = query.order_by(Order.created_at.asc())

    result = await db.execute(query)
    orders = result.scalars().all()

    tasks = []
    for order in orders:
        current_value = getattr(order, field_name)
        tasks.append(
            WorkspaceTask(
                order_id=order.id,
                client_names=get_client_names(order),
                field_to_fill=field_name,
                current_value=str(current_value) if current_value is not None else None,
                created_at=order.created_at,
            )
        )

    return tasks


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Получить подробную информацию о заказе, включая позиции и клиентов."""
    order = await get_order_or_404(order_id, db)
    return order


@router.put("/{order_id}", response_model=OrderResponse)
async def update_order(
    order_id: UUID,
    data: OrderUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Обновить заказ. Доступные поля зависят от роли пользователя:
    - FLIGHTS_MANAGER: только flight_id
    - HOTELS_MANAGER: только hotel_id
    - CLINICS_MANAGER: только clinic_id
    - DOCTORS_MANAGER: только doctor_id
    - VISAS_MANAGER: только visa_id
    - EXCURSIONS_MANAGER: только excursion_confirmed
    - COORDINATOR, MANAGER: все поля
    """
    order = await get_order_or_404(order_id, db)

    # Получаем только заполненные поля
    update_data = data.model_dump(exclude_unset=True)

    # Проверяем права на редактирование полей
    check_field_permissions(current_user, update_data)

    # Применяем обновления
    for field, value in update_data.items():
        if value is not None:
            setattr(order, field, value)

    await db.flush()
    await db.refresh(order)
    return order


@router.delete("/{order_id}", status_code=status.HTTP_200_OK)
async def cancel_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Отменить заказ (установить статус CANCELLED)."""
    order = await get_order_or_404(order_id, db)
    order.status = OrderStatus.CANCELLED
    await db.flush()
    return {"detail": f"Заказ {order_id} отменён"}


# === Позиции заказа ===

@router.post("/{order_id}/items", response_model=OrderItemResponse, status_code=status.HTTP_201_CREATED)
async def add_order_item(
    order_id: UUID,
    data: OrderItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Добавить позицию (услугу) в заказ."""
    order = await get_order_or_404(order_id, db)

    # Загружаем информацию об услуге
    service_info = await fetch_service_info(data.service_id)
    price = Decimal(str(service_info.get("base_price", 0) or 0))

    item = OrderItem(
        order_id=order.id,
        service_id=data.service_id,
        service_name=service_info.get("name", "Неизвестная услуга"),
        price=price,
        quantity=data.quantity,
    )
    db.add(item)

    # Пересчитываем общую сумму
    order.total_amount += price * data.quantity
    await db.flush()
    await db.refresh(item)

    return item


@router.delete("/{order_id}/items/{item_id}", status_code=status.HTTP_200_OK)
async def remove_order_item(
    order_id: UUID,
    item_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Удалить позицию из заказа."""
    result = await db.execute(
        select(OrderItem).where(OrderItem.id == item_id, OrderItem.order_id == order_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Позиция {item_id} не найдена в заказе {order_id}",
        )

    # Уменьшаем общую сумму заказа
    order = await get_order_or_404(order_id, db)
    order.total_amount -= item.price * item.quantity

    await db.delete(item)
    await db.flush()

    return {"detail": f"Позиция {item_id} удалена из заказа {order_id}"}


# === Клиенты заказа ===

@router.post("/{order_id}/clients", response_model=OrderClientResponse, status_code=status.HTTP_201_CREATED)
async def add_order_client(
    order_id: UUID,
    data: OrderClientCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Привязать клиента к заказу."""
    order = await get_order_or_404(order_id, db)

    # Загружаем информацию о клиенте
    client_info = await fetch_client_info(data.client_id)

    first_name = client_info.get("first_name", "")
    last_name = client_info.get("last_name", "")
    client_name = f"{first_name} {last_name}".strip() or "Неизвестный клиент"

    order_client = OrderClient(
        order_id=order.id,
        client_id=data.client_id,
        client_name=client_name,
        is_primary=data.is_primary,
    )
    db.add(order_client)
    await db.flush()
    await db.refresh(order_client)

    return order_client


@router.delete("/{order_id}/clients/{client_id}", status_code=status.HTTP_200_OK)
async def remove_order_client(
    order_id: UUID,
    client_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Отвязать клиента от заказа."""
    result = await db.execute(
        select(OrderClient).where(
            OrderClient.client_id == client_id, OrderClient.order_id == order_id
        )
    )
    order_client = result.scalar_one_or_none()
    if not order_client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Клиент {client_id} не найден в заказе {order_id}",
        )

    await db.delete(order_client)
    await db.flush()

    return {"detail": f"Клиент {client_id} удалён из заказа {order_id}"}


# === Пересчёт сумм ===

@router.put("/{order_id}/recalculate", response_model=OrderResponse)
async def recalculate_order(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Пересчитать суммы заказа:
    - total_amount из позиций заказа
    - paid_amount из payments-service
    """
    order = await get_order_or_404(order_id, db)

    # Пересчёт total_amount из позиций
    total = Decimal("0")
    for item in order.items:
        total += item.price * item.quantity
    order.total_amount = total

    # Получаем оплаченную сумму из payments-service
    order.paid_amount = await fetch_paid_amount(order_id)

    # Автоматическое обновление статуса на основе оплаты
    if order.status != OrderStatus.CANCELLED:
        if order.paid_amount >= order.total_amount and order.total_amount > 0:
            order.status = OrderStatus.FULLY_PAID
        elif order.paid_amount > 0:
            order.status = OrderStatus.ACTIVE
        else:
            order.status = OrderStatus.NOT_PAID

    await db.flush()
    await db.refresh(order)

    return order


# === Внутренние эндпоинты для межсервисных вызовов (без аутентификации) ===

@internal_router.get("/{order_id}", response_model=OrderResponse)
async def get_order_internal(
    order_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Внутренний эндпоинт: получить заказ по ID без аутентификации (для payments-service)."""
    order = await get_order_or_404(order_id, db)
    return order
