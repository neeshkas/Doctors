# Маршруты для управления визовыми заявками
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import VisaApplication, VisaStatus
from app.schemas import VisaApplicationCreate, VisaApplicationResponse, VisaStatusUpdate

router = APIRouter(prefix="/visas", tags=["Визовые заявки"])


@router.post("/", response_model=VisaApplicationResponse, status_code=201)
async def create_visa_application(data: VisaApplicationCreate, db: AsyncSession = Depends(get_db)):
    """Создать новую визовую заявку."""
    visa = VisaApplication(**data.model_dump())
    db.add(visa)
    await db.flush()
    await db.refresh(visa)
    return visa


@router.get("/{visa_id}", response_model=VisaApplicationResponse)
async def get_visa(visa_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить визовую заявку по идентификатору."""
    result = await db.execute(select(VisaApplication).where(VisaApplication.id == visa_id))
    visa = result.scalar_one_or_none()
    if not visa:
        raise HTTPException(status_code=404, detail="Визовая заявка не найдена")
    return visa


@router.get("/by-order/{order_id}", response_model=list[VisaApplicationResponse])
async def get_visas_by_order(order_id: UUID, db: AsyncSession = Depends(get_db)):
    """Получить визовые заявки по идентификатору заказа."""
    result = await db.execute(
        select(VisaApplication).where(VisaApplication.order_id == order_id)
    )
    return result.scalars().all()


@router.put("/{visa_id}/status", response_model=VisaApplicationResponse)
async def update_visa_status(
    visa_id: UUID,
    data: VisaStatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Обновить статус визовой заявки."""
    result = await db.execute(select(VisaApplication).where(VisaApplication.id == visa_id))
    visa = result.scalar_one_or_none()
    if not visa:
        raise HTTPException(status_code=404, detail="Визовая заявка не найдена")
    visa.status = data.status
    if data.notes is not None:
        visa.notes = data.notes
    # Устанавливаем дату решения при финальных статусах
    if data.status in (VisaStatus.APPROVED, VisaStatus.REJECTED):
        visa.resolved_at = datetime.utcnow()
    await db.flush()
    await db.refresh(visa)
    return visa
