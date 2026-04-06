# Настройка асинхронного подключения к базе данных

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

# Создаём асинхронный движок SQLAlchemy
engine = create_async_engine(settings.DATABASE_URL, echo=False)

# Фабрика асинхронных сессий
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    """Базовый класс для всех моделей."""
    pass


async def get_db():
    """Зависимость FastAPI для получения сессии базы данных."""
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
