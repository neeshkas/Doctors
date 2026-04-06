# Маршруты для управления клиниками
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Clinic
from app.schemas import ClinicCreate, ClinicResponse, ClinicUpdate

router = APIRouter(prefix="/clinics", tags=["Клиники"])


@router.get("/", response_model=list[ClinicResponse])
async def list_clinics(
    city: str | None = Query(None, description="Фильтр по городу"),
    specialization: str | None = Query(None, description="Фильтр по специализации"),
    db: AsyncSession = Depends(get_db),
):
    """Получить список клиник с возможностью фильтрации."""
    query = select(Clinic)
    if city:
        query = query.where(Clinic.city == city)
    if specialization:
        query = query.where(Clinic.specialization == specialization)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{clinic_id}", response_model=ClinicResponse)
async def get_clinic(clinic_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить клинику по идентификатору."""
    result = await db.execute(select(Clinic).where(Clinic.id == clinic_id))
    clinic = result.scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Клиника не найдена")
    return clinic


@router.post("/", response_model=ClinicResponse, status_code=201)
async def create_clinic(data: ClinicCreate, db: AsyncSession = Depends(get_db)):
    """Создать новую клинику."""
    clinic = Clinic(**data.model_dump())
    db.add(clinic)
    await db.flush()
    await db.refresh(clinic)
    return clinic


@router.put("/{clinic_id}", response_model=ClinicResponse)
async def update_clinic(clinic_id: UUID, data: ClinicUpdate, db: AsyncSession = Depends(get_db)):
    """Обновить данные клиники."""
    result = await db.execute(select(Clinic).where(Clinic.id == clinic_id))
    clinic = result.scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Клиника не найдена")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(clinic, field, value)
    await db.flush()
    await db.refresh(clinic)
    return clinic
