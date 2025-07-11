from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    SECRET_KEY: str = "default_secret_key_for_dev_only"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    ELASTICSEARCH_HOST: str = "localhost"
    ELASTICSEARCH_PORT: int = 9200  # ✅ Add this line
    CORPUS_FILES_DIR: str = "/app/corpus_files"

    class Config:
        env_file = ".env"

settings = Settings()
