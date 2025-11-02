# 🆘 Guide de dépannage rapide - Erreur ModuleNotFoundError

## 🎯 Votre erreur

```
ModuleNotFoundError: No module named 'pydantic_settings'
```

Cela signifie que l'installation n'a pas été complétée correctement.

---

## ✅ SOLUTION RAPIDE (2 minutes)

### Méthode 1 : Installer les modules manquants un par un

```powershell
# 1. Vérifier que venv est activé
# Votre prompt devrait commencer par (venv)

# Si pas activé :
venv\Scripts\Activate.ps1

# 2. Installer les modules manquants
pip install pydantic-settings
pip install fastapi uvicorn
pip install sqlalchemy
pip install python-dotenv
pip install python-multipart

# 3. Réessayer
python run.py
```

### Méthode 2 : Script d'installation automatique (RECOMMANDÉ)

**Pour PowerShell :**
```powershell
# Exécuter le script d'installation progressif
.\install-essentials.ps1
```

**Pour CMD :**
```cmd
install-essentials.bat
```

**Ce script va :**
- ✅ Installer chaque package individuellement
- ✅ Afficher la progression (1/15, 2/15, etc.)
- ✅ S'arrêter si une erreur critique survient
- ✅ Continuer si l'erreur n'est pas critique (ex: InsightFace)
- ✅ Vérifier que tout fonctionne à la fin

⏱️ **Temps : 15-20 minutes**

---

## 🔍 Diagnostic : Vérifier ce qui est installé

```powershell
# Lister tous les packages installés
pip list

# Vérifier les packages essentiels
pip list | findstr fastapi
pip list | findstr pydantic
pip list | findstr ultralytics
pip list | findstr torch
```

---

## 📦 Liste des packages ESSENTIELS (minimum vital)

Ces packages DOIVENT être installés pour que le serveur démarre :

```powershell
# Installer le strict minimum
pip install fastapi
pip install uvicorn[standard]
pip install pydantic
pip install pydantic-settings
pip install sqlalchemy
pip install python-dotenv
pip install python-multipart
pip install python-jose[cryptography]
pip install passlib[bcrypt]
pip install httpx
pip install requests
pip install python-dateutil
pip install aiofiles
pip install loguru
```

⏱️ **Temps : 2-3 minutes**

---

## 🚀 Test après installation

### 1. Vérifier les imports Python

```powershell
python
```

Dans Python :
```python
# Tester les imports un par un
import fastapi
print("✓ FastAPI OK")

import pydantic
print("✓ Pydantic OK")

from pydantic_settings import BaseSettings
print("✓ Pydantic Settings OK")

import sqlalchemy
print("✓ SQLAlchemy OK")

import uvicorn
print("✓ Uvicorn OK")

# Tout est OK ? Quitter
exit()
```

### 2. Initialiser la base de données

```powershell
python -c "from app.database import init_db; init_db()"
```

**Si cette commande fonctionne** ✅ → Vous pouvez passer à l'étape 3

**Si erreur** ❌ → Notez l'erreur et installez le module manquant

### 3. Lancer le serveur

```powershell
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
...
INFO:     Uvicorn running on http://0.0.0.0:8000
```

---

## 🐛 Erreurs courantes après pydantic_settings

### Erreur : "No module named 'ultralytics'"

```powershell
pip install ultralytics opencv-python numpy torch torchvision
```

### Erreur : "No module named 'sqlalchemy'"

```powershell
pip install sqlalchemy
```

### Erreur : "No module named 'jose'"

```powershell
pip install python-jose[cryptography]
```

### Erreur : "No module named 'passlib'"

```powershell
pip install passlib[bcrypt]
```

### Erreur : "No module named 'cv2'" (OpenCV)

```powershell
pip install opencv-python
```

### Erreur : "No module named 'torch'"

