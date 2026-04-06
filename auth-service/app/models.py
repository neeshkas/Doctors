"""Модели базы данных для сервиса аутентификации."""

import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, Enum
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class Role(str, enum.Enum):
    """Роли пользователей в системе DoctorsHunter."""

    COORDINATOR = "COORDINATOR"             # Координатор — полный доступ
    MANAGER = "MANAGER"                     # Менеджер — полный доступ
    FLIGHTS_MANAGER = "FLIGHTS_MANAGER"     # Менеджер по авиабилетам
    HOTELS_MANAGER = "HOTELS_MANAGER"       # Менеджер по отелям
    CLINICS_MANAGER = "CLINICS_MANAGER"     # Менеджер по клиникам
    DOCTORS_MANAGER = "DOCTORS_MANAGER"     # Менеджер по врачам
    VISAS_MANAGER = "VISAS_MANAGER"         # Менеджер по визам
    EXCURSIONS_MANAGER = "EXCURSIONS_MANAGER"  # Менеджер по экскурсиям
    CLIENT = "CLIENT"                       # Клиент
    PARTNER = "PARTNER"                     # Партнёр


class User(Base):
    """Модель пользователя системы."""

    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(Enum(Role), nullable=False, default=Role.CLIENT)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
