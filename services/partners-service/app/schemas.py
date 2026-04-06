# Pydantic-схемы для валидации данных сервиса партнёров
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field

from app.models import PartnerType


class PartnerCreate(BaseModel):
    """Схема для регистрации нового партнёра"""
    user_id: uuid.UUID = Field(..., description="Идентификатор пользователя из сервиса авторизации")
    company_name: str = Field(..., max_length=255, description="Название компании")
    partner_type: PartnerType = Field(..., description="Тип партнёра")
    contact_email: str = Field(..., max_length=255, description="Контактный email")
    contact_phone: Optional[str] = Field(None, max_length=50, description="Контактный телефон")
    description: Optional[str] = Field(None, description="Описание компании")


class PartnerUpdate(BaseModel):
    """Схема для обновления данных партнёра"""
    company_name: Optional[str] = Field(None, max_length=255, description="Название компании")
    partner_type: Optional[PartnerType] = Field(None, description="Тип партнёра")
    contact_email: Optional[str] = Field(None, max_length=255, description="Контактный email")
    contact_phone: Optional[str] = Field(None, max_length=50, description="Контактный телефон")
    description: Optional[str] = Field(None, description="Описание компании")
    is_active: Optional[bool] = Field(None, description="Флаг активности")


class PartnerResponse(BaseModel):
    """Схема ответа с данными партнёра"""
    id: uuid.UUID
    user_id: uuid.UUID
    company_name: str
    partner_type: PartnerType
    contact_email: str
    contact_phone: Optional[str]
    description: Optional[str]
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
