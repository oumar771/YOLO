"""Database configuration and models."""

from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
from config.settings import get_settings

settings = get_settings()

# Créer le moteur de base de données
engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Employee(Base):
    """Modèle pour les employés."""
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    department = Column(String)
    position = Column(String)
    phone = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relations
    face_encodings = relationship("FaceEncoding", back_populates="employee", cascade="all, delete-orphan")
    attendances = relationship("Attendance", back_populates="employee", cascade="all, delete-orphan")


class FaceEncoding(Base):
    """Modèle pour les encodages de visages."""
    __tablename__ = "face_encodings"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.id"), nullable=False)
    encoding = Column(Text, nullable=False)  # Stocké en JSON
    image_path = Column(String)
    quality_score = Column(Float)  # Score de qualité de l'image
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relations
    employee = relationship("Employee", back_populates="face_encodings")


class Attendance(Base):
    """Modèle pour les présences."""
    __tablename__ = "attendances"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.id"), nullable=False)
    check_in = Column(DateTime, nullable=False)
    check_out = Column(DateTime, nullable=True)
    location = Column(String)
    confidence = Column(Float)  # Niveau de confiance de la reconnaissance
    image_path = Column(String)
    synced = Column(Boolean, default=False)  # Si synchronisé avec le cloud
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relations
    employee = relationship("Employee", back_populates="attendances")


class UnknownFace(Base):
    """Modèle pour les visages inconnus."""
    __tablename__ = "unknown_faces"

    id = Column(Integer, primary_key=True, index=True)
    image_path = Column(String, nullable=False)
    encoding = Column(Text)
    detected_at = Column(DateTime, default=datetime.utcnow)
    location = Column(String)
    is_notified = Column(Boolean, default=False)  # Si RH a été notifié
    notes = Column(Text)  # Notes des RH
    detection_type = Column(String)  # 'person', 'animal', 'weapon', etc.
    confidence = Column(Float)
    synced = Column(Boolean, default=False)


class DetectionEvent(Base):
    """Modèle pour les événements de détection (armes, animaux, etc.)."""
    __tablename__ = "detection_events"

    id = Column(Integer, primary_key=True, index=True)
    detection_type = Column(String, nullable=False)  # 'weapon', 'animal', 'unknown_person'
    class_name = Column(String)  # Type spécifique (ex: 'gun', 'dog', etc.)
    confidence = Column(Float)
    image_path = Column(String)
    video_path = Column(String, nullable=True)
    location = Column(String)
    is_notified = Column(Boolean, default=False)
    severity = Column(String)  # 'low', 'medium', 'high', 'critical'
    notes = Column(Text)
    detected_at = Column(DateTime, default=datetime.utcnow)
    synced = Column(Boolean, default=False)


class TrainingDataset(Base):
    """Modèle pour le suivi des datasets d'entraînement."""
    __tablename__ = "training_datasets"

    id = Column(Integer, primary_key=True, index=True)
    dataset_name = Column(String, nullable=False)
    dataset_path = Column(String, nullable=False)
    num_images = Column(Integer)
    num_classes = Column(Integer)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_trained = Column(DateTime, nullable=True)


class ModelVersion(Base):
    """Modèle pour les versions de modèles entraînés."""
    __tablename__ = "model_versions"

    id = Column(Integer, primary_key=True, index=True)
    model_name = Column(String, nullable=False)
    model_type = Column(String)  # 'face_recognition', 'weapon_detection', etc.
    version = Column(String, nullable=False)
    model_path = Column(String, nullable=False)
    accuracy = Column(Float)
    precision = Column(Float)
    recall = Column(Float)
    f1_score = Column(Float)
    training_duration = Column(Integer)  # En secondes
    is_active = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    notes = Column(Text)


# Créer toutes les tables
def init_db():
    """Initialiser la base de données."""
    Base.metadata.create_all(bind=engine)


def get_db():
    """Obtenir une session de base de données."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
