# 📘 Guide de déploiement Azure

Ce guide explique comment déployer le système de reconnaissance faciale YOLO sur Microsoft Azure avec le niveau gratuit.

---

## 🎁 Compte Azure gratuit

### Ce qui est inclus gratuitement

- **12 mois gratuits** :
  - 750 heures de VM B1S
  - 5 GB Blob Storage
  - 250 GB SQL Database
  - Azure App Service

- **Toujours gratuit** :
  - 5 GB Blob Storage
  - 10 Web/Mobile Apps
  - 1 million d'appels Azure Functions
  - Cosmos DB : 1000 RU/s avec 25 GB de stockage

### Créer un compte

1. Aller sur https://azure.microsoft.com/fr-fr/free/
2. Cliquer sur "Commencer gratuitement"
3. Se connecter avec un compte Microsoft
4. Fournir les informations de carte bancaire (non débitée)
5. Accepter les conditions

---

## 🏗️ Architecture Azure recommandée

```
┌─────────────────────────────────────────────────────┐
│                   Application Mobile                 │
│                      (Flutter)                       │
└────────────────────┬────────────────────────────────┘
                     │ HTTPS
                     ▼
┌─────────────────────────────────────────────────────┐
│              Azure App Service                       │
│            (Backend FastAPI)                         │
└──────┬──────────────────────┬────────────────┬──────┘
       │                      │                │
       ▼                      ▼                ▼
┌──────────────┐    ┌──────────────┐   ┌─────────────┐
│ Azure Blob   │    │  Cosmos DB   │   │   SendGrid  │
│   Storage    │    │  (Database)  │   │    (Email)  │
│  (Images)    │    │              │   │             │
└──────────────┘    └──────────────┘   └─────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│     Azure Machine Learning           │
│    (Entraînement des modèles)        │
└──────────────────────────────────────┘
```

---

## 📦 1. Déploiement du Backend (App Service)

### Option A : Via le portail Azure

1. **Créer un resource group**
   ```
   Portail Azure > Resource groups > Create
   - Name: rg-face-recognition
   - Region: West Europe
   ```

2. **Créer un App Service**
   ```
   Azure Portal > App Services > Create
   - Name: face-recognition-api
   - Runtime: Python 3.10
   - Region: West Europe
   - Plan: Free F1 (gratuit)
   ```

3. **Déployer le code**
   ```bash
   # Installer Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Se connecter
   az login

   # Déployer
   cd backend
   az webapp up \
     --name face-recognition-api \
     --resource-group rg-face-recognition \
     --runtime "PYTHON:3.10"
   ```

### Option B : Déploiement automatique avec GitHub Actions

1. **Créer le workflow**

Créer `.github/workflows/azure-deploy.yml` :

```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        cd backend
        pip install -r requirements.txt

    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: face-recognition-api
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: ./backend
```

2. **Configurer les secrets GitHub**
   - Aller dans les settings du repo
   - Secrets and variables > Actions > New repository secret
   - Ajouter `AZURE_WEBAPP_PUBLISH_PROFILE`

---

## 💾 2. Configuration du stockage (Blob Storage)

### Créer un compte de stockage

```bash
# Créer le compte
az storage account create \
  --name facerecstorage \
  --resource-group rg-face-recognition \
  --location westeurope \
  --sku Standard_LRS \
  --kind StorageV2

# Créer les conteneurs
az storage container create \
  --name face-images \
  --account-name facerecstorage \
  --public-access off

az storage container create \
  --name training-data \
  --account-name facerecstorage \
  --public-access off

az storage container create \
  --name models \
  --account-name facerecstorage \
  --public-access off

# Obtenir la connection string
az storage account show-connection-string \
  --name facerecstorage \
  --resource-group rg-face-recognition \
  --output tsv
```

### Configurer dans l'App Service

```bash
az webapp config appsettings set \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --settings AZURE_STORAGE_CONNECTION_STRING="your-connection-string"
```

---

## 🗄️ 3. Configuration de Cosmos DB

### Créer un compte Cosmos DB (niveau gratuit)

```bash
# Créer le compte
az cosmosdb create \
  --name facereccosmosdb \
  --resource-group rg-face-recognition \
  --default-consistency-level Session \
  --enable-free-tier true

# Créer une base de données
az cosmosdb sql database create \
  --account-name facereccosmosdb \
  --resource-group rg-face-recognition \
  --name attendance_db \
  --throughput 400

# Créer les conteneurs
az cosmosdb sql container create \
  --account-name facereccosmosdb \
  --database-name attendance_db \
  --name attendances \
  --partition-key-path /employee_id \
  --throughput 400

az cosmosdb sql container create \
  --account-name facereccosmosdb \
  --database-name attendance_db \
  --name unknown_faces \
  --partition-key-path /id \
  --throughput 400

az cosmosdb sql container create \
  --account-name facereccosmosdb \
  --database-name attendance_db \
  --name detection_events \
  --partition-key-path /detection_type \
  --throughput 400

# Obtenir les clés
az cosmosdb keys list \
  --name facereccosmosdb \
  --resource-group rg-face-recognition \
  --type keys
```

