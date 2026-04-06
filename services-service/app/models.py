"""Модели базы данных для каталога медицинских услуг."""

import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Enum, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class ServiceCategory(str, enum.Enum):
    """Категории медицинских услуг."""

    ONLINE_CONSULTATION = "ONLINE_CONSULTATION"      # Онлайн-консультация
    OFFLINE_CONSULTATION = "OFFLINE_CONSULTATION"    # Офлайн-консультация
    CHECKUP_KOREA = "CHECKUP_KOREA"                  # Чекап в Корее
    TREATMENT_KOREA = "TREATMENT_KOREA"              # Лечение в Корее
    EXAMINATION_KOREA = "EXAMINATION_KOREA"          # Обследование в Корее


class MedicalService(Base):
    """Модель медицинской услуги."""

    __tablename__ = "medical_services"

    # Уникальный идентификатор услуги
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # Категория услуги
    category: Mapped[ServiceCategory] = mapped_column(
        Enum(ServiceCategory), nullable=False
    )
    # Название услуги
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Описание услуги
    description: Mapped[str] = mapped_column(Text, nullable=True)
    # Требуется ли поездка для получения услуги
    requires_travel: Mapped[bool] = mapped_column(Boolean, default=False)
    # Базовая стоимость услуги
    base_price: Mapped[Decimal] = mapped_column(
        Numeric(precision=12, scale=2), nullable=True
    )
    # Активна ли услуга (доступна для заказа)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    # Дата и время создания записи
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
