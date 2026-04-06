# Главный файл приложения — B2B сервис партнёров DoctorsHunter
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routes import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Создаём таблицы в базе данных при запуске приложения"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="DoctorsHunter Partners Service",
    description="B2B сервис партнёров для платформы DoctorsHunter",
    version="1.0.0",
    lifespan=lifespan,
)

# Настройка CORS для межсервисного взаимодействия
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем маршруты
app.include_router(router)
