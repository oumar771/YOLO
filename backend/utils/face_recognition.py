"""Face recognition utilities using InsightFace and face_recognition."""

import cv2
import numpy as np
import face_recognition
from typing import List, Dict, Optional, Tuple
import json
from pathlib import Path
import logging
from config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# InsightFace pour une reconnaissance plus précise
try:
    from insightface.app import FaceAnalysis
    INSIGHTFACE_AVAILABLE = True
except ImportError:
    INSIGHTFACE_AVAILABLE = False
    logger.warning("InsightFace not available, using face_recognition only")


class FaceRecognitionEngine:
    """Engine for face recognition and encoding."""

    def __init__(self):
        """Initialize face recognition engine."""
        self.use_insightface = settings.USE_INSIGHTFACE and INSIGHTFACE_AVAILABLE
        self.tolerance = settings.FACE_RECOGNITION_TOLERANCE
        self.model = settings.FACE_RECOGNITION_MODEL

        # Initialiser InsightFace si disponible
        if self.use_insightface:
            try:
                self.insightface_app = FaceAnalysis(
                    name=settings.INSIGHTFACE_MODEL,
                    providers=['CPUExecutionProvider']
                )
                self.insightface_app.prepare(ctx_id=0, det_size=(640, 640))
                logger.info("InsightFace initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize InsightFace: {e}")
                self.use_insightface = False

        # Cache des encodages connus
        self.known_face_encodings = {}
        self.known_face_metadata = {}

    def extract_face_encoding(
        self,
        image: np.ndarray,
        face_location: Optional[Tuple[int, int, int, int]] = None
    ) -> Optional[np.ndarray]:
        """
        Extract face encoding from an image.

        Args:
            image: Input image (BGR format from OpenCV)
            face_location: Optional pre-detected face location (top, right, bottom, left)

        Returns:
            Face encoding as numpy array or None if no face found
        """
        # Convertir BGR -> RGB pour face_recognition
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        if self.use_insightface:
            return self._extract_with_insightface(rgb_image, face_location)
        else:
            return self._extract_with_face_recognition(rgb_image, face_location)

    def _extract_with_insightface(
        self,
        rgb_image: np.ndarray,
        face_location: Optional[Tuple] = None
    ) -> Optional[np.ndarray]:
        """Extract encoding using InsightFace."""
        try:
            faces = self.insightface_app.get(rgb_image)

            if not faces:
                return None

            # Si une localisation est fournie, trouver le visage le plus proche
            if face_location:
                top, right, bottom, left = face_location
                center_x = (left + right) / 2
                center_y = (top + bottom) / 2

                best_face = min(
                    faces,
                    key=lambda f: np.sqrt(
                        (f.bbox[0] + f.bbox[2])/2 - center_x)**2 +
                        ((f.bbox[1] + f.bbox[3])/2 - center_y)**2
                    )
                )
            else:
                # Prendre le visage le plus grand
                best_face = max(faces, key=lambda f: (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1]))

            return best_face.embedding

        except Exception as e:
            logger.error(f"InsightFace encoding error: {e}")
            return None

    def _extract_with_face_recognition(
        self,
        rgb_image: np.ndarray,
        face_location: Optional[Tuple] = None
    ) -> Optional[np.ndarray]:
        """Extract encoding using face_recognition library."""
        try:
            if face_location:
                # Utiliser la localisation fournie
                encodings = face_recognition.face_encodings(
                    rgb_image,
                    known_face_locations=[face_location],
                    model=self.model
                )
            else:
                # Détecter automatiquement
                encodings = face_recognition.face_encodings(
                    rgb_image,
                    model=self.model
                )

            if encodings:
                return encodings[0]
            return None

        except Exception as e:
            logger.error(f"face_recognition encoding error: {e}")
            return None

    def compare_faces(
        self,
        unknown_encoding: np.ndarray,
        known_encodings: List[np.ndarray],
        tolerance: Optional[float] = None
    ) -> List[bool]:
        """
        Compare unknown face encoding with known encodings.

        Args:
            unknown_encoding: Encoding to compare
            known_encodings: List of known encodings
            tolerance: Distance tolerance (lower = more strict)

        Returns:
            List of boolean matches
        """
        if tolerance is None:
            tolerance = self.tolerance

        if self.use_insightface:
            # Utiliser la distance cosine pour InsightFace
            similarities = []
            for known_encoding in known_encodings:
                similarity = np.dot(unknown_encoding, known_encoding) / (
                    np.linalg.norm(unknown_encoding) * np.linalg.norm(known_encoding)
                )
                similarities.append(similarity > (1 - tolerance))
            return similarities
        else:
            # Utiliser face_recognition.compare_faces
            return face_recognition.compare_faces(
                known_encodings,
                unknown_encoding,
                tolerance=tolerance
            )

    def face_distance(
        self,
        unknown_encoding: np.ndarray,
        known_encodings: List[np.ndarray]
    ) -> np.ndarray:
        """
        Calculate distances between unknown face and known faces.

        Args:
            unknown_encoding: Encoding to compare
            known_encodings: List of known encodings

        Returns:
            Array of distances (lower = more similar)
        """
        if self.use_insightface:
            # Distance cosine pour InsightFace (convertie en distance)
            distances = []
            for known_encoding in known_encodings:
                similarity = np.dot(unknown_encoding, known_encoding) / (
                    np.linalg.norm(unknown_encoding) * np.linalg.norm(known_encoding)
                )
                distance = 1 - similarity  # Convertir similarité en distance
                distances.append(distance)
            return np.array(distances)
        else:
            return face_recognition.face_distance(known_encodings, unknown_encoding)

    def load_known_faces(self, employees_data: List[Dict]):
        """
        Load known faces from employee data.

        Args:
            employees_data: List of employee dictionaries with encodings
        """
        self.known_face_encodings.clear()
        self.known_face_metadata.clear()

        for employee in employees_data:
            employee_id = employee['employee_id']
            encodings = employee.get('encodings', [])

            if encodings:
                # Convertir les encodings JSON en numpy arrays
                encoding_arrays = [
                    np.array(json.loads(enc)) if isinstance(enc, str) else np.array(enc)
                    for enc in encodings
                ]

                self.known_face_encodings[employee_id] = encoding_arrays
                self.known_face_metadata[employee_id] = {
                    'name': employee.get('name'),
                    'department': employee.get('department'),
                    'position': employee.get('position')
                }

        logger.info(f"Loaded {len(self.known_face_encodings)} known faces")

    def recognize_face(
        self,
        unknown_encoding: np.ndarray,
        return_confidence: bool = True
    ) -> Optional[Dict]:
        """
        Recognize a face from its encoding.

        Args:
            unknown_encoding: Face encoding to identify
            return_confidence: Whether to include confidence score

        Returns:
            Dictionary with employee info and confidence, or None if unknown
        """
        if not self.known_face_encodings:
            logger.warning("No known faces loaded")
            return None

        # Collecter tous les encodages et leurs métadonnées
        all_encodings = []
        encoding_to_employee = []

        for employee_id, encodings in self.known_face_encodings.items():
            for encoding in encodings:
                all_encodings.append(encoding)
                encoding_to_employee.append(employee_id)

        if not all_encodings:
            return None

        # Calculer les distances
        distances = self.face_distance(unknown_encoding, all_encodings)

        # Trouver la meilleure correspondance
        min_distance_idx = np.argmin(distances)
        min_distance = distances[min_distance_idx]

        # Vérifier si la distance est acceptable
        if min_distance > self.tolerance:
            return None

        # Récupérer l'employé correspondant
        employee_id = encoding_to_employee[min_distance_idx]
        metadata = self.known_face_metadata[employee_id]

        result = {
            'employee_id': employee_id,
            'name': metadata['name'],
            'department': metadata.get('department'),
            'position': metadata.get('position')
        }

        if return_confidence:
            # Convertir la distance en score de confiance (0-1)
            confidence = 1 - min_distance
            result['confidence'] = float(confidence)
            result['distance'] = float(min_distance)

        return result

    def assess_face_quality(self, image: np.ndarray) -> Dict[str, float]:
        """
        Assess the quality of a face image.

        Args:
            image: Face image (BGR format)

        Returns:
            Dictionary with quality metrics
        """
        quality = {
            'brightness': 0.0,
            'contrast': 0.0,
            'sharpness': 0.0,
            'size_score': 0.0,
            'overall_score': 0.0
        }

        try:
            # Convertir en niveaux de gris
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

            # 1. Luminosité (idéal: 100-150)
            mean_brightness = np.mean(gray)
            quality['brightness'] = 1.0 - abs(mean_brightness - 125) / 125

            # 2. Contraste
            contrast = gray.std()
            quality['contrast'] = min(contrast / 64, 1.0)  # Normaliser

            # 3. Netteté (variance du Laplacien)
            laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
            quality['sharpness'] = min(laplacian_var / 500, 1.0)

            # 4. Taille (images plus grandes = meilleure qualité)
            height, width = image.shape[:2]
            size = min(height, width)
            quality['size_score'] = min(size / 200, 1.0)

            # Score global
            quality['overall_score'] = np.mean([
                quality['brightness'],
                quality['contrast'],
                quality['sharpness'],
                quality['size_score']
            ])

        except Exception as e:
            logger.error(f"Error assessing face quality: {e}")

        return quality

    def encode_to_json(self, encoding: np.ndarray) -> str:
        """Convert numpy encoding to JSON string."""
        return json.dumps(encoding.tolist())

    def decode_from_json(self, json_str: str) -> np.ndarray:
        """Convert JSON string to numpy encoding."""
        return np.array(json.loads(json_str))


# Instance globale
_face_engine = None

def get_face_engine() -> FaceRecognitionEngine:
    """Get global face recognition engine (singleton)."""
    global _face_engine
    if _face_engine is None:
        _face_engine = FaceRecognitionEngine()
    return _face_engine
