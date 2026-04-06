# Конфигурация сервиса клиентов
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки приложения, загружаемые из переменных окружения."""

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@clients-db:5432/clients_db"
    AUTH_SERVICE_URL: str = "http://auth-service:8000"

    class Config:
        env_file = ".env"


# Глобальный экземпляр настроек
settings = Settings()
