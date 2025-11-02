"""Auto-training module for continuous learning."""

import logging
from pathlib import Path
from typing import Optional, Dict
from datetime import datetime
import json
from ultralytics import YOLO
from sqlalchemy.orm import Session
from app.database import TrainingDataset, ModelVersion
from config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class AutoTrainer:
    """Automatic training and retraining of YOLO models."""

    def __init__(self):
        """Initialize auto trainer."""
        self.models_dir = Path("trained_models")
        self.datasets_dir = Path("datasets")
        self.results_dir = Path("results")

        # Créer les dossiers
        for dir_path in [self.models_dir, self.datasets_dir, self.results_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)

    def check_training_criteria(self, dataset_path: Path) -> bool:
        """
        Check if training criteria are met.

        Args:
            dataset_path: Path to dataset

        Returns:
            True if training should be triggered
        """
        # Compter les images dans le dataset
        train_images = list((dataset_path / "train" / "images").glob("*.*"))
        val_images = list((dataset_path / "val" / "images").glob("*.*"))

        total_images = len(train_images) + len(val_images)

        if total_images < settings.MIN_IMAGES_FOR_TRAINING:
            logger.info(
                f"Not enough images for training: {total_images} < {settings.MIN_IMAGES_FOR_TRAINING}"
            )
            return False

        logger.info(f"Training criteria met: {total_images} images available")
        return True

    def prepare_dataset(
        self,
        dataset_name: str,
        class_names: list,
        source_dir: Optional[Path] = None
    ) -> Path:
        """
        Prepare dataset for training.

        Args:
            dataset_name: Name of the dataset
            class_names: List of class names
            source_dir: Optional source directory with new data

        Returns:
            Path to prepared dataset
        """
        dataset_path = self.datasets_dir / dataset_name

        # Créer la structure
        for split in ["train", "val", "test"]:
            (dataset_path / split / "images").mkdir(parents=True, exist_ok=True)
            (dataset_path / split / "labels").mkdir(parents=True, exist_ok=True)

        # Créer le fichier de configuration YAML
        config = {
            "path": str(dataset_path),
            "train": "train/images",
            "val": "val/images",
            "test": "test/images",
            "nc": len(class_names),
            "names": class_names
        }

        config_path = dataset_path / "dataset.yaml"
        import yaml
        with open(config_path, 'w') as f:
            yaml.dump(config, f)

        logger.info(f"Dataset prepared at: {dataset_path}")
        return dataset_path

    def train_model(
        self,
        dataset_path: Path,
        model_type: str = "face_detection",
        base_model: str = "yolov8n.pt",
        epochs: Optional[int] = None,
        batch_size: Optional[int] = None,
        resume: bool = False,
        db_session: Optional[Session] = None
    ) -> Dict:
        """
        Train a YOLO model.

        Args:
            dataset_path: Path to dataset
            model_type: Type of model (face_detection, weapon_detection, etc.)
            base_model: Base YOLO model to use
            epochs: Number of training epochs
            batch_size: Batch size for training
            resume: Whether to resume from existing model
            db_session: Database session for saving metadata

        Returns:
            Dictionary with training results
        """
        if epochs is None:
            epochs = settings.TRAINING_EPOCHS

        if batch_size is None:
            batch_size = settings.BATCH_SIZE

        logger.info(f"Starting training: {model_type}")
        logger.info(f"Dataset: {dataset_path}")
        logger.info(f"Epochs: {epochs}, Batch: {batch_size}")

        try:
            # Charger le modèle
            if resume and (self.models_dir / base_model).exists():
                model = YOLO(str(self.models_dir / base_model))
                logger.info(f"Resuming from: {base_model}")
            else:
                model = YOLO(base_model)
                logger.info(f"Starting from: {base_model}")

            # Paramètres d'entraînement
            training_name = f"{model_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

            training_params = {
                "data": str(dataset_path / "dataset.yaml"),
                "epochs": epochs,
                "batch": batch_size,
                "imgsz": 640,
                "name": training_name,
                "patience": 50,
                "save": True,
                "device": 0,  # GPU
                "workers": 8,
                "optimizer": "Adam",
                "lr0": 0.001,
                "verbose": True
            }

            # Lancer l'entraînement
            start_time = datetime.now()
            results = model.train(**training_params)
            end_time = datetime.now()

            training_duration = int((end_time - start_time).total_seconds())

            # Évaluer le modèle
            metrics = model.val()

            # Sauvegarder le modèle
            model_filename = f"{model_type}_{datetime.now().strftime('%Y%m%d')}.pt"
            model_path = self.models_dir / model_filename

            # Copier le meilleur modèle
            import shutil
            best_model_path = Path(f"runs/detect/{training_name}/weights/best.pt")
            if best_model_path.exists():
                shutil.copy(best_model_path, model_path)
                logger.info(f"Model saved to: {model_path}")

            # Créer le rapport
            training_report = {
                "timestamp": datetime.now().isoformat(),
                "model_name": model_filename,
                "model_type": model_type,
                "training_name": training_name,
                "base_model": base_model,
                "epochs": epochs,
                "batch_size": batch_size,
                "training_duration": training_duration,
                "metrics": {
                    "map50": float(metrics.box.map50),
                    "map50_95": float(metrics.box.map),
                    "precision": float(metrics.box.mp),
                    "recall": float(metrics.box.mr)
                },
                "model_path": str(model_path)
            }

            # Sauvegarder dans la base de données
            if db_session:
                model_version = ModelVersion(
                    model_name=model_filename,
                    model_type=model_type,
                    version=datetime.now().strftime('%Y%m%d_%H%M%S'),
                    model_path=str(model_path),
                    accuracy=training_report["metrics"]["map50_95"],
                    precision=training_report["metrics"]["precision"],
                    recall=training_report["metrics"]["recall"],
                    f1_score=2 * (training_report["metrics"]["precision"] * training_report["metrics"]["recall"]) /
                             (training_report["metrics"]["precision"] + training_report["metrics"]["recall"]),
                    training_duration=training_duration,
                    is_active=False,  # À activer manuellement après validation
                    notes=f"Auto-trained model. Dataset: {dataset_path.name}"
                )
                db_session.add(model_version)
                db_session.commit()

            # Sauvegarder le rapport JSON
            report_path = self.results_dir / f"training_report_{training_name}.json"
            with open(report_path, 'w') as f:
                json.dump(training_report, f, indent=2)

            logger.info("Training completed successfully!")
            logger.info(f"Report saved to: {report_path}")

            return training_report

        except Exception as e:
            logger.error(f"Training failed: {e}")
            raise

    def incremental_training(
        self,
        existing_model_path: Path,
        new_dataset_path: Path,
        epochs: int = 50,
        db_session: Optional[Session] = None
    ) -> Dict:
        """
        Perform incremental training on existing model.

        Args:
            existing_model_path: Path to existing model
            new_dataset_path: Path to new dataset
            epochs: Number of epochs for incremental training
            db_session: Database session

        Returns:
            Training results
        """
        logger.info("Starting incremental training...")
        logger.info(f"Base model: {existing_model_path}")
        logger.info(f"New dataset: {new_dataset_path}")

        return self.train_model(
            dataset_path=new_dataset_path,
            model_type="incremental",
            base_model=str(existing_model_path),
            epochs=epochs,
            batch_size=settings.BATCH_SIZE,
            resume=True,
            db_session=db_session
        )

    def evaluate_model(self, model_path: Path, dataset_path: Path) -> Dict:
        """
        Evaluate a trained model.

        Args:
            model_path: Path to model
            dataset_path: Path to test dataset

        Returns:
            Evaluation metrics
        """
        logger.info(f"Evaluating model: {model_path}")

        model = YOLO(str(model_path))
        metrics = model.val(data=str(dataset_path / "dataset.yaml"))

        evaluation_results = {
            "model_path": str(model_path),
            "timestamp": datetime.now().isoformat(),
            "metrics": {
                "map50": float(metrics.box.map50),
                "map50_95": float(metrics.box.map),
                "precision": float(metrics.box.mp),
                "recall": float(metrics.box.mr)
            }
        }

        logger.info(f"Evaluation complete: mAP50-95 = {metrics.box.map:.4f}")

        return evaluation_results

    def export_model(
        self,
        model_path: Path,
        export_format: str = "onnx"
    ) -> Path:
        """
        Export model to different format.

        Args:
            model_path: Path to PyTorch model
            export_format: Export format (onnx, tflite, coreml, etc.)

        Returns:
            Path to exported model
        """
        logger.info(f"Exporting model to {export_format}: {model_path}")

        model = YOLO(str(model_path))
        exported_path = model.export(format=export_format, dynamic=True)

        logger.info(f"Model exported to: {exported_path}")
        return Path(exported_path)


# Instance globale
_auto_trainer = None

def get_auto_trainer() -> AutoTrainer:
    """Get global auto trainer instance."""
    global _auto_trainer
    if _auto_trainer is None:
        _auto_trainer = AutoTrainer()
    return _auto_trainer
