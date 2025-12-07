import os

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # App
    PROJECT_NAME: str = "RAG_SYSRH"

    # Redis
    REDIS_HOST: str = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", 6379))

    model_config = SettingsConfigDict(env_ignore_empty=True, extra="ignore")


settings = Settings()
