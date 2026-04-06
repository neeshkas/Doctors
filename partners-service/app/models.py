# Модели базы данных для B2B сервиса партнёров
import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class PartnerType(str, enum.Enum):
    """Тип партнёра"""
    AIRLINE = "airline"       # Авиакомпания
    HOTEL = "hotel"           # Отель
    CLINIC = "clinic"         # Клиника
    EXCURSION = "excursion"   # Экскурсионное агентство


class Partner(Base):
    """Партнёр (B2B)"""
    __tablename__ = "partners"

    # Уникальный идентификатор партнёра
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # Идентификатор пользователя из сервиса авторизации
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    # Название компании
    company_name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Тип партнёра
    partner_type: Mapped[PartnerType] = mapped_column(Enum(PartnerType), nullable=False)
    # Контактный email
    contact_email: Mapped[str] = mapped_column(String(255), nullable=False)
    # Контактный телефон
    contact_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    # Описание компании
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Флаг активности партнёра
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    # Дата создания записи
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, server_default=func.now())
