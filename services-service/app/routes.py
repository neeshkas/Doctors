"""Маршруты API для управления каталогом медицинских услуг."""

import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import MedicalService
from app.schemas import ServiceCreate, ServiceResponse, ServiceUpdate

router = APIRouter(prefix="/services", tags=["services"])


@router.get("/", response_model=List[ServiceResponse])
async def list_services(db: AsyncSession = Depends(get_db)):
    """Получить список всех медицинских услуг."""
    result = await db.execute(select(MedicalService))
    services = result.scalars().all()
    return services


@router.get("/{service_id}", response_model=ServiceResponse)
async def get_service(service_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Получить детали конкретной услуги по её идентификатору."""
    result = await db.execute(
        select(MedicalService).where(MedicalService.id == service_id)
    )
    service = result.scalars().first()

    if service is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Услуга не найдена",
        )

    return service


@router.post("/", response_model=ServiceResponse, status_code=status.HTTP_201_CREATED)
async def create_service(
    service_data: ServiceCreate, db: AsyncSession = Depends(get_db)
):
    """Создать новую медицинскую услугу (только для администратора, проверка на уровне gateway)."""
    service = MedicalService(**service_data.model_dump())
    db.add(service)
    await db.flush()
    await db.refresh(service)
    return service


@router.put("/{service_id}", response_model=ServiceResponse)
async def update_service(
    service_id: uuid.UUID,
    service_data: ServiceUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Обновить данные существующей медицинской услуги."""
    result = await db.execute(
        select(MedicalService).where(MedicalService.id == service_id)
    )
    service = result.scalars().first()

    if service is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Услуга не найдена",
        )

    # Обновляем только переданные поля (не None)
    update_fields = service_data.model_dump(exclude_unset=True)
    for field, value in update_fields.items():
        setattr(service, field, value)

    await db.flush()
    await db.refresh(service)
    return service
