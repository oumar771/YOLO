# 🔧 Guide de résolution - Installation Windows avec Python 3.12

## 🎯 Votre problème

Vous avez Python 3.12, mais l'ancien `requirements.txt` nécessite Python ≤ 3.11.

---

## ✅ Solution 1 : Utiliser requirements-py312.txt (RECOMMANDÉ)

### Étapes

```powershell
# 1. Vérifier votre version de Python
python --version
# Devrait afficher Python 3.12.x

# 2. Si vous n'avez pas déjà créé le venv, le créer
python -m venv venv

# 3. Activer l'environnement virtuel
venv\Scripts\Activate.ps1

# Si erreur PowerShell "execution policy" :
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Mettre à jour pip
python -m pip install --upgrade pip

# 5. Installer avec le nouveau fichier
pip install -r requirements-py312.txt
```

### ⏱️ Temps d'installation : 15-30 minutes

---

## ✅ Solution 2 : Installation par étapes (si Solution 1 échoue)

Si l'installation complète échoue, installer par groupes :

### Étape 1 : Essentiels (obligatoire)

```powershell
pip install fastapi uvicorn sqlalchemy pydantic python-dotenv aiofiles
```

### Étape 2 : YOLO et Computer Vision (obligatoire)

```powershell
pip install ultralytics opencv-python numpy pillow matplotlib
```

### Étape 3 : PyTorch (obligatoire)

**Option A : CPU seulement (plus simple)**
```powershell
pip install torch torchvision
```

**Option B : GPU NVIDIA avec CUDA**
```powershell
# Pour CUDA 12.1
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# Pour CUDA 11.8
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

### Étape 4 : Base de données et sécurité (obligatoire)

```powershell
pip install python-jose passlib bcrypt httpx requests python-dateutil pytz
```

### Étape 5 : Reconnaissance faciale (optionnel - peut causer des problèmes)

**⚠️ Attention : Ces packages peuvent être difficiles à installer sur Windows**

```powershell
# Essayer d'abord
pip install onnxruntime

# Puis InsightFace (recommandé)
pip install insightface

# face-recognition et deepface (optionnels)
pip install face-recognition deepface
```

**Si `dlib` échoue :**
- Voir la section "Problème dlib" ci-dessous

### Étape 6 : Azure et notifications (optionnel)

```powershell
# Seulement si vous utilisez Azure
pip install azure-storage-blob azure-cosmos azure-identity

# Seulement si vous voulez les notifications email/SMS
pip install sendgrid twilio
```

### Étape 7 : Autres utilitaires (optionnel)

```powershell
pip install scikit-learn albumentations loguru pytest pytest-asyncio
```

---

## 🐛 Problèmes courants et solutions

### Problème 1 : `dlib` ne s'installe pas

**Solution A : Installer via wheel pré-compilé (plus facile)**

1. Télécharger le wheel pour Python 3.12 :
   - Aller sur : https://github.com/z-mahmud22/Dlib_Windows_Python3.x
   - OU : https://pypi.org/project/dlib/#files
   - Télécharger `dlib-19.24.x-cp312-cp312-win_amd64.whl`

2. Installer :
```powershell
pip install C:\chemin\vers\dlib-19.24.x-cp312-cp312-win_amd64.whl
```

**Solution B : Compiler dlib (nécessite Visual Studio)**

```powershell
# Installer CMake
pip install cmake

# Installer dlib
pip install dlib
```

**Solution C : Ignorer dlib temporairement**

Si dlib ne s'installe pas, vous pouvez continuer sans :
- `face-recognition` nécessite dlib
- Mais `insightface` fonctionne sans dlib
- Le système peut fonctionner avec seulement `insightface`

### Problème 2 : Erreur lors de l'installation d'un package C++

**Solution : Installer Visual Studio Build Tools**

1. Télécharger : https://visualstudio.microsoft.com/downloads/
2. Chercher "Build Tools for Visual Studio 2022"
3. Installer avec le workload **"Desktop development with C++"**
4. Redémarrer le terminal
5. Réessayer l'installation

### Problème 3 : `torch` ne s'installe pas

**Solution : Installer manuellement depuis PyTorch.org**

1. Aller sur https://pytorch.org/get-started/locally/
2. Choisir :
   - PyTorch Build : Stable
   - Your OS : Windows
   - Package : Pip
   - Language : Python
   - Compute Platform : CPU (ou CUDA selon votre GPU)

3. Copier et exécuter la commande fournie

**Exemple pour CPU :**
```powershell
pip install torch torchvision torchaudio
```

**Exemple pour CUDA 12.1 :**
```powershell
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Problème 4 : Erreur SSL/Certificate

**Solution :**

```powershell
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org <package-name>
```

### Problème 5 : Mémoire insuffisante lors de l'installation

**Solution :**

```powershell
# Installer avec option no-cache
pip install --no-cache-dir -r requirements-py312.txt

# OU installer un par un
pip install --no-cache-dir ultralytics
pip install --no-cache-dir torch
# etc.
```

