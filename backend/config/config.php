<?php
/**
 * Configuration principale de l'API YOLO Face Recognition
 */

// Configuration de la base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'jwtauth');
define('DB_USER', 'root');
define('DB_PASS', ''); // Changez selon votre configuration phpMyAdmin

// Configuration JWT
define('JWT_SECRET_KEY', 'votre_cle_secrete_super_forte_changez_moi'); // CHANGEZ CETTE CLÉ EN PRODUCTION !
define('JWT_ALGORITHM', 'HS256');
define('JWT_EXPIRATION_TIME', 86400); // 24 heures en secondes
define('JWT_ISSUER', 'yolo-attendance-api');

// Configuration de l'API
define('API_VERSION', 'v1');
define('API_BASE_PATH', '/api');

// Configuration CORS (pour permettre les requêtes depuis l'app Flutter)
define('CORS_ALLOWED_ORIGINS', '*'); // En production, spécifiez les domaines autorisés
define('CORS_ALLOWED_METHODS', 'GET, POST, PUT, DELETE, OPTIONS');
define('CORS_ALLOWED_HEADERS', 'Content-Type, Authorization, X-Requested-With');

// Configuration des uploads
define('UPLOAD_DIR', __DIR__ . '/../uploads/');
define('MAX_UPLOAD_SIZE', 5 * 1024 * 1024); // 5MB

// Timezone
date_default_timezone_set('Africa/Dakar'); // Changez selon votre localisation

// Mode debug (désactiver en production)
define('DEBUG_MODE', true);

// Gestion des erreurs
if (DEBUG_MODE) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// Headers CORS
header('Access-Control-Allow-Origin: ' . CORS_ALLOWED_ORIGINS);
header('Access-Control-Allow-Methods: ' . CORS_ALLOWED_METHODS);
header('Access-Control-Allow-Headers: ' . CORS_ALLOWED_HEADERS);
header('Access-Control-Max-Age: 3600');
header('Content-Type: application/json; charset=UTF-8');

// Gérer les requêtes OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
