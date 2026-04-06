# Модели базы данных для сервиса заказов

import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class OrderStatus(str, enum.Enum):
    """Статусы заказа."""
    NOT_PAID = "NOT_PAID"           # Не оплачен
    ACTIVE = "ACTIVE"               # Активный (частично оплачен)
    FULLY_PAID = "FULLY_PAID"       # Полностью оплачен
    CANCELLED = "CANCELLED"         # Отменён


class Order(Base):
    """Заказ — центральная сущность CRM."""
    __tablename__ = "orders"

    # Основные поля
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus), default=OrderStatus.NOT_PAID, nullable=False
    )

    # Флаг необходимости организации путешествия
    requires_travel: Mapped[bool] = mapped_column(Boolean, default=False)

    # Связи с внешними сервисами (заполняются менеджерами по ролям)
    flight_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    hotel_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    clinic_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    visa_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)

    # Подтверждение экскурсии
    excursion_confirmed: Mapped[bool] = mapped_column(Boolean, default=False)

    # Финансы
    total_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"))
    paid_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"))

    # Дополнительная информация
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Кто создал заказ (UUID пользователя из auth-service)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)

    # Временные метки
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Связи с дочерними таблицами
    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", lazy="selectin"
    )
    clients: Mapped[list["OrderClient"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", lazy="selectin"
    )


class OrderItem(Base):
    """Позиция заказа — услуга из services-service."""
    __tablename__ = "order_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), nullable=False
    )

    # Ссылка на услугу из services-service
    service_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    # Денормализованное название для быстрого отображения
    service_name: Mapped[str] = mapped_column(String(255), nullable=False)

    # Цена и количество
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=1)

    # Связь с заказом
    order: Mapped["Order"] = relationship(back_populates="items")


class OrderClient(Base):
    """Клиент заказа — ссылка на clients-service."""
    __tablename__ = "order_clients"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), nullable=False
    )

    # Ссылка на клиента из clients-service
    client_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    # Денормализованное имя для быстрого отображения
    client_name: Mapped[str] = mapped_column(String(255), nullable=False)

    # Основной клиент заказа
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)

    # Связь с заказом
    order: Mapped["Order"] = relationship(back_populates="clients")
