# Асинхронное подключение к базе данных через SQLAlchemy
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

# Асинхронный движок для подключения к PostgreSQL
engine = create_async_engine(settings.DATABASE_URL, echo=False)

# Фабрика асинхронных сессий
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    """Базовый класс для всех моделей."""
    pass


async def get_db():
    """Генератор асинхронных сессий для внедрения зависимостей."""
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
