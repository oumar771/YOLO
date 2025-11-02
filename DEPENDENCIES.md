# 📦 Liste complète des dépendances

Ce document liste toutes les dépendances nécessaires pour le projet YOLO Face Recognition.

---

## 🐍 Dépendances Python (Backend)

### Framework et API
```
fastapi==0.104.1              # Framework API REST moderne
uvicorn[standard]==0.24.0     # Serveur ASGI
python-multipart==0.0.6       # Upload de fichiers
websockets==12.0              # Support WebSocket
pydantic==2.5.0               # Validation de données
pydantic-settings==2.1.0      # Configuration
```

### Intelligence Artificielle - YOLO et Deep Learning
```
ultralytics==8.0.232          # YOLOv8 (détection d'objets)
torch==2.1.0                  # PyTorch (framework ML)
torchvision==0.16.0           # Vision par ordinateur
opencv-python==4.8.1.78       # Traitement d'images
opencv-contrib-python==4.8.1.78  # Modules supplémentaires OpenCV
```

### Reconnaissance faciale
```
face-recognition==1.3.0       # Reconnaissance faciale simple
dlib==19.24.2                 # Machine learning pour vision
deepface==0.0.79              # Framework reconnaissance faciale
insightface==0.7.3            # Reconnaissance faciale avancée
onnxruntime==1.16.3           # Runtime ONNX pour InsightFace
```

### Base de données
```
sqlalchemy==2.0.23            # ORM SQL
pymongo==4.6.0                # MongoDB
motor==3.3.2                  # MongoDB async
alembic==1.12.1               # Migrations DB
```

### Cloud Azure
```
azure-storage-blob==12.19.0   # Stockage Azure
azure-cosmos==4.5.1           # Cosmos DB
azure-identity==1.15.0        # Authentification Azure
azure-ai-formrecognizer==3.3.2  # OCR Azure
```

### Traitement d'images
```
Pillow==10.1.0                # Manipulation d'images
numpy==1.24.3                 # Calculs numériques
scikit-learn==1.3.2           # Machine learning
matplotlib==3.8.2             # Visualisation
albumentations==1.3.1         # Augmentation d'images
```

### Sécurité et authentification
```
python-jose[cryptography]==3.3.0  # JWT tokens
passlib[bcrypt]==1.7.4        # Hachage de mots de passe
python-dotenv==1.0.0          # Variables d'environnement
```

### Notifications
```
sendgrid==6.11.0              # Emails
twilio==8.10.3                # SMS
```

### Utilitaires
```
python-dateutil==2.8.2        # Manipulation de dates
pytz==2023.3                  # Fuseaux horaires
requests==2.31.0              # Requêtes HTTP
aiofiles==23.2.1              # Fichiers async
httpx==0.25.2                 # Client HTTP async
```

### Monitoring
```
prometheus-client==0.19.0     # Métriques Prometheus
loguru==0.7.2                 # Logging avancé
```

### Testing
```
pytest==7.4.3                 # Framework de tests
pytest-asyncio==0.21.1        # Tests async
```

---

## 📱 Dépendances Flutter (Application Mobile)

### Framework
```yaml
flutter:
  sdk: flutter                # Framework Flutter

cupertino_icons: ^1.0.2       # Icons iOS
```

### État et Architecture
```yaml
provider: ^6.0.0              # Gestion d'état
```

### Stockage local
```yaml
shared_preferences: ^2.2.0    # Préférences locales
sqflite: ^2.3.0               # Base de données SQLite
path_provider: ^2.1.0         # Chemins système
```

### Réseau
```yaml
http: ^1.1.0                  # Requêtes HTTP
dio: ^5.3.0                   # Client HTTP avancé (optionnel)
```

### Caméra et images
```yaml
camera: ^0.10.5               # Accès caméra
image_picker: ^1.0.0          # Sélection d'images
```

### Permissions
```yaml
permission_handler: ^11.0.0   # Gestion des permissions
```

### UI
```yaml
intl: ^0.18.0                 # Internationalisation
```

---

## 🛠️ Outils de développement

### Python
- **Python 3.10 ou 3.11** (pas 3.12)
- **pip** (gestionnaire de packages)
- **virtualenv** ou **venv** (environnement virtuel)

### IDE
- **Visual Studio Code** (recommandé pour Python)
  - Extension Python
  - Extension Pylance
  - Extension Docker
  - Extension REST Client

- **Visual Studio 2022** (alternative)
  - Workload "Python development"
  - Workload "Desktop development with C++"

- **Android Studio** (pour Flutter)
  - Android SDK
  - Android Emulator
  - Flutter plugin
  - Dart plugin

### Versioning
- **Git** (contrôle de version)
- **GitHub CLI** (optionnel)

### Conteneurisation
- **Docker Desktop** (optionnel)
  - Docker Engine
  - Docker Compose

---

## 🎮 Dépendances système (Windows)

