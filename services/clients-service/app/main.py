# Главный модуль сервиса клиентов DoctorsHunter
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routes import router

app = FastAPI(
    title="DoctorsHunter Clients Service",
    description="Микросервис управления профилями клиентов CRM DoctorsHunter",
    version="1.0.0",
)

# Настройка CORS для доступа с любых источников
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключение маршрутов
app.include_router(router)


@app.on_event("startup")
async def on_startup():
    """Создание таблиц в базе данных при запуске приложения."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@app.get("/health")
async def health_check():
    """Проверка работоспособности сервиса."""
    return {"status": "ok", "service": "clients-service"}
