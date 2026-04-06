# Главный модуль сервиса путешествий DoctorsHunter CRM
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routes.clinics import router as clinics_router
from app.routes.doctors import router as doctors_router
from app.routes.excursions import router as excursions_router
from app.routes.flights import router as flights_router
from app.routes.hotels import router as hotels_router
from app.routes.visas import router as visas_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Создание таблиц при запуске приложения."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="Travel Service",
    description="Сервис управления путешествиями для DoctorsHunter CRM",
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

# Подключение всех маршрутов под общим префиксом /travel
app.include_router(flights_router, prefix="/travel")
app.include_router(hotels_router, prefix="/travel")
app.include_router(clinics_router, prefix="/travel")
app.include_router(doctors_router, prefix="/travel")
app.include_router(visas_router, prefix="/travel")
app.include_router(excursions_router, prefix="/travel")
