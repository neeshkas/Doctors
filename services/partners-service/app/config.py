# Конфигурация B2B сервиса партнёров
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки сервиса партнёров"""

    # URL базы данных для асинхронного подключения через asyncpg
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@partners-db:5432/partners_db"

    # URL сервиса путешествий для проксирования предложений
    TRAVEL_SERVICE_URL: str = "http://travel-service:8000"

    class Config:
        env_file = ".env"


# Глобальный экземпляр настроек
settings = Settings()
