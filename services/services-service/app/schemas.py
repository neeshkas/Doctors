"""Pydantic-схемы для валидации и сериализации данных услуг."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.models import ServiceCategory


class ServiceCreate(BaseModel):
    """Схема для создания новой услуги."""

    category: ServiceCategory
    name: str
    description: Optional[str] = None
    requires_travel: bool = False
    base_price: Optional[Decimal] = None
    is_active: bool = True


class ServiceUpdate(BaseModel):
    """Схема для обновления существующей услуги."""

    category: Optional[ServiceCategory] = None
    name: Optional[str] = None
    description: Optional[str] = None
    requires_travel: Optional[bool] = None
    base_price: Optional[Decimal] = None
    is_active: Optional[bool] = None


class ServiceResponse(BaseModel):
    """Схема ответа с данными услуги."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    category: ServiceCategory
    name: str
    description: Optional[str] = None
    requires_travel: bool
    base_price: Optional[Decimal] = None
    is_active: bool
    created_at: datetime
