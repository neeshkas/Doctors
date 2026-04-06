# Pydantic-схемы для валидации данных сервиса оплат
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field

from app.models import PaymentMethod, PaymentStatus


class ReceiptCreate(BaseModel):
    """Схема для создания квитанции"""
    order_id: uuid.UUID = Field(..., description="Идентификатор заказа")
    amount: Decimal = Field(..., gt=0, description="Сумма платежа")
    payment_method: PaymentMethod = Field(..., description="Способ оплаты")
    description: Optional[str] = Field(None, description="Описание платежа")
    paid_at: Optional[datetime] = Field(None, description="Дата и время оплаты (если не указано — текущее время)")


class ReceiptUpdate(BaseModel):
    """Схема для обновления квитанции"""
    status: Optional[PaymentStatus] = Field(None, description="Новый статус платежа")
    description: Optional[str] = Field(None, description="Новое описание платежа")


class ReceiptResponse(BaseModel):
    """Схема ответа с данными квитанции"""
    id: uuid.UUID
    order_id: uuid.UUID
    amount: Decimal
    payment_method: PaymentMethod
    status: PaymentStatus
    description: Optional[str]
    paid_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class OrderPaymentSummary(BaseModel):
    """Сводка по оплатам заказа"""
    order_id: uuid.UUID = Field(..., description="Идентификатор заказа")
    total_amount: Decimal = Field(..., description="Общая сумма заказа (из сервиса заказов)")
    paid_amount: Decimal = Field(..., description="Оплаченная сумма")
    remaining_amount: Decimal = Field(..., description="Оставшаяся к оплате сумма")
    overpayment: Decimal = Field(..., description="Переплата (если есть)")
    receipts_count: int = Field(..., description="Количество квитанций")
