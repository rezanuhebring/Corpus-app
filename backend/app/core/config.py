from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """
    This class defines the application's configuration settings.
    It is configured to ONLY read from system environment variables.
    """
    
    # Required environment variables
    SECRET_KEY: str
    ELASTICSEARCH_HOST: str
    
    # Environment variables with default values
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    ELASTICSEARCH_PORT: int = 9200
    CORPUS_FILES_DIR: str = "/app/corpus_files"

# Create a single, global settings instance that will be used by the application
settings = Settings()