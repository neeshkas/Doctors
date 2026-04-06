"""Заполнение базы данных начальными медицинскими услугами."""

from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import MedicalService, ServiceCategory


# Начальный набор медицинских услуг DoctorsHunter
INITIAL_SERVICES = [
    {
        "category": ServiceCategory.ONLINE_CONSULTATION,
        "name": "Онлайн-консультация",
        "description": "Удалённая консультация с врачом по видеосвязи",
        "requires_travel": False,
        "base_price": Decimal("5000.00"),
    },
    {
        "category": ServiceCategory.OFFLINE_CONSULTATION,
        "name": "Офлайн-консультация",
        "description": "Очная консультация с врачом в клинике",
        "requires_travel": False,
        "base_price": Decimal("7000.00"),
    },
    {
        "category": ServiceCategory.CHECKUP_KOREA,
        "name": "Чекап в Корее",
        "description": "Комплексное медицинское обследование в клиниках Южной Кореи",
        "requires_travel": True,
        "base_price": Decimal("150000.00"),
    },
    {
        "category": ServiceCategory.TREATMENT_KOREA,
        "name": "Лечение в Корее",
        "description": "Курс лечения в медицинских центрах Южной Кореи",
        "requires_travel": True,
        "base_price": Decimal("300000.00"),
    },
    {
        "category": ServiceCategory.EXAMINATION_KOREA,
        "name": "Обследование в Корее",
        "description": "Диагностическое обследование в клиниках Южной Кореи",
        "requires_travel": True,
        "base_price": Decimal("200000.00"),
    },
]


async def seed_services(session: AsyncSession) -> None:
    """Заполняет базу начальными услугами, если таблица пуста."""
    result = await session.execute(select(MedicalService).limit(1))
    existing = result.scalars().first()

    if existing is not None:
        # Данные уже существуют, пропускаем заполнение
        return

    for service_data in INITIAL_SERVICES:
        service = MedicalService(**service_data)
        session.add(service)

    await session.commit()
