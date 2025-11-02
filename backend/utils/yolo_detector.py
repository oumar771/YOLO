"""YOLO detection utilities for face, weapon, and animal detection."""

import cv2
import numpy as np
from ultralytics import YOLO
from typing import List, Dict, Tuple, Optional
from pathlib import Path
from config.settings import get_settings
import logging

logger = logging.getLogger(__name__)
settings = get_settings()


class YOLODetector:
    """Unified YOLO detector for multiple detection types."""

    def __init__(self):
        """Initialize YOLO models."""
        self.models = {}
        self.load_models()

    def load_models(self):
        """Load all YOLO models."""
        try:
            # Modèle pour la détection de visages
            face_model_path = Path("trained_models") / settings.YOLO_FACE_MODEL
            if face_model_path.exists():
                self.models['face'] = YOLO(str(face_model_path))
                logger.info(f"Face detection model loaded: {face_model_path}")
            else:
                # Utiliser YOLOv8 par défaut pour la détection de personnes
                self.models['face'] = YOLO('yolov8n.pt')
                logger.warning("Face model not found, using default YOLOv8n")

            # Modèle pour la détection d'armes
            weapon_model_path = Path("trained_models") / settings.YOLO_WEAPON_MODEL
            if weapon_model_path.exists():
                self.models['weapon'] = YOLO(str(weapon_model_path))
                logger.info(f"Weapon detection model loaded: {weapon_model_path}")
            else:
                # Utiliser YOLOv8 par défaut
                self.models['weapon'] = YOLO('yolov8n.pt')
                logger.warning("Weapon model not found, using default YOLOv8n")

            # Modèle pour la détection d'animaux
            animal_model_path = Path("trained_models") / settings.YOLO_ANIMAL_MODEL
            if animal_model_path.exists():
                self.models['animal'] = YOLO(str(animal_model_path))
                logger.info(f"Animal detection model loaded: {animal_model_path}")
            else:
                # Utiliser YOLOv8 standard (contient déjà des classes d'animaux)
                self.models['animal'] = YOLO('yolov8n.pt')
                logger.info("Using default YOLOv8n for animal detection")

        except Exception as e:
            logger.error(f"Error loading YOLO models: {e}")
            raise

    def detect_faces(
        self,
        image: np.ndarray,
        conf_threshold: Optional[float] = None
    ) -> List[Dict]:
        """
        Detect faces in an image.

        Args:
            image: Input image as numpy array
            conf_threshold: Confidence threshold (default from settings)

        Returns:
            List of detected faces with bounding boxes and confidence
        """
        if conf_threshold is None:
            conf_threshold = settings.CONFIDENCE_THRESHOLD

        results = self.models['face'].predict(
            image,
            conf=conf_threshold,
            iou=settings.IOU_THRESHOLD,
            classes=[0],  # Classe 0 = personne dans COCO
            verbose=False
        )

        detections = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                confidence = float(box.conf[0])

                # Extraire la région du visage
                face_region = image[int(y1):int(y2), int(x1):int(x2)]

                detections.append({
                    'bbox': [int(x1), int(y1), int(x2), int(y2)],
                    'confidence': confidence,
                    'face_region': face_region,
                    'type': 'face'
                })

        return detections

    def detect_weapons(
        self,
        image: np.ndarray,
        conf_threshold: Optional[float] = None
    ) -> List[Dict]:
        """
        Detect weapons in an image.

        Args:
            image: Input image as numpy array
            conf_threshold: Confidence threshold

        Returns:
            List of detected weapons with details
        """
        if conf_threshold is None:
            conf_threshold = settings.CONFIDENCE_THRESHOLD

        results = self.models['weapon'].predict(
            image,
            conf=conf_threshold,
            iou=settings.IOU_THRESHOLD,
            verbose=False
        )

        detections = []
        weapon_classes = ['knife', 'gun', 'rifle', 'scissors']  # Classes d'armes

        for result in results:
            boxes = result.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                confidence = float(box.conf[0])
                class_id = int(box.cls[0])
                class_name = result.names[class_id]

                # Filtrer pour ne garder que les armes
                if any(weapon in class_name.lower() for weapon in weapon_classes):
                    detections.append({
                        'bbox': [int(x1), int(y1), int(x2), int(y2)],
                        'confidence': confidence,
                        'class': class_name,
                        'type': 'weapon',
                        'severity': self._get_weapon_severity(class_name)
                    })

        return detections

    def detect_animals(
        self,
        image: np.ndarray,
        conf_threshold: Optional[float] = None
    ) -> List[Dict]:
        """
        Detect animals in an image.

        Args:
            image: Input image as numpy array
            conf_threshold: Confidence threshold

        Returns:
            List of detected animals with details
        """
        if conf_threshold is None:
            conf_threshold = settings.CONFIDENCE_THRESHOLD

        results = self.models['animal'].predict(
            image,
            conf=conf_threshold,
            iou=settings.IOU_THRESHOLD,
            verbose=False
        )

        detections = []
        # Classes d'animaux dans COCO dataset (IDs 14-23)
        animal_class_ids = list(range(14, 24))  # bird, cat, dog, horse, sheep, cow, etc.

        for result in results:
            boxes = result.boxes
            for box in boxes:
                class_id = int(box.cls[0])

                if class_id in animal_class_ids:
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0])
                    class_name = result.names[class_id]

                    detections.append({
                        'bbox': [int(x1), int(y1), int(x2), int(y2)],
                        'confidence': confidence,
                        'class': class_name,
                        'type': 'animal'
                    })

        return detections

    def detect_all(
        self,
        image: np.ndarray,
        conf_threshold: Optional[float] = None
    ) -> Dict[str, List[Dict]]:
        """
        Detect all types (faces, weapons, animals) in a single image.

        Args:
            image: Input image as numpy array
            conf_threshold: Confidence threshold

        Returns:
            Dictionary with all detections categorized by type
        """
        return {
            'faces': self.detect_faces(image, conf_threshold),
            'weapons': self.detect_weapons(image, conf_threshold),
            'animals': self.detect_animals(image, conf_threshold)
        }

    def _get_weapon_severity(self, weapon_class: str) -> str:
        """Determine severity level based on weapon type."""
        weapon_class = weapon_class.lower()

        if 'gun' in weapon_class or 'rifle' in weapon_class:
            return 'critical'
        elif 'knife' in weapon_class:
            return 'high'
        elif 'scissors' in weapon_class:
            return 'medium'
        else:
            return 'low'

    def process_video(
        self,
        video_path: str,
        output_path: Optional[str] = None,
        conf_threshold: Optional[float] = None
    ) -> List[Dict]:
        """
        Process a video file and detect objects frame by frame.

        Args:
            video_path: Path to input video
            output_path: Optional path to save annotated video
            conf_threshold: Confidence threshold

        Returns:
            List of all detections across all frames
        """
        cap = cv2.VideoCapture(video_path)
        all_detections = []
        frame_count = 0

        # Configuration pour la vidéo de sortie
        if output_path:
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            fps = int(cap.get(cv2.CAP_PROP_FPS))
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Détection sur la frame actuelle
            detections = self.detect_all(frame, conf_threshold)

            # Ajouter le numéro de frame et le timestamp
            timestamp = cap.get(cv2.CAP_PROP_POS_MSEC) / 1000.0
            for detection_type, items in detections.items():
                for item in items:
                    item['frame'] = frame_count
                    item['timestamp'] = timestamp
                    all_detections.append(item)

            # Annoter et sauvegarder la frame si nécessaire
            if output_path:
                annotated_frame = self._annotate_frame(frame, detections)
                out.write(annotated_frame)

            frame_count += 1

        cap.release()
        if output_path:
            out.release()

        logger.info(f"Processed {frame_count} frames, found {len(all_detections)} detections")
        return all_detections

    def _annotate_frame(self, frame: np.ndarray, detections: Dict) -> np.ndarray:
        """Annotate a frame with detection boxes and labels."""
        annotated = frame.copy()

        colors = {
            'face': (0, 255, 0),      # Vert
            'weapon': (0, 0, 255),     # Rouge
            'animal': (255, 0, 0)      # Bleu
        }

        for detection_type, items in detections.items():
            color = colors.get(detection_type, (255, 255, 255))

            for item in items:
                bbox = item['bbox']
                confidence = item['confidence']
                class_name = item.get('class', detection_type)

                # Dessiner le rectangle
                cv2.rectangle(
                    annotated,
                    (bbox[0], bbox[1]),
                    (bbox[2], bbox[3]),
                    color,
                    2
                )

                # Ajouter le label
                label = f"{class_name}: {confidence:.2f}"
                cv2.putText(
                    annotated,
                    label,
                    (bbox[0], bbox[1] - 10),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.5,
                    color,
                    2
                )

        return annotated


# Instance globale du détecteur
_detector = None

def get_detector() -> YOLODetector:
    """Get global detector instance (singleton)."""
    global _detector
    if _detector is None:
        _detector = YOLODetector()
    return _detector
