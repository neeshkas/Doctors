# Точка входа в приложение DoctorsHunter Orders Service

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routes import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Создание таблиц при запуске приложения."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


# Инициализация приложения
app = FastAPI(
    title="DoctorsHunter Orders Service",
    description="Центральный сервис управления заказами CRM DoctorsHunter",
    version="1.0.0",
    lifespan=lifespan,
)

# Настройка CORS для взаимодействия с фронтендом
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключение маршрутов
app.include_router(router)


@app.get("/health")
async def health_check():
    """Проверка работоспособности сервиса."""
    return {"status": "ok", "service": "orders-service"}
