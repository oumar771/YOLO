"""Azure Cloud Storage utilities for offline/online synchronization."""

import asyncio
from typing import Optional, Dict, List
from pathlib import Path
import logging
from datetime import datetime
import json
from config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Azure imports
try:
    from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
    from azure.cosmos import CosmosClient
    from azure.core.exceptions import ResourceNotFoundError, ResourceExistsError
    AZURE_AVAILABLE = True
except ImportError:
    AZURE_AVAILABLE = False
    logger.warning("Azure SDK not available, cloud sync will be disabled")


class AzureStorageManager:
    """Manager for Azure Blob Storage and Cosmos DB."""

    def __init__(self):
        """Initialize Azure storage manager."""
        self.enabled = AZURE_AVAILABLE and settings.AZURE_STORAGE_CONNECTION_STRING is not None

        if self.enabled:
            try:
                # Blob Storage pour les images/vidéos
                self.blob_service_client = BlobServiceClient.from_connection_string(
                    settings.AZURE_STORAGE_CONNECTION_STRING
                )
                self.container_name = settings.AZURE_STORAGE_CONTAINER_NAME
                self._ensure_container_exists()

                # Cosmos DB pour les données structurées
                if settings.AZURE_COSMOS_ENDPOINT and settings.AZURE_COSMOS_KEY:
                    self.cosmos_client = CosmosClient(
                        settings.AZURE_COSMOS_ENDPOINT,
                        settings.AZURE_COSMOS_KEY
                    )
                    self.database = self.cosmos_client.get_database_client(
                        settings.AZURE_COSMOS_DATABASE_NAME
                    )
                    logger.info("Azure Cosmos DB initialized")
                else:
                    self.cosmos_client = None
                    logger.warning("Cosmos DB credentials not provided")

                logger.info("Azure Storage Manager initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize Azure: {e}")
                self.enabled = False
        else:
            logger.info("Azure storage disabled")

    def _ensure_container_exists(self):
        """Ensure the blob container exists."""
        try:
            container_client = self.blob_service_client.get_container_client(
                self.container_name
            )
            container_client.get_container_properties()
        except ResourceNotFoundError:
            self.blob_service_client.create_container(self.container_name)
            logger.info(f"Created container: {self.container_name}")

    async def upload_image(
        self,
        local_path: str,
        blob_name: Optional[str] = None,
        metadata: Optional[Dict] = None
    ) -> Optional[str]:
        """
        Upload an image to Azure Blob Storage.

        Args:
            local_path: Local file path
            blob_name: Optional blob name (defaults to filename with timestamp)
            metadata: Optional metadata to attach

        Returns:
            Blob URL if successful, None otherwise
        """
        if not self.enabled:
            logger.debug("Azure storage disabled, skipping upload")
            return None

        try:
            local_path = Path(local_path)
            if not local_path.exists():
                logger.error(f"Local file not found: {local_path}")
                return None

            # Générer un nom de blob unique si non fourni
            if blob_name is None:
                timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                blob_name = f"{timestamp}_{local_path.name}"

            # Créer le blob client
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )

            # Upload avec métadonnées
            with open(local_path, "rb") as data:
                blob_client.upload_blob(
                    data,
                    overwrite=True,
                    metadata=metadata
                )

            blob_url = blob_client.url
            logger.info(f"Uploaded {local_path.name} to {blob_url}")
            return blob_url

        except Exception as e:
            logger.error(f"Failed to upload image: {e}")
            return None

    async def download_image(
        self,
        blob_name: str,
        local_path: str
    ) -> bool:
        """
        Download an image from Azure Blob Storage.

        Args:
            blob_name: Blob name to download
            local_path: Local destination path

        Returns:
            True if successful, False otherwise
        """
        if not self.enabled:
            return False

        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )

            # Télécharger
            with open(local_path, "wb") as file:
                download_stream = blob_client.download_blob()
                file.write(download_stream.readall())

            logger.info(f"Downloaded {blob_name} to {local_path}")
            return True

        except Exception as e:
            logger.error(f"Failed to download image: {e}")
            return False

    async def sync_attendance_record(self, record: Dict) -> bool:
        """
        Synchronize an attendance record to Cosmos DB.

        Args:
            record: Attendance record dictionary

        Returns:
            True if successful, False otherwise
        """
        if not self.enabled or not self.cosmos_client:
            return False

        try:
            container = self.database.get_container_client("attendances")

            # Ajouter des métadonnées
            record['synced_at'] = datetime.utcnow().isoformat()
            record['id'] = f"att_{record.get('id', datetime.utcnow().timestamp())}"

            # Upsert (create or update)
            container.upsert_item(record)
            logger.info(f"Synced attendance record: {record['id']}")
            return True

        except Exception as e:
            logger.error(f"Failed to sync attendance: {e}")
            return False

    async def sync_detection_event(self, event: Dict) -> bool:
        """
        Synchronize a detection event to Cosmos DB.

        Args:
            event: Detection event dictionary

        Returns:
            True if successful, False otherwise
        """
        if not self.enabled or not self.cosmos_client:
            return False

        try:
            container = self.database.get_container_client("detection_events")

            event['synced_at'] = datetime.utcnow().isoformat()
            event['id'] = f"det_{event.get('id', datetime.utcnow().timestamp())}"

            container.upsert_item(event)
            logger.info(f"Synced detection event: {event['id']}")
            return True

        except Exception as e:
            logger.error(f"Failed to sync detection event: {e}")
            return False

    async def sync_unknown_face(self, face_data: Dict, image_path: str) -> bool:
        """
        Synchronize an unknown face detection.

        Args:
            face_data: Unknown face metadata
            image_path: Local image path

        Returns:
            True if successful, False otherwise
        """
        if not self.enabled:
            return False

        try:
            # Upload l'image
            blob_name = f"unknown_faces/{datetime.utcnow().strftime('%Y%m%d')}/{Path(image_path).name}"
            blob_url = await self.upload_image(image_path, blob_name)

            if blob_url and self.cosmos_client:
                # Sync les métadonnées
                container = self.database.get_container_client("unknown_faces")

                face_data['image_url'] = blob_url
                face_data['synced_at'] = datetime.utcnow().isoformat()
                face_data['id'] = f"unk_{face_data.get('id', datetime.utcnow().timestamp())}"

                container.upsert_item(face_data)
                logger.info(f"Synced unknown face: {face_data['id']}")
                return True

        except Exception as e:
            logger.error(f"Failed to sync unknown face: {e}")

        return False

    async def get_pending_syncs(self) -> Dict[str, List]:
        """
        Retrieve records that haven't been synced yet.

        Returns:
            Dictionary of pending sync records by type
        """
        # Cette fonction devrait interroger la base locale
        # pour trouver les enregistrements non synchronisés
        # À implémenter selon la logique de votre base de données locale
        pass


