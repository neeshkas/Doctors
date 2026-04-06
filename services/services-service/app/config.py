"""Конфигурация сервиса медицинских услуг."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки приложения, загружаемые из переменных окружения."""

    DATABASE_URL: str = (
        "postgresql+asyncpg://postgres:postgres@services-db:5432/services_db"
    )

    class Config:
        env_file = ".env"


settings = Settings()
