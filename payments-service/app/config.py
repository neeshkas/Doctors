# Конфигурация сервиса оплат и квитанций
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки сервиса оплат"""

    # URL базы данных для асинхронного подключения через asyncpg
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@payments-db:5432/payments_db"

    # URL сервиса заказов для получения информации о суммах заказов
    ORDERS_SERVICE_URL: str = "http://orders-service:8000"

    class Config:
        env_file = ".env"


# Глобальный экземпляр настроек
settings = Settings()
