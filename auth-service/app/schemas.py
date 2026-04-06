"""Pydantic-схемы для валидации запросов и ответов."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr

from app.models import Role


class UserCreate(BaseModel):
    """Схема для регистрации нового пользователя."""

    email: EmailStr
    password: str
    full_name: str
    role: Role = Role.CLIENT


class UserLogin(BaseModel):
    """Схема для входа пользователя."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Схема ответа с данными пользователя."""

    id: UUID
    email: str
    full_name: str
    role: Role
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    """Схема JWT-токена."""

    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Данные, извлечённые из JWT-токена."""

    user_id: str
    email: str
    role: str
