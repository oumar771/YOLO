# 🎯 Système de Reconnaissance Faciale YOLO pour Entreprise

## 📋 Vue d'ensemble

Système complet de reconnaissance faciale basé sur YOLOv8 avec les fonctionnalités suivantes :

### ✨ Fonctionnalités principales

- ✅ **Reconnaissance faciale** avec YOLOv8 et InsightFace
- ✅ **Enregistrement automatique** des heures d'arrivée
- ✅ **Mode hors connexion** avec synchronisation cloud automatique
- ✅ **Détection de personnes inconnues** avec notification RH
- ✅ **Détection d'animaux** dans les locaux
- ✅ **Détection d'armes** avec alertes critiques
- ✅ **Traitement vidéo** pour analyse de séquences
- ✅ **Auto-apprentissage** du modèle sur nouvelles données
- ✅ **Synchronisation Azure Cloud** pour stockage et entraînement
- ✅ **Notifications email/SMS** pour les RH
- ✅ **API REST** complète avec FastAPI
- ✅ **Application mobile Flutter** intégrée

---

## 🏗️ Architecture du projet

```
YOLO/
├── backend/                    # Backend Python FastAPI
│   ├── app/
│   │   ├── main.py            # API principale
│   │   └── database.py        # Modèles de base de données
│   ├── config/
│   │   └── settings.py        # Configuration
│   ├── models/                # Modèles ML (à créer)
│   ├── utils/
│   │   ├── yolo_detector.py   # Détection YOLO
│   │   ├── face_recognition.py # Reconnaissance faciale
│   │   ├── cloud_storage.py   # Gestion Azure
│   │   ├── notifications.py   # Notifications RH
│   │   └── auto_training.py   # Auto-apprentissage
│   ├── scripts/
│   │   ├── setup.sh           # Script d'installation
│   │   └── add_employee.py    # Ajouter des employés
│   ├── requirements.txt       # Dépendances Python
│   ├── .env.example           # Configuration exemple
│   └── run.py                 # Point d'entrée
│
├── notebooks/                  # Jupyter Notebooks
│   └── train_yolo_face_recognition.ipynb
│
├── datasets/                   # Datasets d'entraînement
│   ├── employees/             # Images des employés
│   ├── unknown/               # Personnes inconnues
│   ├── weapons/               # Dataset armes
│   ├── animals/               # Dataset animaux
│   ├── train/                 # Données d'entraînement
│   ├── val/                   # Données de validation
│   └── test/                  # Données de test
│
├── trained_models/            # Modèles entraînés
├── logs/                      # Fichiers de logs
├── storage/                   # Stockage local
│   ├── images/
│   ├── videos/
│   └── sync_queue/           # Queue de synchronisation
│
└── [Application Flutter]      # App mobile existante
    ├── main.dart
    ├── attendance_service.dart
    └── ...

```

---

## 🚀 Installation et Configuration

### Prérequis

