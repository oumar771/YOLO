# 🖥️ Configuration Environnement Windows - Visual Studio 2022 + Android Studio

Guide complet pour configurer votre environnement de développement sur Windows avec Visual Studio 2022 et Android Studio.

---

## 📋 Table des matières

1. [Prérequis système](#prérequis-système)
2. [Installation Python et environnement](#installation-python)
3. [Configuration Visual Studio 2022](#configuration-visual-studio-2022)
4. [Installation Android Studio et Flutter](#installation-android-studio-et-flutter)
5. [Installation des dépendances du projet](#installation-des-dépendances-du-projet)
6. [Configuration CUDA (optionnel - GPU)](#configuration-cuda)
7. [Test de l'installation](#test-de-linstallation)
8. [Résolution des problèmes](#résolution-des-problèmes)

---

## 🖥️ Prérequis système

### Configuration minimale

- **OS** : Windows 10/11 (64-bit)
- **RAM** : 8 GB minimum, 16 GB recommandé
- **Espace disque** : 30 GB minimum
- **Processeur** : Intel i5 ou équivalent
- **GPU** (optionnel) : NVIDIA avec CUDA (pour accélération)

### Configuration recommandée

- **RAM** : 16 GB ou plus
- **GPU** : NVIDIA RTX 2060 ou supérieur
- **SSD** : Pour de meilleures performances

---

## 🐍 Installation Python et environnement

### 1. Installer Python 3.10 ou 3.11

**Option A : Via le site officiel (recommandé)**

1. Télécharger Python depuis https://www.python.org/downloads/
2. **Choisir Python 3.10.x ou 3.11.x** (pas 3.12, certaines librairies ne sont pas encore compatibles)
3. Lors de l'installation :
   - ✅ **Cocher "Add Python to PATH"** (très important !)
   - Choisir "Customize installation"
   - Cocher toutes les options
   - Installer pour tous les utilisateurs

**Vérifier l'installation :**

```cmd
python --version
# Devrait afficher : Python 3.10.x ou 3.11.x

pip --version
# Devrait afficher la version de pip
```

### 2. Installer Git pour Windows

```
https://git-scm.com/download/win
```

- Accepter les options par défaut
- Choisir "Use Git from the Windows Command Prompt"

**Vérifier :**

```cmd
git --version
```

---

## 🎨 Configuration Visual Studio 2022

### 1. Installer Visual Studio 2022

**Option A : Visual Studio 2022 Community (gratuit)**

1. Télécharger depuis : https://visualstudio.microsoft.com/fr/downloads/
2. Choisir **Visual Studio 2022 Community**

**Option B : Visual Studio Code (plus léger, recommandé pour Python)**

Si vous préférez VS Code (plus léger et mieux pour Python) :

1. Télécharger depuis : https://code.visualstudio.com/
2. Installer avec les options par défaut

**Je recommande VS Code pour ce projet**, mais les deux fonctionnent.

### 2. Configuration Visual Studio Code (si choisi)

#### Extensions à installer

Ouvrir VS Code et installer ces extensions (Ctrl+Shift+X) :

**Pour Python :**
1. **Python** (Microsoft) - Essentiel
2. **Pylance** (Microsoft) - IntelliSense avancé
3. **Python Indent** - Auto-indentation
4. **autoDocstring** - Documentation automatique
5. **Python Test Explorer** - Pour les tests

**Pour le développement :**
6. **GitLens** - Gestion Git avancée
7. **Docker** - Si vous utilisez Docker
8. **Thunder Client** - Tester les API (alternative à Postman)
9. **REST Client** - Tester les endpoints REST
10. **YAML** - Pour les fichiers de configuration

**Optionnel mais utile :**
11. **Jupyter** - Pour les notebooks
12. **Rainbow CSV** - Visualiser les CSV
13. **Error Lens** - Voir les erreurs en ligne

#### Configuration VS Code pour Python

1. Ouvrir VS Code
2. `Ctrl+Shift+P` → "Python: Select Interpreter"
3. Choisir la version de Python installée

**Créer un fichier de configuration** `.vscode/settings.json` :

```json
{
    "python.defaultInterpreterPath": "python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length", "100"],
    "editor.formatOnSave": true,
    "editor.rulers": [100],
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "[python]": {
        "editor.tabSize": 4,
        "editor.insertSpaces": true
    }
}
```

### 3. Configuration Visual Studio 2022 (si choisi)

#### Workloads à installer

Lors de l'installation, sélectionner :

1. **Python development**
   - Python language support
   - Python native development tools

2. **Desktop development with C++** (pour certaines librairies)
   - MSVC v143 ou plus récent
   - Windows 10/11 SDK
   - CMake tools

3. **Data science and analytical applications** (optionnel)
   - Pour Jupyter Notebooks

#### Configuration après installation

1. Ouvrir Visual Studio 2022
2. Aller dans `Tools` → `Options` → `Python` → `Environments`
3. Vérifier que Python est détecté
4. Si non détecté : `Add Environment` → Pointer vers votre installation Python

---

## 📱 Installation Android Studio et Flutter

### 1. Installer Android Studio

#### Téléchargement et installation

1. Télécharger depuis : https://developer.android.com/studio
2. Lancer l'installateur
3. Choisir "Standard" installation
4. Accepter les licences Android SDK

**Composants à installer dans Android Studio :**

1. Ouvrir Android Studio
2. `Configure` (ou `More Actions`) → `SDK Manager`
3. Dans l'onglet **SDK Platforms**, cocher :
   - ✅ Android 13.0 (API Level 33)
   - ✅ Android 12.0 (API Level 31)
   - ✅ Android 11.0 (API Level 30)

4. Dans l'onglet **SDK Tools**, cocher :
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Platform-Tools
   - ✅ Android SDK Tools (obsolete)
   - ✅ Android Emulator
   - ✅ Intel x86 Emulator Accelerator (HAXM)
   - ✅ Google Play services

5. Cliquer sur `Apply` et attendre le téléchargement

### 2. Installer Flutter

#### Téléchargement

1. Télécharger Flutter SDK : https://docs.flutter.dev/get-started/install/windows
2. Extraire dans `C:\src\flutter` (ou un autre dossier sans espaces)

#### Configuration PATH

**Ajouter Flutter au PATH :**

1. Rechercher "Variables d'environnement" dans Windows
2. Cliquer sur "Variables d'environnement"
3. Dans "Variables utilisateur", sélectionner `Path` et cliquer sur `Modifier`
4. Cliquer sur `Nouveau` et ajouter : `C:\src\flutter\bin`
5. Cliquer sur `OK`

**Vérifier l'installation :**

Ouvrir un **nouveau** terminal CMD ou PowerShell :

```cmd
flutter --version
flutter doctor
```

#### Résoudre les problèmes détectés par flutter doctor

```cmd
flutter doctor
```

Cette commande affichera les problèmes. Résoudre les issues :

**Si "Android licenses not accepted" :**

```cmd
flutter doctor --android-licenses
```

Accepter toutes les licences en tapant `y`.

**Si "cmdline-tools component is missing" :**

1. Ouvrir Android Studio
2. `SDK Manager` → `SDK Tools`
3. Cocher `Android SDK Command-line Tools (latest)`
4. Appliquer

### 3. Créer un émulateur Android

1. Ouvrir Android Studio
2. `Configure` → `AVD Manager` (Android Virtual Device Manager)
3. Cliquer sur `Create Virtual Device`
4. Choisir un appareil (ex: Pixel 5)
5. Choisir une image système (ex: Android 13, API 33)
6. Télécharger l'image si nécessaire
7. Nommer l'émulateur et créer

**Tester l'émulateur :**

```cmd
# Lister les émulateurs
flutter emulators

# Lancer un émulateur
flutter emulators --launch <nom_emulateur>
```

---

## 📦 Installation des dépendances du projet

### 1. Cloner le projet

```cmd
cd C:\Users\VotreNom\Documents
git clone https://github.com/oumar771/YOLO.git
cd YOLO
```

### 2. Installer les dépendances Python (Backend)

```cmd
cd backend

:: Créer un environnement virtuel
python -m venv venv

:: Activer l'environnement virtuel (Windows CMD)
venv\Scripts\activate.bat

:: OU pour PowerShell :
venv\Scripts\Activate.ps1

:: Si erreur PowerShell "execution policy", exécuter :
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

:: Mettre à jour pip
python -m pip install --upgrade pip

:: Installer les dépendances
pip install -r requirements.txt
```

**⚠️ Attention** : L'installation peut prendre 10-20 minutes selon votre connexion.

#### Problèmes courants lors de l'installation

**Si erreur avec `dlib` :**

```cmd
:: Installer CMake
pip install cmake

:: Puis réessayer
pip install dlib
```

**Si erreur avec des packages C++ :**

Installer **Visual Studio Build Tools** :
1. https://visualstudio.microsoft.com/downloads/
2. Chercher "Build Tools for Visual Studio 2022"
3. Installer avec workload "Desktop development with C++"

**Si erreur avec `torch` :**

Installer PyTorch manuellement :

```cmd
:: Pour CPU uniquement
pip install torch torchvision torchaudio

:: Pour GPU (NVIDIA CUDA 11.8)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

### 3. Installer les dépendances Flutter (App Mobile)

```cmd
cd ..
flutter pub get

:: OU si vous êtes dans un sous-dossier Flutter spécifique
cd chemin/vers/app/flutter
flutter pub get
```

### 4. Créer les dossiers nécessaires

```cmd
cd backend

:: Créer les dossiers
mkdir storage\images
mkdir storage\videos
mkdir storage\temp
mkdir storage\sync_queue
mkdir logs
mkdir trained_models
mkdir datasets\train\images
mkdir datasets\train\labels
mkdir datasets\val\images
mkdir datasets\val\labels
mkdir datasets\test\images
mkdir datasets\test\labels
```

### 5. Configurer les variables d'environnement

```cmd
cd backend

:: Copier le fichier de configuration
copy .env.example .env

:: Éditer avec VS Code ou Notepad
code .env
:: OU
notepad .env
```

**Configuration minimale pour démarrer** (`.env`) :

```env
# Serveur
HOST=0.0.0.0
PORT=8000
DEBUG=True
ENVIRONMENT=development

# Base de données (SQLite pour commencer)
DATABASE_URL=sqlite:///./storage/attendance.db

# JWT
SECRET_KEY=votre-cle-secrete-tres-longue-et-aleatoire-123456789

# YOLO (modèles par défaut)
CONFIDENCE_THRESHOLD=0.5

# Stockage local
LOCAL_STORAGE_PATH=./storage
OFFLINE_MODE=True

# Logs
LOG_LEVEL=INFO
LOG_FILE=./logs/app.log
```

---

## 🎮 Configuration CUDA (optionnel - GPU)

Si vous avez une carte graphique NVIDIA et voulez utiliser le GPU :

### 1. Vérifier la compatibilité

```cmd
nvidia-smi
```

Si cette commande fonctionne, vous avez les drivers NVIDIA installés.

### 2. Installer CUDA Toolkit

1. Télécharger CUDA 11.8 : https://developer.nvidia.com/cuda-11-8-0-download-archive
2. Choisir :
   - OS : Windows
   - Architecture : x86_64
   - Version : 10 ou 11
   - Installer type : exe (local)

3. Suivre l'installateur (options par défaut)

### 3. Installer cuDNN

1. Créer un compte NVIDIA (gratuit)
2. Télécharger cuDNN : https://developer.nvidia.com/cudnn
3. Extraire le ZIP
4. Copier les fichiers dans le dossier CUDA :
   ```
   cudnn/bin/*.dll → C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\bin
   cudnn/include/*.h → C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\include
   cudnn/lib/*.lib → C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\lib\x64
   ```

### 4. Installer PyTorch avec CUDA

```cmd
:: Activer l'environnement virtuel
venv\Scripts\activate

:: Installer PyTorch avec CUDA 11.8
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

**Vérifier que CUDA fonctionne :**

```cmd
python -c "import torch; print(torch.cuda.is_available())"
# Devrait afficher : True
```

---

## ✅ Test de l'installation

### 1. Tester le backend Python

```cmd
cd backend
venv\Scripts\activate

:: Initialiser la base de données
python -c "from app.database import init_db; init_db()"

:: Lancer le serveur
python run.py
```

**Résultat attendu :**

```
====================================
Starting YOLO Face Recognition System
====================================
Environment: development
Host: 0.0.0.0
Port: 8000
Debug mode: True
====================================
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Tester dans le navigateur :**

```
http://localhost:8000
http://localhost:8000/docs  (Documentation Swagger)
```

### 2. Tester l'application Flutter

**Dans un nouveau terminal :**

```cmd
cd YOLO

:: Lister les appareils disponibles
flutter devices

:: Lancer sur l'émulateur Android
flutter run

:: OU choisir un appareil spécifique
flutter run -d <device-id>
```

### 3. Test complet avec une image

```cmd
:: Dans le dossier backend avec venv activé

:: Ajouter un employé test
python scripts/add_employee.py ^
  --id "TEST001" ^
  --name "Test User" ^
  --email "test@test.com" ^
  --department "IT" ^
  --images path\to\photo1.jpg path\to\photo2.jpg path\to\photo3.jpg
```

**Tester la reconnaissance :**

```cmd
:: Avec cURL (installer depuis https://curl.se/windows/)
curl -X POST "http://localhost:8000/api/recognize" ^
  -F "file=@C:\path\to\test_photo.jpg"
```

**OU utiliser l'interface Swagger :**
- Aller sur http://localhost:8000/docs
- Chercher `/api/recognize`
- Cliquer sur "Try it out"
- Upload une image
- Cliquer sur "Execute"

---

## 🔧 Résolution des problèmes

### Problème : "Python not found"

**Solution :**
```cmd
:: Vérifier l'installation
where python

:: Si vide, réinstaller Python et cocher "Add to PATH"
```

### Problème : "pip install" échoue

**Solutions :**

```cmd
:: Mettre à jour pip
python -m pip install --upgrade pip

:: Installer setuptools et wheel
pip install --upgrade setuptools wheel

:: Si problème de certificat SSL
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org <package>
```

### Problème : "Permission denied" lors de l'activation du venv

**Solution PowerShell :**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problème : Flutter ne trouve pas Android SDK

**Solution :**

```cmd
:: Définir la variable d'environnement ANDROID_HOME
setx ANDROID_HOME "C:\Users\VotreNom\AppData\Local\Android\Sdk"

:: Redémarrer le terminal et vérifier
flutter doctor
```

### Problème : "Module not found" lors du lancement

**Solution :**

```cmd
:: Vérifier que le venv est activé
:: Le prompt devrait commencer par (venv)

:: Réinstaller les dépendances
pip install -r requirements.txt
```

### Problème : Port 8000 déjà utilisé

**Solution :**

```cmd
:: Trouver le processus
netstat -ano | findstr :8000

:: Tuer le processus
taskkill /PID <PID> /F

:: OU changer le port dans .env
PORT=8001
```

### Problème : Erreur CUDA / GPU

**Solution :**

```cmd
:: Vérifier les drivers NVIDIA
nvidia-smi

:: Réinstaller PyTorch CPU si problèmes GPU
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio
```

---

## 📝 Checklist finale

Avant de commencer à développer, vérifier que tout fonctionne :

- [ ] Python 3.10/3.11 installé et dans le PATH
- [ ] Git installé
- [ ] VS Code ou Visual Studio 2022 configuré
- [ ] Android Studio installé avec SDK
- [ ] Flutter installé et dans le PATH
- [ ] Émulateur Android créé et fonctionnel
- [ ] Dépendances Python installées (`pip list` dans venv)
- [ ] Serveur backend démarre (`python run.py`)
- [ ] Page http://localhost:8000 accessible
- [ ] Application Flutter démarre (`flutter run`)
- [ ] CUDA fonctionnel (optionnel - `torch.cuda.is_available()`)

---

## 🎯 Structure de travail recommandée

```
C:\Users\VotreNom\
├── Documents\
│   └── Projects\
│       └── YOLO\                    # Votre projet
│           ├── backend\             # Ouvrir ce dossier dans VS Code
│           │   └── venv\            # Environnement virtuel
│           └── [fichiers Flutter]   # Ouvrir dans Android Studio
│
└── AppData\Local\
    └── Android\
        └── Sdk\                     # Android SDK
```

**Workflow recommandé :**

1. **Terminal 1** : Backend Python
   ```cmd
   cd C:\Users\VotreNom\Documents\Projects\YOLO\backend
   venv\Scripts\activate
   python run.py
   ```

2. **Terminal 2** : Application Flutter
   ```cmd
   cd C:\Users\VotreNom\Documents\Projects\YOLO
   flutter run
   ```

3. **VS Code** : Éditer le code backend (Python)
4. **Android Studio** : Éditer l'application Flutter

---

## 🚀 Prochaines étapes

1. ✅ Lire [QUICKSTART.md](../QUICKSTART.md)
2. ✅ Ajouter des employés avec leurs photos
3. ✅ Tester la reconnaissance faciale
4. ✅ Explorer l'API avec Swagger (http://localhost:8000/docs)
5. ✅ Personnaliser l'application Flutter

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifier la [section Résolution des problèmes](#résolution-des-problèmes)
2. Consulter [README_SYSTEM.md](../README_SYSTEM.md)
3. Vérifier les logs dans `backend/logs/app.log`

---

**Bon développement ! 🎉**
