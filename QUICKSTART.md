# 🚀 Quick Start Guide - Système YOLO de Reconnaissance Faciale

Guide de démarrage rapide pour être opérationnel en 10 minutes.

---

## ⚡ Installation rapide (5 minutes)

### 1. Prérequis

```bash
# Vérifier Python
python3 --version  # Doit être >= 3.8

# Vérifier pip
pip3 --version
```

### 2. Installation automatique

```bash
cd backend
chmod +x scripts/setup.sh
./scripts/setup.sh
```

✅ **C'est fait !** Le script installe tout automatiquement.

---

## 🎯 Premier test (3 minutes)

### 1. Configurer l'environnement

```bash
cd backend

# Copier la configuration
cp .env.example .env

# Éditer si nécessaire (optionnel pour le test)
nano .env
```

### 2. Ajouter un employé de test

```bash
# Activez l'environnement virtuel
source venv/bin/activate

# Ajoutez vous-même avec quelques photos
python scripts/add_employee.py \
  --id "TEST001" \
  --name "Votre Nom" \
  --email "votre@email.com" \
  --department "Test" \
  --images photo1.jpg photo2.jpg photo3.jpg
```

**💡 Conseil pour les photos :**
- Prenez 3-5 photos de votre visage
- Bonne lumière
- Visage de face
- Pas de lunettes de soleil

### 3. Lancer le serveur

```bash
python run.py
```

✅ Le serveur démarre sur : http://localhost:8000

### 4. Tester la reconnaissance

**Option A : Via le navigateur**

1. Ouvrir : http://localhost:8000/docs
2. Essayer l'endpoint `/api/recognize`
3. Upload une photo
4. Voir le résultat !

**Option B : Via cURL**

```bash
# Dans un autre terminal
curl -X POST "http://localhost:8000/api/recognize" \
  -F "file=@test_photo.jpg" \
  | jq .
```

**Résultat attendu :**

```json
{
  "success": true,
  "recognized": true,
  "employee": {
    "name": "Votre Nom",
    "department": "Test"
  },
  "confidence": 0.95
}
```

---

## 📱 Test avec l'application mobile (2 minutes)

### 1. Mise à jour de l'URL

Éditer `env.dart` :

```dart
static const String BASE_URL = 'http://10.0.2.2:8000';  // Pour émulateur Android
// OU
static const String BASE_URL = 'http://192.168.1.X:8000';  // Pour téléphone physique
```

### 2. Lancer l'app Flutter

```bash
# Dans le dossier racine du projet
flutter run
```

### 3. Tester la reconnaissance

1. Ouvrir l'app
2. Prendre une photo
3. ✅ Voir votre nom apparaître !

---

## 🎓 Entraîner votre propre modèle (optionnel)

### Sur Google Colab (GRATUIT + GPU)

1. **Ouvrir le notebook :**
   - Aller sur https://colab.research.google.com/
   - Upload `notebooks/train_yolo_face_recognition.ipynb`

2. **Activer le GPU :**
   - Runtime > Change runtime type
   - Choisir "GPU" (T4 gratuit)

3. **Exécuter toutes les cellules :**
   - Runtime > Run all
   - Attendre 1-2 heures

4. **Télécharger le modèle :**
   - Le modèle sera dans `trained_models/`
   - Download vers votre ordinateur

5. **Utiliser le nouveau modèle :**
   ```bash
   # Copier dans le backend
   cp /path/to/downloaded/model.pt backend/trained_models/yolov8n-face.pt

   # Redémarrer le serveur
   ```

---

## 🔧 Fonctionnalités à tester

### 1. Détection multi-classes

```bash
# Tester sur une image avec des personnes/animaux/armes
curl -X POST "http://localhost:8000/api/detect" \
  -F "file=@test_image.jpg" \
  -F "detection_type=all" \
  | jq .
```

### 2. Analyse vidéo

```bash
python backend/scripts/test_video.py test_video.mp4

# Résultat :
# - test_video_detected.mp4 (vidéo annotée)
# - test_video_detections.json (données)
```

### 3. Liste des présences

```bash
curl "http://localhost:8000/api/attendances" | jq .
```

### 4. Personnes inconnues

```bash
curl "http://localhost:8000/api/unknown-faces" | jq .
```

---

## 🐳 Alternative : Utiliser Docker (1 commande)

```bash
cd backend

# Construire et lancer
docker-compose up -d

# C'est tout ! Le serveur est prêt sur http://localhost:8000
```

---

## 📊 Interface Web (Swagger)

Le serveur fournit une interface web interactive :

**URL :** http://localhost:8000/docs

Vous pouvez :
- ✅ Tester tous les endpoints
- ✅ Upload des fichiers
- ✅ Voir la documentation
- ✅ Voir les schémas de données

---

## 🎯 Prochaines étapes

Maintenant que ça marche, vous pouvez :

1. **Ajouter plus d'employés**
   ```bash
   python scripts/add_employee.py --id EMP002 --name "..." --images ...
   ```

2. **Configurer les notifications**
   - Éditer `.env` avec vos clés SendGrid/Twilio
   - Les RH recevront des alertes automatiquement

3. **Configurer Azure (optionnel)**
   - Voir `docs/AZURE_DEPLOYMENT.md`
   - Synchronisation cloud automatique

4. **Entraîner un modèle personnalisé**
   - Voir `notebooks/train_yolo_face_recognition.ipynb`
   - Améliorer la précision

5. **Déployer en production**
   - Utiliser Docker
   - Déployer sur Azure App Service
   - Configurer HTTPS

---

## 🆘 Problèmes courants

### "Module not found"

```bash
# Réactiver l'environnement virtuel
cd backend
source venv/bin/activate

# Réinstaller les dépendances
pip install -r requirements.txt
```

### "No face detected"

- Vérifier la qualité de l'image
- Bonne lumière
- Visage bien visible
- Pas trop de distance

### "Port 8000 already in use"

```bash
# Trouver et tuer le processus
lsof -ti:8000 | xargs kill -9

# OU changer le port dans .env
PORT=8001
```

### "CUDA not available"

C'est normal ! Le système fonctionne aussi sur CPU.

Pour activer le GPU :
- Installer les drivers NVIDIA
- Installer CUDA toolkit
- Installer PyTorch avec support CUDA

---

## 📚 Documentation complète

- **Guide complet :** `README_SYSTEM.md`
- **Déploiement Azure :** `docs/AZURE_DEPLOYMENT.md`
- **Exemples d'usage :** `docs/EXAMPLES.md`
- **API Documentation :** http://localhost:8000/docs

---

## 💬 Support

Besoin d'aide ?

1. Vérifier la documentation complète
2. Chercher dans les issues GitHub
3. Créer une nouvelle issue

---

## 🎉 Félicitations !

Vous avez maintenant un système de reconnaissance faciale fonctionnel avec :

✅ Reconnaissance faciale YOLOv8
✅ Détection d'armes et animaux
✅ Enregistrement automatique des présences
✅ Notifications aux RH
✅ Mode hors connexion
✅ API REST complète
✅ Application mobile Flutter

**Temps total : ~10 minutes** ⚡

---

**Prêt pour la production ?** Consultez `README_SYSTEM.md` pour les étapes suivantes !
