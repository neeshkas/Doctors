# Маршруты API B2B сервиса партнёров
import uuid
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import Partner
from app.schemas import PartnerCreate, PartnerResponse, PartnerUpdate

router = APIRouter()


@router.post("/partners/", response_model=PartnerResponse, status_code=201)
async def register_partner(data: PartnerCreate, db: AsyncSession = Depends(get_db)):
    """Зарегистрировать нового партнёра"""
    partner = Partner(
        user_id=data.user_id,
        company_name=data.company_name,
        partner_type=data.partner_type,
        contact_email=data.contact_email,
        contact_phone=data.contact_phone,
        description=data.description,
    )
    db.add(partner)
    await db.flush()
    await db.refresh(partner)
    return partner


@router.get("/partners/", response_model=list[PartnerResponse])
async def list_partners(
    partner_type: Optional[str] = Query(None, description="Фильтр по типу партнёра"),
    is_active: Optional[bool] = Query(None, description="Фильтр по активности"),
    db: AsyncSession = Depends(get_db),
):
    """Получить список всех партнёров с возможностью фильтрации"""
    query = select(Partner)
    if partner_type is not None:
        query = query.where(Partner.partner_type == partner_type)
    if is_active is not None:
        query = query.where(Partner.is_active == is_active)
    query = query.order_by(Partner.created_at.desc())

    result = await db.execute(query)
    return result.scalars().all()


@router.get("/partners/{partner_id}", response_model=PartnerResponse)
async def get_partner(partner_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Получить детальную информацию о партнёре"""
    result = await db.execute(select(Partner).where(Partner.id == partner_id))
    partner = result.scalar_one_or_none()
    if not partner:
        raise HTTPException(status_code=404, detail="Партнёр не найден")
    return partner


@router.put("/partners/{partner_id}", response_model=PartnerResponse)
async def update_partner(
    partner_id: uuid.UUID, data: PartnerUpdate, db: AsyncSession = Depends(get_db)
):
    """Обновить информацию о партнёре"""
    result = await db.execute(select(Partner).where(Partner.id == partner_id))
    partner = result.scalar_one_or_none()
    if not partner:
        raise HTTPException(status_code=404, detail="Партнёр не найден")

    # Обновляем только переданные поля
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(partner, field, value)

    await db.flush()
    await db.refresh(partner)
    return partner


async def _proxy_to_travel_service(endpoint: str, payload: dict) -> dict:
    """Проксирование запроса в сервис путешествий"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.TRAVEL_SERVICE_URL}{endpoint}",
                json=payload,
            )
            if response.status_code in (200, 201):
                return response.json()
            else:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Ошибка от сервиса путешествий: {response.text}",
                )
    except httpx.RequestError:
        raise HTTPException(
            status_code=503,
            detail="Сервис путешествий недоступен",
        )


@router.post("/partners/{partner_id}/offers/flight")
async def create_flight_offer(
    partner_id: uuid.UUID, payload: dict, db: AsyncSession = Depends(get_db)
):
    """Создать предложение авиаперелёта (проксируется в travel-service)"""
    # Проверяем, что партнёр существует и активен
    result = await db.execute(select(Partner).where(Partner.id == partner_id))
    partner = result.scalar_one_or_none()
    if not partner:
        raise HTTPException(status_code=404, detail="Партнёр не найден")
    if not partner.is_active:
        raise HTTPException(status_code=403, detail="Партнёр деактивирован")

    # Добавляем идентификатор партнёра в данные предложения
    payload["partner_id"] = str(partner_id)
    return await _proxy_to_travel_service("/travel/flights", payload)


@router.post("/partners/{partner_id}/offers/hotel")
async def create_hotel_offer(
    partner_id: uuid.UUID, payload: dict, db: AsyncSession = Depends(get_db)
):
    """Создать предложение отеля (проксируется в travel-service)"""
    result = await db.execute(select(Partner).where(Partner.id == partner_id))
    partner = result.scalar_one_or_none()
    if not partner:
        raise HTTPException(status_code=404, detail="Партнёр не найден")
    if not partner.is_active:
        raise HTTPException(status_code=403, detail="Партнёр деактивирован")

    payload["partner_id"] = str(partner_id)
    return await _proxy_to_travel_service("/travel/hotels", payload)


@router.post("/partners/{partner_id}/offers/clinic")
async def create_clinic_offer(
    partner_id: uuid.UUID, payload: dict, db: AsyncSession = Depends(get_db)
):
    """Создать предложение клиники (проксируется в travel-service)"""
    result = await db.execute(select(Partner).where(Partner.id == partner_id))
    partner = result.scalar_one_or_none()
    if not partner:
        raise HTTPException(status_code=404, detail="Партнёр не найден")
    if not partner.is_active:
        raise HTTPException(status_code=403, detail="Партнёр деактивирован")

    payload["partner_id"] = str(partner_id)
    return await _proxy_to_travel_service("/travel/clinics", payload)


@router.post("/partners/{partner_id}/offers/excursion")
async def create_excursion_offer(
    partner_id: uuid.UUID, payload: dict, db: AsyncSession = Depends(get_db)
):
    """Создать предложение экскурсии (проксируется в travel-service)"""
    result = await db.execute(select(Partner).where(Partner.id == partner_id))
    partner = result.scalar_one_or_none()
    if not partner:
        raise HTTPException(status_code=404, detail="Партнёр не найден")
    if not partner.is_active:
        raise HTTPException(status_code=403, detail="Партнёр деактивирован")

    payload["partner_id"] = str(partner_id)
    return await _proxy_to_travel_service("/travel/excursions", payload)
