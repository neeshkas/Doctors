# Маршруты API сервиса оплат и квитанций
import uuid
from decimal import Decimal

import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import Receipt
from app.schemas import (
    OrderPaymentSummary,
    ReceiptCreate,
    ReceiptResponse,
    ReceiptUpdate,
)

router = APIRouter()


@router.post("/payments/receipts", response_model=ReceiptResponse, status_code=201)
async def create_receipt(data: ReceiptCreate, db: AsyncSession = Depends(get_db)):
    """Создать квитанцию для заказа"""
    receipt = Receipt(
        order_id=data.order_id,
        amount=data.amount,
        payment_method=data.payment_method,
        description=data.description,
    )
    # Если дата оплаты указана явно — используем её
    if data.paid_at is not None:
        receipt.paid_at = data.paid_at

    db.add(receipt)
    await db.flush()
    await db.refresh(receipt)
    return receipt


@router.get("/payments/receipts/{receipt_id}", response_model=ReceiptResponse)
async def get_receipt(receipt_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Получить квитанцию по идентификатору"""
    result = await db.execute(select(Receipt).where(Receipt.id == receipt_id))
    receipt = result.scalar_one_or_none()
    if not receipt:
        raise HTTPException(status_code=404, detail="Квитанция не найдена")
    return receipt


@router.get("/payments/by-order/{order_id}", response_model=list[ReceiptResponse])
async def get_receipts_by_order(order_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Получить список квитанций по идентификатору заказа"""
    result = await db.execute(
        select(Receipt).where(Receipt.order_id == order_id).order_by(Receipt.created_at.desc())
    )
    return result.scalars().all()


@router.get("/payments/summary/{order_id}", response_model=OrderPaymentSummary)
async def get_payment_summary(order_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Получить сводку по оплатам заказа: общая сумма, оплачено, остаток, переплата"""
    # Получаем общую сумму заказа из сервиса заказов (через внутренний эндпоинт без auth)
    total_amount = Decimal("0.00")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.ORDERS_SERVICE_URL}/orders/internal/{order_id}"
            )
            if response.status_code == 200:
                order_data = response.json()
                total_amount = Decimal(str(order_data.get("total_amount", "0.00")))
            else:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Не удалось получить данные заказа из сервиса заказов",
                )
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Сервис заказов недоступен",
        )

    # Считаем оплаченную сумму по квитанциям
    result = await db.execute(
        select(Receipt).where(Receipt.order_id == order_id)
    )
    receipts = result.scalars().all()
    paid_amount = sum(r.amount for r in receipts if r.status.value == "completed")
    remaining = max(Decimal("0.00"), total_amount - paid_amount)
    overpayment = max(Decimal("0.00"), paid_amount - total_amount)

    return OrderPaymentSummary(
        order_id=order_id,
        total_amount=total_amount,
        paid_amount=paid_amount,
        remaining_amount=remaining,
        overpayment=overpayment,
        receipts_count=len(receipts),
    )


@router.put("/payments/receipts/{receipt_id}", response_model=ReceiptResponse)
async def update_receipt(
    receipt_id: uuid.UUID, data: ReceiptUpdate, db: AsyncSession = Depends(get_db)
):
    """Обновить статус или описание квитанции"""
    result = await db.execute(select(Receipt).where(Receipt.id == receipt_id))
    receipt = result.scalar_one_or_none()
    if not receipt:
        raise HTTPException(status_code=404, detail="Квитанция не найдена")

    # Обновляем только переданные поля
    if data.status is not None:
        receipt.status = data.status
    if data.description is not None:
        receipt.description = data.description

    await db.flush()
    await db.refresh(receipt)
    return receipt


@router.delete("/payments/receipts/{receipt_id}", status_code=204)
async def delete_receipt(receipt_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Удалить квитанцию"""
    result = await db.execute(select(Receipt).where(Receipt.id == receipt_id))
    receipt = result.scalar_one_or_none()
    if not receipt:
        raise HTTPException(status_code=404, detail="Квитанция не найдена")

    await db.delete(receipt)
    await db.flush()
