#!/bin/bash

# Script de configuration initiale du projet

echo "======================================"
echo "Configuration du système YOLO"
echo "======================================"

# Créer un environnement virtuel
echo "Création de l'environnement virtuel..."
python3 -m venv venv

# Activer l'environnement virtuel
echo "Activation de l'environnement virtuel..."
source venv/bin/activate

# Mettre à jour pip
echo "Mise à jour de pip..."
pip install --upgrade pip

# Installer les dépendances
echo "Installation des dépendances..."
pip install -r requirements.txt

# Créer les dossiers nécessaires
echo "Création des dossiers..."
mkdir -p storage/{images,videos,temp,sync_queue}
mkdir -p logs
mkdir -p trained_models

# Créer le fichier .env depuis .env.example
if [ ! -f .env ]; then
    echo "Création du fichier .env..."
    cp .env.example .env
    echo "⚠️  IMPORTANT: Veuillez configurer le fichier .env avec vos credentials"
fi

# Télécharger les modèles YOLO de base
echo "Téléchargement des modèles YOLO..."
python3 << EOF
from ultralytics import YOLO
import os

os.makedirs('trained_models', exist_ok=True)

print("Téléchargement de YOLOv8n...")
model = YOLO('yolov8n.pt')
print("Modèle YOLOv8n téléchargé!")
EOF

# Initialiser la base de données
echo "Initialisation de la base de données..."
python3 << EOF
from app.database import init_db
init_db()
print("Base de données initialisée!")
EOF

echo ""
echo "======================================"
echo "Configuration terminée!"
echo "======================================"
echo ""
echo "Prochaines étapes:"
echo "1. Configurez le fichier .env avec vos credentials"
echo "2. Ajoutez des employés: python scripts/add_employee.py"
echo "3. Lancez le serveur: python run.py"
echo ""
echo "Pour activer l'environnement virtuel:"
echo "  source venv/bin/activate"
echo ""
