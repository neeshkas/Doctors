# Конфигурация сервиса заказов DoctorsHunter

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки приложения, загружаемые из переменных окружения."""

    # Подключение к базе данных
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@orders-db:5432/orders_db"

    # URL-адреса внешних микросервисов
    AUTH_SERVICE_URL: str = "http://auth-service:8000"
    TRAVEL_SERVICE_URL: str = "http://travel-service:8000"
    SERVICES_SERVICE_URL: str = "http://services-service:8000"
    PAYMENTS_SERVICE_URL: str = "http://payments-service:8000"
    CLIENTS_SERVICE_URL: str = "http://clients-service:8000"

    class Config:
        env_file = ".env"


# Глобальный экземпляр настроек
settings = Settings()
