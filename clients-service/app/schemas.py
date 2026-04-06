# Pydantic-схемы для валидации данных клиентов
import uuid
from datetime import date, datetime

from pydantic import BaseModel, EmailStr


class ClientCreate(BaseModel):
    """Схема для создания нового клиента."""

    user_id: uuid.UUID
    first_name: str
    last_name: str
    middle_name: str | None = None
    phone: str
    email: EmailStr
    passport_number: str | None = None
    date_of_birth: date | None = None
    country: str = "Казахстан"
    city: str | None = None


class ClientUpdate(BaseModel):
    """Схема для обновления данных клиента. Все поля необязательные."""

    first_name: str | None = None
    last_name: str | None = None
    middle_name: str | None = None
    phone: str | None = None
    email: EmailStr | None = None
    passport_number: str | None = None
    date_of_birth: date | None = None
    country: str | None = None
    city: str | None = None


class ClientResponse(BaseModel):
    """Схема ответа с данными клиента."""

    id: uuid.UUID
    user_id: uuid.UUID
    first_name: str
    last_name: str
    middle_name: str | None = None
    phone: str
    email: str
    passport_number: str | None = None
    date_of_birth: date | None = None
    country: str
    city: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
