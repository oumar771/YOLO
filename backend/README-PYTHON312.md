# 🔧 CORRECTIF : Requirements.txt pour Python 3.12+

Si vous avez Python 3.12, utilisez ce fichier au lieu de requirements.txt

## Installation

```cmd
pip install -r requirements-py312.txt
```

## Différences principales

- ultralytics >= 8.1.0 (compatible Python 3.12)
- torch >= 2.2.0 (dernières versions)
- Versions mises à jour pour Python 3.12

## Si des erreurs persistent

Installez par groupes :

### 1. Essentiels
```cmd
pip install fastapi uvicorn sqlalchemy pydantic python-dotenv
```

### 2. YOLO et Deep Learning
```cmd
pip install ultralytics opencv-python numpy
```

### 3. PyTorch
```cmd
# CPU seulement
pip install torch torchvision

# OU avec CUDA 12.1 (si GPU NVIDIA)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
```

### 4. Reconnaissance faciale (optionnel au début)
```cmd
# Attention : dlib peut être problématique sur Windows
pip install face-recognition insightface deepface
```

### 5. Azure (optionnel)
```cmd
pip install azure-storage-blob azure-cosmos azure-identity
```