class LocalStorageManager:
    """Manager for local storage with offline support."""

    def __init__(self):
        """Initialize local storage manager."""
        self.storage_path = Path(settings.LOCAL_STORAGE_PATH)
        self.storage_path.mkdir(parents=True, exist_ok=True)

        # Créer les sous-dossiers
        self.images_path = self.storage_path / "images"
        self.videos_path = self.storage_path / "videos"
        self.temp_path = self.storage_path / "temp"
        self.queue_path = self.storage_path / "sync_queue"

        for path in [self.images_path, self.videos_path, self.temp_path, self.queue_path]:
            path.mkdir(exist_ok=True)

        logger.info(f"Local storage initialized at: {self.storage_path}")

    def save_image(
        self,
        image_data: bytes,
        filename: str,
        category: str = "general"
    ) -> str:
        """
        Save an image locally.

        Args:
            image_data: Image bytes
            filename: Filename
            category: Category subfolder (e.g., 'attendance', 'unknown', 'weapons')

        Returns:
            Local file path
        """
        category_path = self.images_path / category
        category_path.mkdir(exist_ok=True)

        file_path = category_path / filename
        with open(file_path, 'wb') as f:
            f.write(image_data)

        logger.debug(f"Saved image: {file_path}")
        return str(file_path)

    def queue_for_sync(self, data: Dict, data_type: str):
        """
        Queue data for cloud synchronization.

        Args:
            data: Data to sync
            data_type: Type of data ('attendance', 'detection', 'unknown_face')
        """
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S_%f")
        queue_file = self.queue_path / f"{data_type}_{timestamp}.json"

        with open(queue_file, 'w') as f:
            json.dump(data, f)

        logger.debug(f"Queued for sync: {queue_file}")

    def get_sync_queue(self) -> List[Dict]:
        """
        Get all items in the sync queue.

        Returns:
            List of items to sync
        """
        queue_items = []

        for queue_file in self.queue_path.glob("*.json"):
            try:
                with open(queue_file, 'r') as f:
                    data = json.load(f)
                    data['_queue_file'] = str(queue_file)
                    queue_items.append(data)
            except Exception as e:
                logger.error(f"Error reading queue file {queue_file}: {e}")

        return queue_items

    def remove_from_queue(self, queue_file: str):
        """Remove an item from the sync queue after successful sync."""
        try:
            Path(queue_file).unlink()
            logger.debug(f"Removed from queue: {queue_file}")
        except Exception as e:
            logger.error(f"Error removing queue file: {e}")


# Instances globales
_azure_manager = None
_local_manager = None

def get_azure_manager() -> AzureStorageManager:
    """Get global Azure storage manager."""
    global _azure_manager
    if _azure_manager is None:
        _azure_manager = AzureStorageManager()
    return _azure_manager

def get_local_manager() -> LocalStorageManager:
    """Get global local storage manager."""
    global _local_manager
    if _local_manager is None:
        _local_manager = LocalStorageManager()
    return _local_manager
