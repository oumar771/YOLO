<?php
/**
 * Point d'entrée principal de l'API YOLO Face Recognition
 * Router simple pour les requêtes API
 */

require_once 'config/config.php';

// Obtenir la méthode HTTP et l'URI
$method = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Nettoyer l'URI (enlever le chemin de base si nécessaire)
$uri = str_replace('/backend', '', $uri);
$uri = rtrim($uri, '/');

// Router les requêtes
switch (true) {
    // Test de connexion
    case $uri === '/api/test' && $method === 'GET':
        require_once 'config/database.php';
        echo json_encode([
            'status' => 'success',
            'message' => 'API is working',
            'version' => API_VERSION,
            'database' => Database::testConnection()
        ]);
        break;

    // Authentication endpoints
    case $uri === '/api/auth/login' && $method === 'POST':
        require 'api/auth/login.php';
        break;

    case $uri === '/api/auth/register' && $method === 'POST':
        require 'api/auth/register.php';
        break;

    // Attendance endpoints
    case $uri === '/api/attendances' && $method === 'GET':
        require 'api/attendances/index.php';
        break;

    case $uri === '/api/attendances' && $method === 'POST':
        require 'api/attendances/create.php';
        break;

    // Employee endpoints
    case $uri === '/api/employees' && $method === 'GET':
        require 'api/employees/index.php';
        break;

    // Unknown faces endpoints
    case $uri === '/api/unknown-faces' && $method === 'GET':
        require 'api/unknown-faces/index.php';
        break;

    case $uri === '/api/unknown-faces' && $method === 'POST':
        require 'api/unknown-faces/create.php';
        break;

    case preg_match('/^\/api\/unknown-faces\/(\d+)$/', $uri, $matches) && $method === 'PUT':
        $_GET['id'] = $matches[1];
        require 'api/unknown-faces/update.php';
        break;

    // Documentation / Info
    case $uri === '/' || $uri === '/api':
        echo json_encode([
            'name' => 'YOLO Face Recognition Attendance API',
            'version' => API_VERSION,
            'status' => 'running',
            'endpoints' => [
                'POST /api/auth/login' => 'Authenticate user',
                'POST /api/auth/register' => 'Register new user',
                'GET /api/attendances' => 'Get attendance records',
                'POST /api/attendances' => 'Create attendance record',
                'GET /api/employees' => 'Get employees list',
                'GET /api/unknown-faces' => 'Get unknown faces',
                'POST /api/unknown-faces' => 'Report unknown face',
                'PUT /api/unknown-faces/{id}' => 'Update unknown face',
                'GET /api/test' => 'Test API and database connection'
            ],
            'documentation' => 'See README_BACKEND.md for details'
        ]);
        break;

    // Route non trouvée
    default:
        http_response_code(404);
        echo json_encode([
            'error' => 'Not Found',
            'message' => 'Endpoint not found',
            'requested_uri' => $uri,
            'method' => $method
        ]);
        break;
}