### Compilateurs (pour certaines librairies Python)
- **Microsoft Visual C++ 14.0+**
  - Visual Studio Build Tools 2022
  - OU Visual Studio 2022 (n'importe quelle édition)
  - Workload "Desktop development with C++"

### CMake (pour dlib et autres)
```cmd
pip install cmake
```

### CUDA (optionnel - pour GPU NVIDIA)
- **NVIDIA CUDA Toolkit 11.8**
- **cuDNN 8.x** (pour CUDA 11.8)
- **Drivers NVIDIA** à jour

---

## 🔍 Vérification des installations

### Python
```cmd
python --version
pip --version
```

### PyTorch avec GPU (si CUDA installé)
```python
import torch
print(torch.cuda.is_available())  # Devrait afficher True
print(torch.cuda.get_device_name(0))  # Nom de votre GPU
```

### Flutter
```cmd
flutter --version
flutter doctor
```

### Android
```cmd
flutter doctor -v
adb version
```

---

## 📊 Taille des installations

| Composant | Taille approximative |
|-----------|---------------------|
| Python 3.10 | ~100 MB |
| Dépendances Python (backend) | ~5-8 GB |
| PyTorch avec CUDA | ~3-4 GB |
| Visual Studio Code | ~300 MB |
| Visual Studio 2022 (avec C++) | ~10-15 GB |
| Android Studio | ~3-4 GB |
| Android SDK + Emulator | ~5-10 GB |
| Flutter SDK | ~2 GB |
| CUDA Toolkit (optionnel) | ~3 GB |
| **TOTAL** | **~20-30 GB** (sans VS2022) |
| **TOTAL avec VS2022** | **~30-45 GB** |

---

## ⚡ Installation rapide

### Backend Python (avec venv)

```cmd
cd backend

:: Créer l'environnement virtuel
python -m venv venv

:: Activer (Windows)
venv\Scripts\activate

:: Mettre à jour pip
python -m pip install --upgrade pip

:: Installer toutes les dépendances
pip install -r requirements.txt
```

### Application Flutter

```cmd
flutter pub get
```

---

## 🔧 Installation sélective (si problèmes)

Si l'installation complète échoue, installer par groupes :

### 1. Essentiels
```cmd
pip install fastapi uvicorn sqlalchemy pydantic python-dotenv
```

### 2. YOLO et Deep Learning
```cmd
pip install ultralytics torch torchvision opencv-python numpy
```

### 3. Reconnaissance faciale
```cmd
pip install face-recognition insightface deepface
```

### 4. Azure (optionnel)
```cmd
pip install azure-storage-blob azure-cosmos azure-identity
```

### 5. Notifications (optionnel)
```cmd
pip install sendgrid twilio
```

---

## 🐛 Dépendances problématiques

### dlib (souvent problématique sur Windows)

**Solution 1 : Via conda (plus facile)**
```cmd
conda install -c conda-forge dlib
```

**Solution 2 : Via wheel pré-compilé**
```cmd
:: Télécharger depuis
:: https://github.com/z-mahmud22/Dlib_Windows_Python3.x
:: Puis installer
pip install dlib-19.24.0-cp310-cp310-win_amd64.whl
```

**Solution 3 : Compiler (nécessite Visual Studio)**
```cmd
pip install cmake
pip install dlib
```

### InsightFace

Si problème avec InsightFace :
```cmd
:: Installer ONNX Runtime d'abord
pip install onnxruntime

:: Puis InsightFace
pip install insightface
```

---

## 📝 Fichiers de configuration

### requirements.txt (Backend)
Localisation : `backend/requirements.txt`

### pubspec.yaml (Flutter)
Localisation : `pubspec.yaml` (racine du projet Flutter)

### .env (Configuration)
Localisation : `backend/.env`
Template : `backend/.env.example`

---

## 🚀 Versions recommandées

### Python
- ✅ **Python 3.10.x** (recommandé)
- ✅ **Python 3.11.x** (fonctionne)
- ❌ **Python 3.12.x** (incompatibilités)
- ❌ **Python 3.9.x ou moins** (trop ancien)

### PyTorch
- ✅ **torch 2.1.0** (stable)
- ✅ **torch 2.0.x** (fonctionne)

### Flutter
- ✅ **Flutter 3.13+** (recommandé)
- ✅ **Flutter 3.10+** (fonctionne)

---

## 🔄 Mise à jour des dépendances

### Python
```cmd
:: Mettre à jour toutes les dépendances
pip install --upgrade -r requirements.txt

:: Mettre à jour un package spécifique
pip install --upgrade ultralytics
```

### Flutter
```cmd
:: Mettre à jour Flutter
flutter upgrade

:: Mettre à jour les dépendances
flutter pub upgrade
```

---

## 📖 Documentation des dépendances principales

- **YOLOv8** : https://docs.ultralytics.com/
- **FastAPI** : https://fastapi.tiangolo.com/
- **PyTorch** : https://pytorch.org/docs/
- **InsightFace** : https://github.com/deepinsight/insightface
- **Flutter** : https://docs.flutter.dev/
- **Azure SDK** : https://docs.microsoft.com/azure/developer/python/

---

**Pour installer tout l'environnement sur Windows, suivez le guide détaillé :**
👉 [SETUP_WINDOWS_VS2022.md](docs/SETUP_WINDOWS_VS2022.md)
