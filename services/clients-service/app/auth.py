# Аутентификация через внешний сервис авторизации
import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings

# Схема авторизации через Bearer-токен
security = HTTPBearer()


async def verify_token(token: str) -> dict:
    """
    Проверка токена через сервис авторизации.
    Отправляет GET-запрос на /auth/me с Bearer-токеном.
    Возвращает данные текущего пользователя.
    """
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.AUTH_SERVICE_URL}/auth/me",
                headers={"Authorization": f"Bearer {token}"},
            )
            if response.status_code == 200:
                return response.json()
            # Токен невалиден или истёк
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Недействительный токен авторизации",
            )
        except httpx.RequestError:
            # Сервис авторизации недоступен
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Сервис авторизации недоступен",
            )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Зависимость для получения текущего пользователя.
    Извлекает токен из заголовка Authorization и проверяет его.
    """
    token = credentials.credentials
    user = await verify_token(token)
    return user
