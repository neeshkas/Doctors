# Маршруты для управления экскурсиями
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Excursion
from app.schemas import ExcursionCreate, ExcursionResponse, ExcursionUpdate

router = APIRouter(prefix="/excursions", tags=["Экскурсии"])


@router.get("/", response_model=list[ExcursionResponse])
async def list_excursions(
    city: str | None = Query(None, description="Фильтр по городу"),
    db: AsyncSession = Depends(get_db),
):
    """Получить список экскурсий с возможностью фильтрации."""
    query = select(Excursion)
    if city:
        query = query.where(Excursion.city == city)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{excursion_id}", response_model=ExcursionResponse)
async def get_excursion(excursion_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить экскурсию по идентификатору."""
    result = await db.execute(select(Excursion).where(Excursion.id == excursion_id))
    excursion = result.scalar_one_or_none()
    if not excursion:
        raise HTTPException(status_code=404, detail="Экскурсия не найдена")
    return excursion


@router.post("/", response_model=ExcursionResponse, status_code=201)
async def create_excursion(data: ExcursionCreate, db: AsyncSession = Depends(get_db)):
    """Создать новую экскурсию."""
    excursion = Excursion(**data.model_dump())
    db.add(excursion)
    await db.flush()
    await db.refresh(excursion)
    return excursion


@router.put("/{excursion_id}", response_model=ExcursionResponse)
async def update_excursion(
    excursion_id: UUID,
    data: ExcursionUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Обновить данные экскурсии."""
    result = await db.execute(select(Excursion).where(Excursion.id == excursion_id))
    excursion = result.scalar_one_or_none()
    if not excursion:
        raise HTTPException(status_code=404, detail="Экскурсия не найдена")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(excursion, field, value)
    await db.flush()
    await db.refresh(excursion)
    return excursion