- Python 3.8+
- CUDA (optionnel, pour GPU)
- Node.js et npm (pour l'app Flutter)
- Compte Azure (optionnel, pour le cloud)
- Compte SendGrid (optionnel, pour les emails)
- Compte Twilio (optionnel, pour les SMS)

### Installation Backend

```bash
cd backend

# Rendre le script d'installation exécutable
chmod +x scripts/setup.sh

# Lancer l'installation
./scripts/setup.sh

# OU installation manuelle :
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

pip install -r requirements.txt
```

### Configuration

1. **Copier le fichier de configuration :**

```bash
cp .env.example .env
```

2. **Éditer le fichier `.env` :**

```env
# Base de données
DATABASE_URL=sqlite:///./attendance.db

# JWT
SECRET_KEY=votre-clé-secrète-très-longue

# Azure (optionnel)
AZURE_STORAGE_CONNECTION_STRING=your-connection-string
AZURE_COSMOS_ENDPOINT=your-cosmos-endpoint
AZURE_COSMOS_KEY=your-cosmos-key

# Notifications (optionnel)
SENDGRID_API_KEY=your-sendgrid-key
HR_EMAIL=rh@votreentreprise.com
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token

# Auto-apprentissage
ENABLE_AUTO_LEARNING=True
MIN_IMAGES_FOR_TRAINING=50
```

3. **Initialiser la base de données :**

```bash
python -c "from app.database import init_db; init_db()"
```

---

## 👥 Gestion des employés

### Ajouter un employé

```bash
python scripts/add_employee.py \
  --id "EMP001" \
  --name "Jean Dupont" \
  --email "jean.dupont@entreprise.com" \
  --department "IT" \
  --position "Développeur" \
  --images path/to/photo1.jpg path/to/photo2.jpg path/to/photo3.jpg
```

**Recommandations pour les photos :**
- Minimum 3 photos par personne
- Photos de face, léger angle gauche, léger angle droit
- Bonne luminosité
- Fond neutre si possible
- Résolution minimum 640x640

### Via l'API

```bash
# Créer un employé
curl -X POST "http://localhost:8000/api/employees" \
  -F "employee_id=EMP001" \
  -F "name=Jean Dupont" \
  -F "email=jean.dupont@entreprise.com" \
  -F "department=IT"

# Ajouter une photo de visage
curl -X POST "http://localhost:8000/api/employees/EMP001/add-face" \
  -F "file=@photo.jpg"
```

---

## 🎮 Utilisation

### Démarrer le serveur

```bash
cd backend

# Activer l'environnement virtuel
source venv/bin/activate

# Lancer le serveur
python run.py

# OU avec uvicorn directement
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Le serveur sera accessible sur : `http://localhost:8000`

Documentation API : `http://localhost:8000/docs`

### Endpoints API principaux

#### 1. Reconnaissance faciale

```bash
curl -X POST "http://localhost:8000/api/recognize" \
  -F "file=@image.jpg"
```

**Réponse (employé reconnu) :**
```json
{
  "success": true,
  "recognized": true,
  "employee": {
    "id": "EMP001",
    "name": "Jean Dupont",
    "department": "IT",
    "position": "Développeur"
  },
  "confidence": 0.95,
  "attendance_id": 123,
  "check_in": "2024-01-15T08:30:00",
  "timestamp": "2024-01-15T08:30:05"
}
```

**Réponse (personne inconnue) :**
```json
{
  "success": true,
  "recognized": false,
  "message": "Personne inconnue détectée. RH notifiés.",
  "unknown_id": 456,
  "timestamp": "2024-01-15T08:30:05"
}
```

#### 2. Détection multi-classes

```bash
curl -X POST "http://localhost:8000/api/detect" \
  -F "file=@image.jpg" \
  -F "detection_type=all"
```

Types de détection disponibles :
- `face` : Visages uniquement
- `weapon` : Armes
- `animal` : Animaux
- `all` : Tout

#### 3. Traitement vidéo

```bash
curl -X POST "http://localhost:8000/api/process-video" \
  -F "file=@video.mp4"
```

#### 4. Récupérer les présences

```bash
# Toutes les présences
curl "http://localhost:8000/api/attendances"

# Pour un employé spécifique
curl "http://localhost:8000/api/attendances?employee_id=EMP001"

# Pour une période
curl "http://localhost:8000/api/attendances?start_date=2024-01-01&end_date=2024-01-31"
```

#### 5. Visages inconnus

```bash
curl "http://localhost:8000/api/unknown-faces"
```

#### 6. Événements de détection

```bash
# Tous les événements
curl "http://localhost:8000/api/detection-events"

# Armes uniquement
curl "http://localhost:8000/api/detection-events?detection_type=weapon"
```

---

## 🎓 Entraînement du modèle

### Google Colab (Recommandé)

1. **Ouvrir le notebook dans Colab :**
   - Aller sur [Google Colab](https://colab.research.google.com/)
   - Importer `notebooks/train_yolo_face_recognition.ipynb`

2. **Activer le GPU :**
   - Runtime > Change runtime type > GPU (T4 ou A100)

3. **Suivre les étapes du notebook**

### Jupyter local

```bash
cd notebooks

# Installer Jupyter
pip install jupyter

# Lancer Jupyter
jupyter notebook train_yolo_face_recognition.ipynb
```

### Azure Machine Learning

1. **Créer un workspace Azure ML**
2. **Upload le notebook**
3. **Créer un compute instance avec GPU**
4. **Lancer l'entraînement**

### Script Python direct

```python
from utils.auto_training import get_auto_trainer

trainer = get_auto_trainer()

# Préparer le dataset
dataset_path = trainer.prepare_dataset(
    dataset_name="face_detection_v1",
    class_names=["face"]
)

# Lancer l'entraînement
results = trainer.train_model(
    dataset_path=dataset_path,
    model_type="face_detection",
    epochs=100,
    batch_size=16
)

print(f"mAP50: {results['metrics']['map50']:.4f}")
```

---

## ☁️ Configuration Azure

### 1. Azure Blob Storage

```bash
# Créer un compte de stockage
az storage account create \
  --name yourStorageAccount \
  --resource-group yourResourceGroup \
  --location westeurope

# Créer un conteneur
az storage container create \
  --name face-recognition \
  --account-name yourStorageAccount

# Obtenir la connection string
az storage account show-connection-string \
  --name yourStorageAccount \
  --resource-group yourResourceGroup
```

Ajouter dans `.env` :
```env
AZURE_STORAGE_CONNECTION_STRING=your-connection-string
AZURE_STORAGE_CONTAINER_NAME=face-recognition
```

### 2. Azure Cosmos DB

```bash
# Créer un compte Cosmos DB
az cosmosdb create \
  --name yourCosmosAccount \
  --resource-group yourResourceGroup

# Créer une base de données
az cosmosdb sql database create \
  --account-name yourCosmosAccount \
  --resource-group yourResourceGroup \
  --name attendance_db

# Obtenir les clés
az cosmosdb keys list \
  --name yourCosmosAccount \
  --resource-group yourResourceGroup
```

Ajouter dans `.env` :
```env
AZURE_COSMOS_ENDPOINT=https://yourCosmosAccount.documents.azure.com:443/
AZURE_COSMOS_KEY=your-cosmos-key
AZURE_COSMOS_DATABASE_NAME=attendance_db
```

### 3. Niveau gratuit Azure

Azure offre plusieurs services gratuits :
- **Blob Storage** : 5 GB gratuits
- **Cosmos DB** : 1000 RU/s gratuits
- **Azure ML** : Compute gratuit limité

Plus d'infos : https://azure.microsoft.com/fr-fr/free/

---

## 📱 Intégration avec l'application Flutter

L'application Flutter existante se connecte déjà à l'API via les fichiers :
- `attendance_service.dart`
- `unknown_service.dart`
- `env.dart`

### Mettre à jour l'URL de l'API

Éditer `env.dart` :

```dart
static const String BASE_URL = 'http://votre-serveur:8000';

// Nouveaux endpoints
static const String DETECT_ENDPOINT = '/api/detect';
static const String RECOGNIZE_ENDPOINT = '/api/recognize';
static const String PROCESS_VIDEO_ENDPOINT = '/api/process-video';
```

---

## 🔒 Sécurité

### Bonnes pratiques

1. **Changez les clés secrètes en production**
2. **Utilisez HTTPS en production**
3. **Limitez l'accès à l'API** (authentification JWT)
4. **Chiffrez les données sensibles**
5. **Sauvegardez régulièrement la base de données**
6. **Respectez le RGPD** pour les données biométriques

### RGPD et données biométriques

⚠️ **Important** : Les données biométriques sont des données sensibles.

Vous devez :
- Obtenir le consentement explicite des employés
- Informer sur l'utilisation des données
- Permettre l'accès et la suppression des données
- Sécuriser le stockage
- Limiter la conservation des données

---

## 📊 Monitoring et logs

### Logs

Les logs sont sauvegardés dans `logs/app.log`

```bash
# Voir les logs en temps réel
tail -f logs/app.log

# Filtrer les erreurs
grep "ERROR" logs/app.log
```

### Métriques

Le système utilise Prometheus pour les métriques (à configurer).

---

## 🧪 Tests

### Tests d'intégration

```bash
cd backend
pytest tests/
```

### Test manuel avec cURL

Voir la section "Endpoints API principaux" ci-dessus.

### Test avec Postman

Importer la collection Postman (à créer) disponible dans `docs/postman/`

---

## 🐛 Dépannage

### Problème : Aucun visage détecté

**Solutions :**
- Vérifier la qualité de l'image
- Augmenter la résolution
- Améliorer l'éclairage
- Réduire `CONFIDENCE_THRESHOLD` dans `.env`

### Problème : Reconnaissance incorrecte

**Solutions :**
- Ajouter plus de photos de l'employé
- Réentraîner le modèle
- Ajuster `FACE_RECOGNITION_TOLERANCE`

### Problème : Performances lentes

**Solutions :**
- Utiliser un GPU
- Réduire la taille des images
- Utiliser un modèle plus petit (yolov8n vs yolov8m)
- Activer TensorRT (NVIDIA)

### Problème : Erreur de connexion Azure

**Solutions :**
- Vérifier les credentials dans `.env`
- Tester la connexion réseau
- Vérifier les permissions Azure

---

## 📈 Roadmap

- [ ] Support multi-caméras
- [ ] Dashboard web React
- [ ] Détection de masque COVID
- [ ] Analyse comportementale
- [ ] Intégration avec systèmes RH existants
- [ ] Support Docker/Kubernetes
- [ ] Mode edge computing (Jetson Nano)

---

## 🤝 Contribution

Pour contribuer au projet :

1. Fork le repository
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📄 Licence

Ce projet est sous licence MIT. Voir `LICENSE` pour plus de détails.

---

## 🙏 Remerciements

- [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics)
- [InsightFace](https://github.com/deepinsight/insightface)
- [FastAPI](https://fastapi.tiangolo.com/)
- [Flutter](https://flutter.dev/)

---

## 📞 Support

Pour toute question ou problème :
- Créer une issue sur GitHub
- Email : support@votreentreprise.com

---

**Développé avec ❤️ pour améliorer la sécurité et l'efficacité en entreprise**
