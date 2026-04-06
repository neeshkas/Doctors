# Аутентификация и авторизация через auth-service

from typing import Any

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings

# Схема авторизации через Bearer-токен
security = HTTPBearer()

# Соответствие ролей и полей, которые они могут редактировать
ROLE_FIELD_PERMISSIONS: dict[str, list[str]] = {
    "FLIGHTS_MANAGER": ["flight_id"],
    "HOTELS_MANAGER": ["hotel_id"],
    "CLINICS_MANAGER": ["clinic_id"],
    "DOCTORS_MANAGER": ["doctor_id"],
    "VISAS_MANAGER": ["visa_id"],
    "EXCURSIONS_MANAGER": ["excursion_confirmed"],
}

# Роли с полным доступом к редактированию всех полей
FULL_ACCESS_ROLES = {"COORDINATOR", "MANAGER"}


async def verify_token(token: str) -> dict[str, Any]:
    """
    Проверяет токен через auth-service.
    Возвращает данные пользователя или выбрасывает исключение.
    """
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.AUTH_SERVICE_URL}/auth/me",
                headers={"Authorization": f"Bearer {token}"},
                timeout=10.0,
            )
        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Сервис авторизации недоступен",
            )

    if response.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Недействительный токен авторизации",
        )

    return response.json()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict[str, Any]:
    """
    Зависимость FastAPI: извлекает и проверяет текущего пользователя
    по Bearer-токену из заголовка Authorization.
    """
    user = await verify_token(credentials.credentials)
    return user


def check_field_permissions(user: dict[str, Any], update_data: dict[str, Any]) -> None:
    """
    Проверяет, имеет ли пользователь право редактировать указанные поля.
    Координаторы и менеджеры могут редактировать всё.
    Остальные роли — только свои поля.
    """
    user_role = user.get("role", "")

    # Координаторы и менеджеры имеют полный доступ
    if user_role in FULL_ACCESS_ROLES:
        return

    # Определяем разрешённые поля для роли пользователя
    allowed_fields = set(ROLE_FIELD_PERMISSIONS.get(user_role, []))

    # Поля, которые пользователь пытается обновить (не None)
    requested_fields = {key for key, value in update_data.items() if value is not None}

    # Проверяем, что все запрашиваемые поля входят в список разрешённых
    forbidden_fields = requested_fields - allowed_fields
    if forbidden_fields:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Роль {user_role} не имеет доступа к полям: {', '.join(forbidden_fields)}",
        )
