# Начальные данные: тестовые пользователи для разработки

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Role, User
from app.security import hash_password


# Тестовые аккаунты для разработки
SEED_USERS = [
    {
        "email": "admin@doctorshunter.com",
        "password": "admin123",
        "full_name": "Администратор",
        "role": Role.COORDINATOR,
    },
    {
        "email": "manager@doctorshunter.com",
        "password": "manager123",
        "full_name": "Менеджер",
        "role": Role.MANAGER,
    },
    {
        "email": "flights@doctorshunter.com",
        "password": "flights123",
        "full_name": "Менеджер авиабилетов",
        "role": Role.FLIGHTS_MANAGER,
    },
    {
        "email": "hotels@doctorshunter.com",
        "password": "hotels123",
        "full_name": "Менеджер отелей",
        "role": Role.HOTELS_MANAGER,
    },
    {
        "email": "clinics@doctorshunter.com",
        "password": "clinics123",
        "full_name": "Менеджер клиник",
        "role": Role.CLINICS_MANAGER,
    },
    {
        "email": "doctors@doctorshunter.com",
        "password": "doctors123",
        "full_name": "Менеджер врачей",
        "role": Role.DOCTORS_MANAGER,
    },
    {
        "email": "visas@doctorshunter.com",
        "password": "visas123",
        "full_name": "Менеджер виз",
        "role": Role.VISAS_MANAGER,
    },
    {
        "email": "excursions@doctorshunter.com",
        "password": "excursions123",
        "full_name": "Менеджер экскурсий",
        "role": Role.EXCURSIONS_MANAGER,
    },
    {
        "email": "client@doctorshunter.com",
        "password": "client123",
        "full_name": "Тестовый клиент",
        "role": Role.CLIENT,
    },
    {
        "email": "partner@doctorshunter.com",
        "password": "partner123",
        "full_name": "Тестовый партнёр",
        "role": Role.PARTNER,
    },
]


async def seed_users(db: AsyncSession) -> None:
    """Создать тестовых пользователей, если таблица пуста."""
    result = await db.execute(select(User).limit(1))
    if result.scalar_one_or_none() is not None:
        return  # Пользователи уже есть — пропускаем

    for user_data in SEED_USERS:
        user = User(
            email=user_data["email"],
            hashed_password=hash_password(user_data["password"]),
            full_name=user_data["full_name"],
            role=user_data["role"],
        )
        db.add(user)

    await db.flush()
