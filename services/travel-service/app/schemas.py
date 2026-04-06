# Pydantic-схемы для валидации запросов и ответов
import enum
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


# --- Статус визы ---

class VisaStatus(str, enum.Enum):
    """Статусы визовой заявки."""
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


# --- Авиаперелёты ---

class FlightCreate(BaseModel):
    """Схема создания авиаперелёта."""
    partner_id: UUID
    airline: str
    flight_number: str
    departure_city: str
    arrival_city: str
    departure_date: datetime
    arrival_date: datetime
    price: Decimal
    seats_available: int
    is_active: bool = True


class FlightUpdate(BaseModel):
    """Схема обновления авиаперелёта."""
    partner_id: UUID | None = None
    airline: str | None = None
    flight_number: str | None = None
    departure_city: str | None = None
    arrival_city: str | None = None
    departure_date: datetime | None = None
    arrival_date: datetime | None = None
    price: Decimal | None = None
    seats_available: int | None = None
    is_active: bool | None = None


class FlightResponse(BaseModel):
    """Схема ответа для авиаперелёта."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    partner_id: UUID
    airline: str
    flight_number: str
    departure_city: str
    arrival_city: str
    departure_date: datetime
    arrival_date: datetime
    price: Decimal
    seats_available: int
    is_active: bool
    created_at: datetime


# --- Отели ---

class HotelCreate(BaseModel):
    """Схема создания отеля."""
    partner_id: UUID
    name: str
    city: str
    address: str
    star_rating: int
    price_per_night: Decimal
    description: str | None = None
    is_active: bool = True


class HotelUpdate(BaseModel):
    """Схема обновления отеля."""
    partner_id: UUID | None = None
    name: str | None = None
    city: str | None = None
    address: str | None = None
    star_rating: int | None = None
    price_per_night: Decimal | None = None
    description: str | None = None
    is_active: bool | None = None


class HotelResponse(BaseModel):
    """Схема ответа для отеля."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    partner_id: UUID
    name: str
    city: str
    address: str
    star_rating: int
    price_per_night: Decimal
    description: str | None
    is_active: bool
    created_at: datetime


# --- Клиники ---

class ClinicCreate(BaseModel):
    """Схема создания клиники."""
    partner_id: UUID
    name: str
    city: str
    address: str
    specialization: str
    description: str | None = None
    rating: float = 0.0
    is_active: bool = True


class ClinicUpdate(BaseModel):
    """Схема обновления клиники."""
    partner_id: UUID | None = None
    name: str | None = None
    city: str | None = None
    address: str | None = None
    specialization: str | None = None
    description: str | None = None
    rating: float | None = None
    is_active: bool | None = None


class ClinicResponse(BaseModel):
    """Схема ответа для клиники."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    partner_id: UUID
    name: str
    city: str
    address: str
    specialization: str
    description: str | None
    rating: float
    is_active: bool
    created_at: datetime


# --- Врачи ---

class DoctorCreate(BaseModel):
    """Схема создания врача."""
    clinic_id: UUID
    full_name: str
    specialization: str
    experience_years: int = 0
    description: str | None = None
    rating: float = 0.0
    is_active: bool = True


class DoctorUpdate(BaseModel):
    """Схема обновления врача."""
    clinic_id: UUID | None = None
    full_name: str | None = None
    specialization: str | None = None
    experience_years: int | None = None
    description: str | None = None
    rating: float | None = None
    is_active: bool | None = None


class DoctorResponse(BaseModel):
    """Схема ответа для врача."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    clinic_id: UUID
    full_name: str
    specialization: str
    experience_years: int
    description: str | None
    rating: float
    is_active: bool
    created_at: datetime


# --- Визовые заявки ---

class VisaApplicationCreate(BaseModel):
    """Схема создания визовой заявки."""
    client_id: UUID
    order_id: UUID
    passport_number: str
    notes: str | None = None


class VisaApplicationUpdate(BaseModel):
    """Схема обновления визовой заявки."""
    notes: str | None = None


class VisaStatusUpdate(BaseModel):
    """Схема обновления статуса визовой заявки."""
    status: VisaStatus
    notes: str | None = None


class VisaApplicationResponse(BaseModel):
    """Схема ответа для визовой заявки."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    client_id: UUID
    order_id: UUID
    status: VisaStatus
    passport_number: str
    applied_at: datetime
    resolved_at: datetime | None
    notes: str | None
    created_at: datetime


# --- Экскурсии ---

class ExcursionCreate(BaseModel):
    """Схема создания экскурсии."""
    partner_id: UUID
    name: str
    city: str
    description: str | None = None
    price: Decimal
    duration_hours: float
    is_active: bool = True


class ExcursionUpdate(BaseModel):
    """Схема обновления экскурсии."""
    partner_id: UUID | None = None
    name: str | None = None
    city: str | None = None
    description: str | None = None
    price: Decimal | None = None
    duration_hours: float | None = None
    is_active: bool | None = None


class ExcursionResponse(BaseModel):
    """Схема ответа для экскурсии."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    partner_id: UUID
    name: str
    city: str
    description: str | None
    price: Decimal
    duration_hours: float
    is_active: bool
    created_at: datetime
