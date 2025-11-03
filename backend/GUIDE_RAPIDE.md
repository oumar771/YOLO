# 🚀 Guide Rapide - Installation Backend YOLO

## ⏱️ Installation en 5 minutes

### 1️⃣ Installer XAMPP
- Téléchargez : https://www.apachefriends.org/
- Installez et démarrez **Apache** et **MySQL**

### 2️⃣ Créer la base de données

1. Ouvrez phpMyAdmin : **http://localhost/phpmyadmin**
2. Cliquez sur l'onglet **"SQL"**
3. Copiez TOUT le contenu du fichier **`backend/database/jwtauth.sql`**
4. Collez dans la zone de texte et cliquez **"Exécuter"**

✅ **C'est fait !** La base `jwtauth` et toutes les tables sont créées automatiquement.

### 3️⃣ Copier les fichiers

Copiez le dossier `backend` dans :
```
C:\xampp\htdocs\yolo-backend\
```

### 4️⃣ Configuration

Ouvrez `backend/config/config.php` et vérifiez :

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'jwtauth');
define('DB_USER', 'root');
define('DB_PASS', ''); // Vide par défaut sur XAMPP
```

**IMPORTANT** : Changez la clé JWT pour la sécurité :
```php
define('JWT_SECRET_KEY', 'mettez_une_cle_aleatoire_longue_ici');
```

### 5️⃣ Tester

Ouvrez dans votre navigateur :
```
http://localhost/yolo-backend/api/test
```

Vous devriez voir :
```json
{
  "status": "success",
  "message": "API is working",
  "database": {
    "status": "success"
  }
}
```

---

## 🎯 Connexion depuis l'app Flutter

Modifiez dans `env.dart` :

**Émulateur Android :**
```dart
static const String BASE_URL = 'http://10.0.2.2/yolo-backend';
```

**Appareil physique (WiFi) :**
```dart
static const String BASE_URL = 'http://192.168.1.XXX/yolo-backend';
```
*Remplacez XXX par votre IP locale (trouvez-la avec `ipconfig`)*

---

## 🔑 Comptes de test

| Email | Password | Rôle |
|-------|----------|------|
| admin@yolo.com | admin123 | Admin |
| john@yolo.com | admin123 | Employé |
| hr@yolo.com | admin123 | RH |

---

## ❓ Problèmes courants

### ❌ "Database Connection Error"
→ Vérifiez que MySQL est démarré dans XAMPP

### ❌ L'app Flutter ne se connecte pas
→ Utilisez `10.0.2.2` pour émulateur Android (pas `localhost`)

### ❌ "404 Not Found"
→ Vérifiez que le dossier est bien dans `htdocs/yolo-backend/`

---

## 📖 Documentation complète

Pour plus de détails, consultez **README_BACKEND.md**

---

**✅ Vous êtes prêt !** Votre backend est opérationnel. 🎉
