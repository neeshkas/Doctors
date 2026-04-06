"""Настройка базы данных: асинхронный движок и сессии SQLAlchemy."""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

from app.config import settings

# Асинхронный движок для подключения к PostgreSQL
engine = create_async_engine(settings.DATABASE_URL, echo=True)

# Фабрика асинхронных сессий
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# Базовый класс для моделей
Base = declarative_base()


async def get_db():
    """Генератор асинхронной сессии БД для внедрения зависимостей."""
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
