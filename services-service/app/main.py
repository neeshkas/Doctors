"""Точка входа микросервиса каталога медицинских услуг DoctorsHunter."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import async_session, engine, Base
from app.routes import router
from app.seed import seed_services


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Жизненный цикл приложения: создание таблиц и заполнение начальными данными."""
    # Создаём таблицы в базе данных при запуске
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Заполняем начальными данными
    async with async_session() as session:
        await seed_services(session)

    yield


app = FastAPI(
    title="DoctorsHunter Services Catalog",
    description="Микросервис каталога медицинских услуг DoctorsHunter CRM",
    version="1.0.0",
    lifespan=lifespan,
)

# Настройка CORS для доступа из фронтенда
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем маршруты каталога услуг
app.include_router(router)
