# Pydantic-схемы для валидации запросов и ответов

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models import OrderStatus


# === Позиции заказа (OrderItem) ===

class OrderItemCreate(BaseModel):
    """Схема для добавления позиции в заказ."""
    service_id: UUID
    quantity: int = 1


class OrderItemResponse(BaseModel):
    """Ответ с информацией о позиции заказа."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    order_id: UUID
    service_id: UUID
    service_name: str
    price: Decimal
    quantity: int


# === Клиенты заказа (OrderClient) ===

class OrderClientCreate(BaseModel):
    """Схема для привязки клиента к заказу."""
    client_id: UUID
    is_primary: bool = False


class OrderClientResponse(BaseModel):
    """Ответ с информацией о клиенте заказа."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    order_id: UUID
    client_id: UUID
    client_name: str
    is_primary: bool


# === Заказ (Order) ===

class OrderCreate(BaseModel):
    """Схема создания нового заказа."""
    requires_travel: bool = False
    items: list[OrderItemCreate] = []
    client_ids: list[UUID] = []


class OrderUpdate(BaseModel):
    """Схема обновления заказа. Все поля опциональны."""
    flight_id: Optional[UUID] = None
    hotel_id: Optional[UUID] = None
    clinic_id: Optional[UUID] = None
    doctor_id: Optional[UUID] = None
    visa_id: Optional[UUID] = None
    excursion_confirmed: Optional[bool] = None
    notes: Optional[str] = None
    status: Optional[OrderStatus] = None


class OrderResponse(BaseModel):
    """Полный ответ с информацией о заказе, включая позиции и клиентов."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: OrderStatus
    requires_travel: bool
    flight_id: Optional[UUID] = None
    hotel_id: Optional[UUID] = None
    clinic_id: Optional[UUID] = None
    doctor_id: Optional[UUID] = None
    visa_id: Optional[UUID] = None
    excursion_confirmed: bool
    total_amount: Decimal
    paid_amount: Decimal
    notes: Optional[str] = None
    created_by: UUID
    created_at: datetime
    updated_at: datetime

    # Вложенные объекты
    items: list[OrderItemResponse] = []
    clients: list[OrderClientResponse] = []


class OrderListResponse(BaseModel):
    """Упрощённый ответ для табличного отображения списка заказов (мастер-панель)."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: OrderStatus
    requires_travel: bool
    flight_id: Optional[UUID] = None
    hotel_id: Optional[UUID] = None
    clinic_id: Optional[UUID] = None
    doctor_id: Optional[UUID] = None
    visa_id: Optional[UUID] = None
    excursion_confirmed: bool = False
    total_amount: Decimal
    paid_amount: Decimal
    client_names: str  # Имена клиентов через запятую
    service_names: str = ""  # Названия услуг через запятую
    created_at: datetime


class WorkspaceTask(BaseModel):
    """Задача для рабочего пространства менеджера по роли."""
    order_id: UUID
    client_names: str
    field_to_fill: str       # Поле, которое нужно заполнить
    current_value: Optional[str] = None  # Текущее значение (обычно None)
    created_at: datetime
