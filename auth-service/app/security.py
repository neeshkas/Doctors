"""Модуль безопасности: хеширование паролей, JWT-токены, проверка прав доступа."""

from datetime import datetime, timedelta
from typing import List

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import Role, User
from app.schemas import TokenData

# Контекст для хеширования паролей (bcrypt)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Схема OAuth2 для извлечения токена из заголовка Authorization
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

# Роли с полным административным доступом
ADMIN_ROLES: List[Role] = [Role.COORDINATOR, Role.MANAGER]


def hash_password(password: str) -> str:
    """Хешировать пароль с помощью bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Проверить пароль по хешу."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict) -> str:
    """Создать JWT-токен доступа с указанными данными."""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> TokenData:
    """Декодировать и валидировать JWT-токен."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        email: str = payload.get("email")
        role: str = payload.get("role")
        if user_id is None or email is None or role is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Невалидный токен: отсутствуют обязательные поля",
            )
        return TokenData(user_id=user_id, email=email, role=role)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Невалидный токен доступа",
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Получить текущего пользователя по JWT-токену (зависимость FastAPI)."""
    token_data = decode_access_token(token)
    result = await db.execute(select(User).where(User.id == token_data.user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Пользователь не найден",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Учётная запись деактивирована",
        )
    return user


def role_required(allowed_roles: List[Role]):
    """
    Фабрика зависимостей для проверки роли пользователя.

    Администраторские роли (COORDINATOR, MANAGER) всегда имеют доступ.
    """

    async def check_role(current_user: User = Depends(get_current_user)) -> User:
        """Проверить, что роль пользователя входит в список разрешённых."""
        # Администраторы имеют полный доступ
        if current_user.role in ADMIN_ROLES:
            return current_user
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Недостаточно прав для выполнения данного действия",
            )
        return current_user

    return check_role
