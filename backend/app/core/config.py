from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # This tells Pydantic to ignore any extra variables it finds
    # in the environment that are not defined in this class.
    model_config = SettingsConfigDict(extra='ignore')

    # Core settings defined in the class
    SECRET_KEY: str = "default_secret_key_for_dev_only"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    
    # Elasticsearch settings
    ELASTICSEARCH_HOST: str = "localhost"
    
    # File storage path
    CORPUS_FILES_DIR: str = "/app/corpus_files"

# --- THIS IS THE CRITICAL FIX ---
# We must create an instance of the class for other modules to import.
settings = Settings()