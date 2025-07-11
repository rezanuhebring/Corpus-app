from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    ELASTICSEARCH_HOST: str  # <--- REMOVE THE "localhost" DEFAULT
    ELASTICSEARCH_PORT: int = 9200
    CORPUS_FILES_DIR: str = "/app/corpus_files"

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8' # Add encoding for consistency

settings = Settings()