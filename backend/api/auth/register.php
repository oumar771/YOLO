<?php
/**
 * Endpoint: POST /api/auth/register
 * Enregistrement de nouveaux utilisateurs
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Obtenir les données POST
$data = json_decode(file_get_contents("php://input"));

// Vérifier les champs requis
$required_fields = ['name', 'email', 'password', 'employee_id'];
foreach ($required_fields as $field) {
    if (!isset($data->$field) || empty($data->$field)) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Bad Request',
            'message' => "Field '$field' is required"
        ]);
        exit();
    }
}

// Valider l'email
if (!filter_var($data->email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Bad Request',
        'message' => 'Invalid email format'
    ]);
    exit();
}

// Valider le mot de passe (minimum 6 caractères)
if (strlen($data->password) < 6) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Bad Request',
        'message' => 'Password must be at least 6 characters long'
    ]);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Vérifier si l'email existe déjà
    $check_query = "SELECT id FROM users WHERE email = :email OR employee_id = :employee_id";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(':email', $data->email);
    $check_stmt->bindParam(':employee_id', $data->employee_id);
    $check_stmt->execute();

    if ($check_stmt->rowCount() > 0) {
        http_response_code(409);
        echo json_encode([
            'error' => 'Conflict',
            'message' => 'Email or Employee ID already exists'
        ]);
        exit();
    }

    // Hasher le mot de passe
    $hashed_password = password_hash($data->password, PASSWORD_DEFAULT);

    // Insérer le nouvel utilisateur
    $query = "INSERT INTO users (name, email, password, employee_id, department, role)
              VALUES (:name, :email, :password, :employee_id, :department, :role)";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':name', $data->name);
    $stmt->bindParam(':email', $data->email);
    $stmt->bindParam(':password', $hashed_password);
    $stmt->bindParam(':employee_id', $data->employee_id);

    $department = $data->department ?? null;
    $role = $data->role ?? 'employee';

    $stmt->bindParam(':department', $department);
    $stmt->bindParam(':role', $role);

    if ($stmt->execute()) {
        $user_id = $db->lastInsertId();

        // Générer le token JWT
        $token = JWTHandler::generateToken(
            $user_id,
            $data->email,
            $data->employee_id
        );

        // Retourner la réponse
        http_response_code(201);
        echo json_encode([
            'access_token' => $token,
            'token_type' => 'bearer',
            'expires_in' => JWT_EXPIRATION_TIME,
            'user' => [
                'id' => (int)$user_id,
                'name' => $data->name,
                'email' => $data->email,
                'employee_id' => $data->employee_id,
                'department' => $department,
                'photo_url' => null,
                'role' => $role
            ]
        ]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
