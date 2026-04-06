# Маршруты для управления авиаперелётами
from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Flight
from app.schemas import FlightCreate, FlightResponse, FlightUpdate

router = APIRouter(prefix="/flights", tags=["Авиаперелёты"])


@router.get("/", response_model=list[FlightResponse])
async def list_flights(
    departure_city: str | None = Query(None, description="Фильтр по городу вылета"),
    arrival_city: str | None = Query(None, description="Фильтр по городу прилёта"),
    date: date | None = Query(None, description="Фильтр по дате вылета"),
    db: AsyncSession = Depends(get_db),
):
    """Получить список авиаперелётов с возможностью фильтрации."""
    query = select(Flight)
    if departure_city:
        query = query.where(Flight.departure_city == departure_city)
    if arrival_city:
        query = query.where(Flight.arrival_city == arrival_city)
    if date:
        # Фильтруем по дате (без учёта времени)
        query = query.where(Flight.departure_date >= date)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{flight_id}", response_model=FlightResponse)
async def get_flight(flight_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить авиаперелёт по идентификатору."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if not flight:
        raise HTTPException(status_code=404, detail="Авиаперелёт не найден")
    return flight


@router.post("/", response_model=FlightResponse, status_code=201)
async def create_flight(data: FlightCreate, db: AsyncSession = Depends(get_db)):
    """Создать новый авиаперелёт."""
    flight = Flight(**data.model_dump())
    db.add(flight)
    await db.flush()
    await db.refresh(flight)
    return flight


@router.put("/{flight_id}", response_model=FlightResponse)
async def update_flight(flight_id: UUID, data: FlightUpdate, db: AsyncSession = Depends(get_db)):
    """Обновить данные авиаперелёта."""
    result = await db.execute(select(Flight).where(Flight.id == flight_id))
    flight = result.scalar_one_or_none()
    if not flight:
        raise HTTPException(status_code=404, detail="Авиаперелёт не найден")
    # Обновляем только переданные поля
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(flight, field, value)
    await db.flush()
    await db.refresh(flight)
    return flight