### Configurer dans l'App Service

```bash
az webapp config appsettings set \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --settings \
    AZURE_COSMOS_ENDPOINT="https://facereccosmosdb.documents.azure.com:443/" \
    AZURE_COSMOS_KEY="your-cosmos-key" \
    AZURE_COSMOS_DATABASE_NAME="attendance_db"
```

---

## 🤖 4. Azure Machine Learning (Entraînement)

### Créer un workspace Azure ML

```bash
# Installer l'extension ML
az extension add -n ml

# Créer le workspace
az ml workspace create \
  --name face-recognition-ml \
  --resource-group rg-face-recognition \
  --location westeurope
```

### Créer un compute instance (CPU gratuit)

```bash
# Compute CPU pour développement (gratuit)
az ml compute create \
  --name cpu-cluster \
  --resource-group rg-face-recognition \
  --workspace-name face-recognition-ml \
  --type ComputeInstance \
  --size Standard_DS3_v2 \
  --min-instances 0 \
  --max-instances 1
```

### Upload le notebook d'entraînement

1. Aller sur https://ml.azure.com
2. Sélectionner votre workspace
3. Notebooks > Upload
4. Uploader `notebooks/train_yolo_face_recognition.ipynb`
5. Créer un compute instance et lancer le notebook

### Entraînement avec Azure ML SDK

```python
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from azure.ai.ml import command
from azure.ai.ml.entities import Environment

# Se connecter
ml_client = MLClient.from_config(DefaultAzureCredential())

# Définir l'environnement
env = Environment(
    name="yolo-training-env",
    conda_file="environment.yml",
    image="mcr.microsoft.com/azureml/openmpi4.1.0-cuda11.1-cudnn8-ubuntu20.04"
)

# Créer le job d'entraînement
job = command(
    code="./notebooks",
    command="python train_script.py --epochs 100 --batch 16",
    environment=env,
    compute="cpu-cluster",
    display_name="yolo-face-training"
)

# Soumettre le job
returned_job = ml_client.jobs.create_or_update(job)
```

---

## 📧 5. Configuration SendGrid (Notifications)

### Créer un compte SendGrid

1. Aller sur https://portal.azure.com
2. Créer une ressource SendGrid
3. Plan gratuit : 100 emails/jour

```bash
# Via Azure Marketplace
# 1. Chercher "SendGrid" dans le Marketplace
# 2. Créer avec plan gratuit
# 3. Obtenir l'API key depuis le portail SendGrid
```

### Configurer dans l'App Service

```bash
az webapp config appsettings set \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --settings \
    SENDGRID_API_KEY="your-sendgrid-key" \
    HR_EMAIL="rh@votreentreprise.com"
```

---

## 🔐 6. Sécurité

### Configurer SSL/TLS

Azure App Service fournit automatiquement un certificat SSL gratuit.

Pour un domaine personnalisé :

```bash
# Ajouter un domaine personnalisé
az webapp config hostname add \
  --webapp-name face-recognition-api \
  --resource-group rg-face-recognition \
  --hostname www.votredomaine.com

# Activer HTTPS
az webapp update \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --https-only true
```

### Configurer les variables d'environnement sécurisées

```bash
az webapp config appsettings set \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --settings \
    SECRET_KEY="your-very-long-secret-key" \
    DATABASE_URL="your-database-url" \
    ENVIRONMENT="production"
```

### Activer Application Insights (monitoring)

```bash
az monitor app-insights component create \
  --app face-recognition-insights \
  --location westeurope \
  --resource-group rg-face-recognition \
  --application-type web

# Lier à l'App Service
az webapp config appsettings set \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="your-connection-string"
```

---

## 📊 7. Monitoring et logs

### Voir les logs en temps réel

```bash
az webapp log tail \
  --name face-recognition-api \
  --resource-group rg-face-recognition
```

### Configuration des logs

```bash
az webapp log config \
  --name face-recognition-api \
  --resource-group rg-face-recognition \
  --application-logging filesystem \
  --detailed-error-messages true \
  --failed-request-tracing true \
  --web-server-logging filesystem
```

### Dashboard dans Azure Portal

