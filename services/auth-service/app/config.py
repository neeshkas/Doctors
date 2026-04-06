"""Конфигурация сервиса аутентификации DoctorsHunter."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Настройки приложения, загружаемые из переменных окружения."""

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@auth-db:5432/auth_db"
    SECRET_KEY: str = "doctorshunter-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    class Config:
        env_file = ".env"


settings = Settings()
