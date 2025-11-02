"""Configuration settings for the application."""

from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """Application settings."""

    # Serveur
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True
    ENVIRONMENT: str = "development"

    # Base de données
    DATABASE_URL: str = "sqlite:///./attendance.db"

    # JWT et sécurité
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # YOLO Models
    YOLO_FACE_MODEL: str = "yolov8n-face.pt"
    YOLO_WEAPON_MODEL: str = "yolov8n-weapons.pt"
    YOLO_ANIMAL_MODEL: str = "yolov8n.pt"
    CONFIDENCE_THRESHOLD: float = 0.5
    IOU_THRESHOLD: float = 0.45

    # Reconnaissance faciale
    FACE_RECOGNITION_TOLERANCE: float = 0.6
    FACE_RECOGNITION_MODEL: str = "hog"  # ou cnn
    USE_INSIGHTFACE: bool = True
    INSIGHTFACE_MODEL: str = "buffalo_l"

    # Azure Cloud Storage
    AZURE_STORAGE_CONNECTION_STRING: Optional[str] = None
    AZURE_STORAGE_CONTAINER_NAME: str = "face-recognition"
    AZURE_COSMOS_ENDPOINT: Optional[str] = None
    AZURE_COSMOS_KEY: Optional[str] = None
    AZURE_COSMOS_DATABASE_NAME: str = "attendance_db"

    # Notifications
    SENDGRID_API_KEY: Optional[str] = None
    HR_EMAIL: str = "hr@company.com"
    TWILIO_ACCOUNT_SID: Optional[str] = None
    TWILIO_AUTH_TOKEN: Optional[str] = None
    TWILIO_PHONE_NUMBER: Optional[str] = None

    # Auto-apprentissage
    ENABLE_AUTO_LEARNING: bool = True
    MIN_IMAGES_FOR_TRAINING: int = 50
    TRAINING_EPOCHS: int = 100
    BATCH_SIZE: int = 16
    AUTO_TRAIN_SCHEDULE: str = "0 2 * * *"

    # Stockage local
    LOCAL_STORAGE_PATH: str = "./storage"
    OFFLINE_MODE: bool = True
    SYNC_INTERVAL_MINUTES: int = 5

    # Logs
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "./logs/app.log"

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