---

## 🎯 Installation MINIMALE (pour démarrer rapidement)

Si vous voulez juste tester le système sans toutes les fonctionnalités :

```powershell
# 1. Activer venv
venv\Scripts\Activate.ps1

# 2. Installer le strict minimum
pip install fastapi uvicorn sqlalchemy pydantic python-dotenv
pip install ultralytics opencv-python numpy pillow
pip install torch torchvision
pip install python-jose passlib bcrypt
pip install httpx requests python-dateutil

# 3. Créer un .env minimal
copy .env.example .env

# 4. Tester
python -c "from app.database import init_db; init_db()"
python run.py
```

**Fonctionnalités disponibles avec l'installation minimale :**
- ✅ API REST FastAPI
- ✅ Détection YOLO (visages, objets)
- ✅ Base de données locale
- ✅ Stockage local
- ❌ Reconnaissance faciale (nécessite InsightFace)
- ❌ Azure Cloud
- ❌ Notifications email/SMS

---

## 🔍 Vérification de l'installation

### Test 1 : Vérifier les imports Python

```powershell
python
```

Dans Python :
```python
# Tester les imports principaux
import fastapi
print("✅ FastAPI OK")

import ultralytics
print("✅ Ultralytics OK")

import torch
print("✅ PyTorch OK")
print(f"CUDA disponible : {torch.cuda.is_available()}")

import cv2
print("✅ OpenCV OK")

import numpy
print("✅ NumPy OK")

# Tester InsightFace (optionnel)
try:
    import insightface
    print("✅ InsightFace OK")
except:
    print("⚠️ InsightFace non installé (optionnel)")

exit()
```

### Test 2 : Lancer le serveur

```powershell
# Initialiser la base de données
python -c "from app.database import init_db; init_db()"

# Lancer le serveur
python run.py
```

**Résultat attendu :**
```
====================================
Starting YOLO Face Recognition System
====================================
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Test 3 : Tester l'API

Ouvrir le navigateur : http://localhost:8000/docs

---

## 📊 Tableau récapitulatif des packages

| Package | Nécessaire ? | Problèmes Windows ? | Alternative |
|---------|--------------|---------------------|-------------|
| fastapi | ✅ Obligatoire | ✅ Facile | - |
| ultralytics | ✅ Obligatoire | ✅ Facile | - |
| torch | ✅ Obligatoire | ⚠️ Lourd (2-4GB) | - |
| opencv-python | ✅ Obligatoire | ✅ Facile | - |
| insightface | ⚠️ Recommandé | ⚠️ Moyen | deepface |
| face-recognition | ⚠️ Optionnel | ❌ Difficile (dlib) | insightface |
| dlib | ⚠️ Optionnel | ❌ Très difficile | Ignorer |
| deepface | ⚠️ Optionnel | ✅ Facile | insightface |
| azure-* | ❌ Optionnel | ✅ Facile | Stockage local |
| sendgrid | ❌ Optionnel | ✅ Facile | Logs seulement |
| twilio | ❌ Optionnel | ✅ Facile | Logs seulement |

---

## 💡 Recommandations

### Pour démarrer rapidement (30 minutes)
```powershell
pip install -r requirements-py312.txt
```

### Si problèmes, installation minimale (15 minutes)
```powershell
pip install fastapi uvicorn ultralytics torch opencv-python sqlalchemy pydantic
```

### Pour la reconnaissance faciale (ajouter après)
```powershell
pip install insightface onnxruntime
```

---

## 🎯 Ordre d'installation recommandé

1. **Installation de base** (obligatoire)
   ```powershell
   pip install fastapi uvicorn sqlalchemy pydantic python-dotenv
   ```

2. **YOLO** (obligatoire)
   ```powershell
   pip install ultralytics opencv-python numpy
   ```

3. **PyTorch** (obligatoire)
   ```powershell
   pip install torch torchvision
   ```

4. **Sécurité** (obligatoire)
   ```powershell
   pip install python-jose passlib bcrypt
   ```

5. **Reconnaissance faciale** (optionnel, peut échouer)
   ```powershell
   pip install insightface onnxruntime
   ```

6. **Le reste** (optionnel)
   ```powershell
   pip install -r requirements-py312.txt
   ```

---

## 📞 Besoin d'aide ?

Si les problèmes persistent :

1. Vérifier que Visual Studio Build Tools est installé
2. Vérifier la version de Python : `python --version`
3. Essayer l'installation minimale
4. Consulter les logs d'erreur complets
5. Chercher l'erreur spécifique sur Google/Stack Overflow

---

## 🚀 Après l'installation

Une fois l'installation réussie :

1. **Configurer** : Éditer `.env`
2. **Tester** : `python run.py`
3. **Ajouter un employé** : `python scripts/add_employee.py`
4. **Lire la doc** : [QUICKSTART.md](../QUICKSTART.md)

---

**Bon courage ! 🎉**
