# 🚀 Backend API YOLO Face Recognition Attendance

API REST pour l'application mobile YOLO de gestion des présences par reconnaissance faciale.

## 📋 Table des matières

- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Structure du projet](#structure-du-projet)
- [Endpoints API](#endpoints-api)
- [Authentification JWT](#authentification-jwt)
- [Tests](#tests)
- [Dépannage](#dépannage)

---

## 🔧 Prérequis

- **PHP 7.4+** ou **PHP 8.x**
- **MySQL 5.7+** ou **MariaDB 10.3+**
- **Apache** avec mod_rewrite activé
- **phpMyAdmin** (recommandé pour la gestion de la base de données)
- **XAMPP**, **WAMP**, ou **LAMP** (serveur local)

---

## 📦 Installation

### Étape 1: Installer le serveur local

Si vous n'avez pas encore de serveur local, installez **XAMPP** :
- Téléchargez XAMPP depuis : https://www.apachefriends.org/
- Installez et démarrez Apache et MySQL

### Étape 2: Créer la base de données

1. **Ouvrez phpMyAdmin** dans votre navigateur :
   ```
   http://localhost/phpmyadmin
   ```

2. **Importez le script SQL** :
   - Cliquez sur l'onglet **"SQL"** dans phpMyAdmin
   - Copiez tout le contenu du fichier `backend/database/jwtauth.sql`
   - Collez-le dans la zone de texte
   - Cliquez sur **"Exécuter"**

   ✅ Cela va créer automatiquement :
   - La base de données `jwtauth`
   - Toutes les tables nécessaires (users, attendances, unknown_faces, etc.)
   - 3 comptes utilisateurs de test
   - Des vues et procédures stockées utiles

### Étape 3: Copier les fichiers backend

1. **Copiez le dossier `backend`** dans le dossier `htdocs` de XAMPP :
   ```
   C:\xampp\htdocs\yolo-backend\
   ```

   Ou sur Linux/Mac :
   ```
   /opt/lampp/htdocs/yolo-backend/
   ```

### Étape 4: Configuration

1. **Ouvrez le fichier** `backend/config/config.php`

2. **Modifiez les paramètres de connexion** à la base de données si nécessaire :
   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'jwtauth');
   define('DB_USER', 'root');
   define('DB_PASS', ''); // Votre mot de passe MySQL (vide par défaut sur XAMPP)
   ```

3. **IMPORTANT - Changez la clé secrète JWT** (pour la sécurité) :
   ```php
   define('JWT_SECRET_KEY', 'votre_cle_secrete_super_forte_changez_moi');
   ```

   💡 Utilisez une clé aléatoire longue et complexe, par exemple :
   ```php
   define('JWT_SECRET_KEY', 'aZ9$mK2!pL7@xR4#nV8&qT5^wY3*bH6');
   ```

4. **Ajustez le fuseau horaire** (optionnel) :
   ```php
   date_default_timezone_set('Africa/Dakar'); // Changez selon votre localisation
   ```

### Étape 5: Vérifier mod_rewrite

Sur XAMPP, `mod_rewrite` est généralement activé. Pour vérifier :

1. Ouvrez `C:\xampp\apache\conf\httpd.conf`
2. Trouvez la ligne :
   ```
   #LoadModule rewrite_module modules/mod_rewrite.so
   ```
3. Supprimez le `#` au début si présent
4. Redémarrez Apache

---

## 🌐 Accès à l'API

Une fois installé, l'API est accessible à :

**Depuis votre ordinateur :**
```
http://localhost/yolo-backend/api
```

**Depuis l'émulateur Android (Flutter) :**
```
http://10.0.2.2/yolo-backend/api
```

**Depuis un appareil physique sur le même réseau WiFi :**
```
http://[VOTRE_IP_LOCALE]/yolo-backend/api
```

Pour trouver votre IP locale :
- Windows : `ipconfig` dans le CMD
- Linux/Mac : `ifconfig` ou `ip addr`

---

## 📁 Structure du projet

```
backend/
├── api/
│   ├── auth/
│   │   ├── login.php           # POST /api/auth/login
│   │   └── register.php        # POST /api/auth/register
│   ├── attendances/
│   │   ├── index.php          # GET /api/attendances
│   │   └── create.php         # POST /api/attendances
│   ├── employees/
│   │   └── index.php          # GET /api/employees
│   └── unknown-faces/
│       ├── index.php          # GET /api/unknown-faces
│       ├── create.php         # POST /api/unknown-faces
│       └── update.php         # PUT /api/unknown-faces/{id}
├── config/
│   ├── config.php             # Configuration principale
│   └── database.php           # Connexion PDO
├── database/
│   └── jwtauth.sql            # Script SQL
├── utils/
│   └── JWTHandler.php         # Gestion JWT
├── uploads/                   # Photos uploadées (créez ce dossier)
├── .htaccess                  # Configuration Apache
├── index.php                  # Router principal
└── README_BACKEND.md          # Cette documentation
```

---

## 🔐 Authentification JWT

### Comment ça marche ?

1. **Connexion** : L'utilisateur envoie email + mot de passe
2. **Token généré** : L'API retourne un JWT token valide 24h
3. **Requêtes authentifiées** : Le token est envoyé dans le header :
   ```
   Authorization: Bearer {votre_token}
   ```

### Exemple de connexion

**Requête :**
```bash
POST http://localhost/yolo-backend/api/auth/login
Content-Type: application/json

{
  "email": "admin@yolo.com",
  "password": "admin123"
}
```

**Réponse :**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@yolo.com",
    "employee_id": "EMP001",
    "department": "Administration",
    "photo_url": null,
    "role": "admin"
  }
}
```

---

## 📡 Endpoints API

### 🔓 Authentification (publics)

#### POST `/api/auth/login`
Connexion utilisateur
```json
{
  "email": "admin@yolo.com",
  "password": "admin123"
}
```

#### POST `/api/auth/register`
Inscription nouvel utilisateur
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "employee_id": "EMP003",
  "department": "IT"
}
```

### 🔒 Présences (authentifiés)

#### GET `/api/attendances`
Récupérer les présences
```
GET /api/attendances?page=1&limit=20&employee_id=EMP001&date_from=2025-11-01
```

**Paramètres :**
- `page` : Numéro de page (défaut: 1)
- `limit` : Éléments par page (défaut: 20)
- `employee_id` : Filtrer par employé
- `date_from` : Date de début (YYYY-MM-DD)
- `date_to` : Date de fin (YYYY-MM-DD)

#### POST `/api/attendances`
Créer une présence
```json
{
  "employee_id": "EMP002",
  "employee_name": "John Doe",
  "confidence": 95.5,
  "photo_url": "https://example.com/photo.jpg",
  "location": "Bureau principal",
  "device_info": "Samsung Galaxy S21"
}
```

### 👥 Employés (authentifiés)

#### GET `/api/employees`
Liste des employés
```
GET /api/employees?active_only=true&department=Engineering
```

### 👤 Visages inconnus (authentifiés)

#### GET `/api/unknown-faces`
Liste des visages inconnus
```
GET /api/unknown-faces?page=1&is_notified=0
```

#### POST `/api/unknown-faces`
Signaler un visage inconnu
```json
{
  "photo_url": "https://example.com/unknown.jpg",
  "confidence": 87.3,
  "notes": "Détecté à l'entrée principale"
}
```

#### PUT `/api/unknown-faces/{id}`
Mettre à jour un visage inconnu
```json
{
  "is_notified": true,
  "notes": "RH contacté",
  "resolved": true
}
```

---

## 🧪 Tests

### Test 1: Vérifier que l'API fonctionne

Ouvrez dans votre navigateur :
```
http://localhost/yolo-backend/api
```

Vous devriez voir :
```json
{
  "name": "YOLO Face Recognition Attendance API",
  "version": "v1",
  "status": "running",
  "endpoints": { ... }
}
```

### Test 2: Tester la connexion à la base de données

```
http://localhost/yolo-backend/api/test
```

Vous devriez voir :
```json
{
  "status": "success",
  "message": "API is working",
  "database": {
    "status": "success",
    "message": "Database connection successful"
  }
}
```

### Test 3: Tester la connexion (avec Postman ou curl)

**Avec curl :**
```bash
curl -X POST http://localhost/yolo-backend/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@yolo.com","password":"admin123"}'
```

**Avec Postman :**
1. Méthode : POST
2. URL : `http://localhost/yolo-backend/api/auth/login`
3. Headers : `Content-Type: application/json`
4. Body (raw JSON) :
   ```json
   {
     "email": "admin@yolo.com",
     "password": "admin123"
   }
   ```

---

## 👤 Comptes de test

La base de données contient 3 comptes par défaut :

| Rôle | Email | Password | Employee ID |
|------|-------|----------|-------------|
| Admin | admin@yolo.com | admin123 | EMP001 |
| Employé | john@yolo.com | admin123 | EMP002 |
| RH | hr@yolo.com | admin123 | HR001 |

---

## 🔧 Configuration de l'app Flutter

Dans votre fichier `env.dart` de l'application Flutter, modifiez l'URL :

**Pour émulateur Android :**
```dart
static const String BASE_URL = 'http://10.0.2.2/yolo-backend';
```

**Pour appareil physique (même WiFi) :**
```dart
static const String BASE_URL = 'http://192.168.1.XXX/yolo-backend'; // Votre IP locale
```

**Pour émulateur iOS :**
```dart
static const String BASE_URL = 'http://localhost/yolo-backend';
```

---

## ❗ Dépannage

### Problème : "Database Connection Error"

**Solutions :**
1. Vérifiez que MySQL est démarré dans XAMPP
2. Vérifiez les identifiants dans `config/config.php`
3. Vérifiez que la base de données `jwtauth` existe dans phpMyAdmin

### Problème : "404 Not Found" sur tous les endpoints

**Solutions :**
1. Vérifiez que `mod_rewrite` est activé dans Apache
2. Vérifiez que le fichier `.htaccess` existe
3. Vérifiez la configuration `AllowOverride All` dans httpd.conf

### Problème : "Invalid token" ou "No token provided"

**Solutions :**
1. Vérifiez que le header `Authorization: Bearer {token}` est présent
2. Vérifiez que le token n'a pas expiré (24h)
3. Reconnectez-vous pour obtenir un nouveau token

### Problème : L'app Flutter ne peut pas se connecter

**Solutions :**
1. **Émulateur Android** : Utilisez `10.0.2.2` au lieu de `localhost`
2. **Appareil physique** :
   - Assurez-vous d'être sur le même réseau WiFi
   - Utilisez votre IP locale (ex: `192.168.1.100`)
   - Désactivez le pare-feu temporairement
3. **Vérifiez les logs** :
   ```bash
   flutter run
   ```

### Problème : Erreur CORS

**Solution :**
- Les headers CORS sont déjà configurés dans `config.php`
- Si le problème persiste, ajoutez votre domaine spécifique :
  ```php
  define('CORS_ALLOWED_ORIGINS', 'http://localhost:3000');
  ```

---

## 🔒 Sécurité en production

Avant de déployer en production :

1. ✅ **Changez JWT_SECRET_KEY** avec une clé forte
2. ✅ **Désactivez DEBUG_MODE** :
   ```php
   define('DEBUG_MODE', false);
   ```
3. ✅ **Utilisez HTTPS** (SSL/TLS)
4. ✅ **Limitez CORS** aux domaines autorisés
5. ✅ **Sécurisez les uploads** de fichiers
6. ✅ **Configurez des sauvegardes** régulières de la base
7. ✅ **Utilisez des mots de passe forts** pour la base de données

---

## 📞 Support

Pour toute question ou problème :

1. Vérifiez la section [Dépannage](#dépannage)
2. Consultez les logs Apache : `xampp/apache/logs/error.log`
3. Activez `DEBUG_MODE` pour voir les erreurs détaillées

---

## 📄 Licence

Ce projet est développé pour l'application YOLO Face Recognition Attendance.

---

**Fait avec ❤️ pour votre projet YOLO**
