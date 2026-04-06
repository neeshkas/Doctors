"""Точка входа приложения DoctorsHunter Auth Service."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine, async_session
from app.routes import router
from app.seed import seed_users


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Жизненный цикл приложения: создание таблиц и начальных данных."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Создаём тестовых пользователей при первом запуске
    async with async_session() as session:
        await seed_users(session)
        await session.commit()

    yield


app = FastAPI(
    title="DoctorsHunter Auth Service",
    description="Сервис аутентификации и авторизации CRM-системы DoctorsHunter",
    version="1.0.0",
    lifespan=lifespan,
)

# Настройка CORS (разрешаем все источники для разработки)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем маршруты аутентификации
app.include_router(router)
