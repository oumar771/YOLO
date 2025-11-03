<?php
/**
 * Endpoint: POST /api/auth/login
 * Authentification des utilisateurs
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Obtenir les données POST
$data = json_decode(file_get_contents("php://input"));

// Vérifier que les champs requis sont présents
if (!isset($data->email) || !isset($data->password)) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Bad Request',
        'message' => 'Email and password are required'
    ]);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Rechercher l'utilisateur par email
    $query = "SELECT id, name, email, password, employee_id, department, photo_url, role, is_active
              FROM users
              WHERE email = :email
              LIMIT 1";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        http_response_code(401);
        echo json_encode([
            'error' => 'Unauthorized',
            'message' => 'Invalid credentials'
        ]);
        exit();
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Vérifier si l'utilisateur est actif
    if (!$user['is_active']) {
        http_response_code(403);
        echo json_encode([
            'error' => 'Forbidden',
            'message' => 'Account is inactive'
        ]);
        exit();
    }

    // Vérifier le mot de passe
    if (!password_verify($data->password, $user['password'])) {
        http_response_code(401);
        echo json_encode([
            'error' => 'Unauthorized',
            'message' => 'Invalid credentials'
        ]);
        exit();
    }

    // Générer le token JWT
    $token = JWTHandler::generateToken(
        $user['id'],
        $user['email'],
        $user['employee_id']
    );

    // Retourner la réponse avec le token
    http_response_code(200);
    echo json_encode([
        'access_token' => $token,
        'token_type' => 'bearer',
        'expires_in' => JWT_EXPIRATION_TIME,
        'user' => [
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'employee_id' => $user['employee_id'],
            'department' => $user['department'],
            'photo_url' => $user['photo_url'],
            'role' => $user['role']
        ]
    ]);

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