1. Aller sur Azure Portal
2. App Service > face-recognition-api
3. Monitoring > Metrics
4. Créer des graphiques pour :
   - Requêtes par seconde
   - Temps de réponse
   - Erreurs 5xx
   - Utilisation CPU/Mémoire

---

## 💰 8. Optimisation des coûts

### Conseils pour rester dans le niveau gratuit

1. **App Service**
   - Utiliser le plan F1 (gratuit)
   - Limite : 60 minutes CPU/jour
   - 1 GB RAM, 1 GB stockage

2. **Blob Storage**
   - Nettoyer régulièrement les anciennes images
   - Utiliser lifecycle policies pour archiver
   - Limite gratuite : 5 GB

3. **Cosmos DB**
   - Utiliser le niveau gratuit (1000 RU/s)
   - Optimiser les requêtes
   - Utiliser le partitioning efficacement

4. **Azure ML**
   - Utiliser compute instances au lieu de clusters
   - Arrêter les instances quand non utilisées
   - Entraîner localement ou sur Colab si possible

### Configurer les alertes de coût

```bash
# Créer un budget
az consumption budget create \
  --budget-name monthly-budget \
  --amount 10 \
  --time-grain Monthly \
  --resource-group rg-face-recognition
```

---

## 🚀 9. Déploiement complet (Script automatique)

Créer `deploy_azure.sh` :

```bash
#!/bin/bash

# Variables
RESOURCE_GROUP="rg-face-recognition"
LOCATION="westeurope"
APP_NAME="face-recognition-api"
STORAGE_NAME="facerecstorage"
COSMOS_NAME="facereccosmosdb"

# Créer le resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Créer l'App Service
az webapp up \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --runtime "PYTHON:3.10" \
  --sku F1

# Créer le stockage
az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku Standard_LRS

# Créer Cosmos DB
az cosmosdb create \
  --name $COSMOS_NAME \
  --resource-group $RESOURCE_GROUP \
  --enable-free-tier true

# Obtenir les connection strings
STORAGE_CONN=$(az storage account show-connection-string \
  --name $STORAGE_NAME --output tsv)

COSMOS_KEY=$(az cosmosdb keys list \
  --name $COSMOS_NAME \
  --resource-group $RESOURCE_GROUP \
  --type keys --query primaryMasterKey --output tsv)

# Configurer l'App Service
az webapp config appsettings set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_STORAGE_CONNECTION_STRING="$STORAGE_CONN" \
    AZURE_COSMOS_ENDPOINT="https://$COSMOS_NAME.documents.azure.com:443/" \
    AZURE_COSMOS_KEY="$COSMOS_KEY"

echo "Déploiement terminé!"
echo "URL: https://$APP_NAME.azurewebsites.net"
```

Rendre exécutable et lancer :

```bash
chmod +x deploy_azure.sh
./deploy_azure.sh
```

---

## 🧪 10. Tests après déploiement

```bash
# Tester l'API
curl https://face-recognition-api.azurewebsites.net/

# Tester la reconnaissance
curl -X POST "https://face-recognition-api.azurewebsites.net/api/recognize" \
  -F "file=@test_image.jpg"

# Vérifier les logs
az webapp log tail --name face-recognition-api --resource-group rg-face-recognition
```

---

## 📱 11. Mettre à jour l'application Flutter

Modifier `env.dart` :

```dart
class Environment {
  static const String BASE_URL = 'https://face-recognition-api.azurewebsites.net';

  // Endpoints
  static const String RECOGNIZE_ENDPOINT = '/api/recognize';
  static const String DETECT_ENDPOINT = '/api/detect';
  // ...
}
```

---

## 🆘 Dépannage

### Erreur : App Service ne démarre pas

```bash
# Vérifier les logs
az webapp log tail --name face-recognition-api

# Vérifier les dépendances
# S'assurer que requirements.txt est correct
```

### Erreur : Connexion à Cosmos DB échoue

```bash
# Vérifier les clés
az cosmosdb keys list --name facereccosmosdb

# Tester la connexion
az cosmosdb check-name-exists --name facereccosmosdb
```

### Erreur : Stockage inaccessible

```bash
# Vérifier les permissions
az storage account show --name facerecstorage

# Régénérer les clés si nécessaire
az storage account keys renew --name facerecstorage --key primary
```

---

## 📚 Ressources supplémentaires

- [Documentation Azure App Service](https://docs.microsoft.com/azure/app-service/)
- [Documentation Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/)
- [Azure ML Documentation](https://docs.microsoft.com/azure/machine-learning/)
- [Azure Free Account](https://azure.microsoft.com/free/)

---

**Note importante** : Ce guide utilise principalement les services gratuits d'Azure. Pour une utilisation en production à grande échelle, envisagez de passer à des plans payants avec plus de ressources.
