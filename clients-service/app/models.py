# Модели базы данных для сервиса клиентов
import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Client(Base):
    """Модель профиля клиента в системе DoctorsHunter."""

    __tablename__ = "clients"

    # Уникальный идентификатор клиента
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # Идентификатор пользователя из сервиса авторизации
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), unique=True, nullable=False, index=True
    )
    # Имя клиента
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    # Фамилия клиента
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    # Отчество (необязательное поле)
    middle_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    # Номер телефона
    phone: Mapped[str] = mapped_column(String(20), nullable=False)
    # Электронная почта
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    # Номер паспорта (необязательное поле)
    passport_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    # Дата рождения (необязательное поле)
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    # Страна проживания
    country: Mapped[str] = mapped_column(String(100), default="Казахстан", server_default="Казахстан")
    # Город проживания (необязательное поле)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    # Дата создания записи
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    # Дата последнего обновления записи
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
