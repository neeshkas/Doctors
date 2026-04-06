# Маршруты для управления отелями
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Hotel
from app.schemas import HotelCreate, HotelResponse, HotelUpdate

router = APIRouter(prefix="/hotels", tags=["Отели"])


@router.get("/", response_model=list[HotelResponse])
async def list_hotels(
    city: str | None = Query(None, description="Фильтр по городу"),
    star_rating: int | None = Query(None, description="Фильтр по звёздности"),
    db: AsyncSession = Depends(get_db),
):
    """Получить список отелей с возможностью фильтрации."""
    query = select(Hotel)
    if city:
        query = query.where(Hotel.city == city)
    if star_rating:
        query = query.where(Hotel.star_rating == star_rating)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{hotel_id}", response_model=HotelResponse)
async def get_hotel(hotel_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить отель по идентификатору."""
    result = await db.execute(select(Hotel).where(Hotel.id == hotel_id))
    hotel = result.scalar_one_or_none()
    if not hotel:
        raise HTTPException(status_code=404, detail="Отель не найден")
    return hotel


@router.post("/", response_model=HotelResponse, status_code=201)
async def create_hotel(data: HotelCreate, db: AsyncSession = Depends(get_db)):
    """Создать новый отель."""
    hotel = Hotel(**data.model_dump())
    db.add(hotel)
    await db.flush()
    await db.refresh(hotel)
    return hotel


@router.put("/{hotel_id}", response_model=HotelResponse)
async def update_hotel(hotel_id: UUID, data: HotelUpdate, db: AsyncSession = Depends(get_db)):
    """Обновить данные отеля."""
    result = await db.execute(select(Hotel).where(Hotel.id == hotel_id))
    hotel = result.scalar_one_or_none()
    if not hotel:
        raise HTTPException(status_code=404, detail="Отель не найден")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(hotel, field, value)
    await db.flush()
    await db.refresh(hotel)
    return hotel