```powershell
# CPU seulement
pip install torch torchvision

# Ou avec CUDA (GPU NVIDIA)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

---

## 🎯 Installation par ordre de priorité

Si vous voulez installer progressivement, voici l'ordre recommandé :

### Groupe 1 : Framework API (OBLIGATOIRE)
```powershell
pip install fastapi uvicorn[standard] pydantic pydantic-settings python-multipart
```

### Groupe 2 : Base de données (OBLIGATOIRE)
```powershell
pip install sqlalchemy python-dotenv
```

### Groupe 3 : Sécurité (OBLIGATOIRE)
```powershell
pip install python-jose[cryptography] passlib[bcrypt]
```

### Groupe 4 : Utilitaires (OBLIGATOIRE)
```powershell
pip install httpx requests python-dateutil pytz aiofiles loguru
```

**➡️ Après ces 4 groupes, vous pouvez lancer `python run.py` !**

### Groupe 5 : YOLO et Computer Vision (pour détection)
```powershell
pip install numpy pillow opencv-python
pip install torch torchvision
pip install ultralytics
```

### Groupe 6 : Reconnaissance faciale (optionnel)
```powershell
pip install onnxruntime insightface
```

### Groupe 7 : Azure Cloud (optionnel)
```powershell
pip install azure-storage-blob azure-cosmos azure-identity
```

---

## 🔄 Réinstallation complète (si tout échoue)

Si rien ne fonctionne, réinitialiser complètement :

```powershell
# 1. Désactiver venv
deactivate

# 2. Supprimer le venv
Remove-Item -Recurse -Force venv

# 3. Recréer le venv
python -m venv venv

# 4. Activer
venv\Scripts\Activate.ps1

# 5. Mettre à jour pip
python -m pip install --upgrade pip

# 6. Installer avec le script
.\install-essentials.ps1
```

---

## 📊 Vérification finale

Après l'installation, vérifier que tout fonctionne :

```powershell
# 1. Lister les packages installés
pip list

# 2. Compter les packages (devrait être 50+)
pip list | Measure-Object -Line

# 3. Vérifier les essentiels
pip show fastapi
pip show pydantic
pip show ultralytics

# 4. Tester le serveur
python run.py
```

---

## 💡 Astuces

### Installer sans cache (si problème de mémoire)

```powershell
pip install --no-cache-dir <package>
```

### Voir les logs d'installation détaillés

```powershell
pip install --verbose <package>
```

### Installer une version spécifique

```powershell
# Si la dernière version cause des problèmes
pip install pydantic==2.5.0
pip install fastapi==0.109.0
```

---

## 🎯 Commande tout-en-un (installation minimale)

Si vous voulez juste une seule commande pour démarrer :

```powershell
pip install fastapi uvicorn[standard] pydantic pydantic-settings sqlalchemy python-dotenv python-multipart python-jose[cryptography] passlib[bcrypt] httpx requests python-dateutil aiofiles loguru numpy pillow opencv-python torch torchvision ultralytics
```

⚠️ **Attention** : Cette commande peut prendre 15-20 minutes

---

## 📞 Toujours bloqué ?

Si après tout ça, vous avez toujours des erreurs :

1. **Copiez l'erreur complète** (toutes les lignes rouges)
2. **Notez le nom du module manquant**
3. **Installez-le :** `pip install <nom-du-module>`
4. **Réessayez :** `python run.py`

**Répétez jusqu'à ce que le serveur démarre.**

---

## ✅ Checklist de succès

- [ ] `venv` activé (prompt commence par `(venv)`)
- [ ] `pip install pydantic-settings` réussi
- [ ] Script `install-essentials.ps1` exécuté
- [ ] `python -c "from pydantic_settings import BaseSettings"` fonctionne
- [ ] `python -c "from app.database import init_db"` fonctionne
- [ ] `python run.py` démarre le serveur
- [ ] `http://localhost:8000` accessible dans le navigateur

---

**🚀 Lancez maintenant le script d'installation :**

```powershell
.\install-essentials.ps1
```

**Et tout devrait fonctionner ! 🎉**
