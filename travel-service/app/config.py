# Конфигурация сервиса путешествий
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки приложения, загружаемые из переменных окружения."""

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@travel-db:5432/travel_db"

    class Config:
        env_file = ".env"


# Глобальный экземпляр настроек
settings = Settings()
