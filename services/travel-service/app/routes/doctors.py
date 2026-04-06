# Маршруты для управления врачами
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Doctor
from app.schemas import DoctorCreate, DoctorResponse, DoctorUpdate

router = APIRouter(prefix="/doctors", tags=["Врачи"])


@router.get("/", response_model=list[DoctorResponse])
async def list_doctors(
    specialization: str | None = Query(None, description="Фильтр по специализации"),
    db: AsyncSession = Depends(get_db),
):
    """Получить список врачей с возможностью фильтрации."""
    query = select(Doctor)
    if specialization:
        query = query.where(Doctor.specialization == specialization)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/by-clinic/{clinic_id}", response_model=list[DoctorResponse])
async def get_doctors_by_clinic(clinic_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить список врачей по идентификатору клиники."""
    result = await db.execute(select(Doctor).where(Doctor.clinic_id == clinic_id))
    return result.scalars().all()


@router.get("/{doctor_id}", response_model=DoctorResponse)
async def get_doctor(doctor_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить врача по идентификатору."""
    result = await db.execute(select(Doctor).where(Doctor.id == doctor_id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Врач не найден")
    return doctor


@router.post("/", response_model=DoctorResponse, status_code=201)
async def create_doctor(data: DoctorCreate, db: AsyncSession = Depends(get_db)):
    """Создать нового врача."""
    doctor = Doctor(**data.model_dump())
    db.add(doctor)
    await db.flush()
    await db.refresh(doctor)
    return doctor


@router.put("/{doctor_id}", response_model=DoctorResponse)
async def update_doctor(doctor_id: UUID, data: DoctorUpdate, db: AsyncSession = Depends(get_db)):
    """Обновить данные врача."""
    result = await db.execute(select(Doctor).where(Doctor.id == doctor_id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Врач не найден")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(doctor, field, value)
    await db.flush()
    await db.refresh(doctor)
    return doctor
