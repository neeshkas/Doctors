# Модели базы данных для сервиса оплат
import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class PaymentMethod(str, enum.Enum):
    """Способ оплаты"""
    CASH = "cash"           # Наличные
    CARD = "card"           # Банковская карта
    TRANSFER = "transfer"   # Банковский перевод
    OTHER = "other"         # Другой способ


class PaymentStatus(str, enum.Enum):
    """Статус платежа"""
    PENDING = "pending"       # Ожидает подтверждения
    COMPLETED = "completed"   # Завершён
    REFUNDED = "refunded"     # Возвращён


class Receipt(Base):
    """Квитанция об оплате"""
    __tablename__ = "receipts"

    # Уникальный идентификатор квитанции
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # Идентификатор заказа, к которому относится квитанция
    order_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    # Сумма платежа
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    # Способ оплаты
    payment_method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod), nullable=False
    )
    # Статус платежа (по умолчанию — завершён)
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus), nullable=False, default=PaymentStatus.COMPLETED
    )
    # Описание платежа (необязательное)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Дата и время оплаты
    paid_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=func.now())
    # Дата создания записи
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
