<?php
/**
 * Endpoint: POST /api/attendances
 * Créer une nouvelle présence
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Vérifier l'authentification
$auth_data = JWTHandler::requireAuth();

// Obtenir les données POST
$data = json_decode(file_get_contents("php://input"));

// Vérifier les champs requis
$required_fields = ['employee_id', 'employee_name', 'confidence'];
foreach ($required_fields as $field) {
    if (!isset($data->$field)) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Bad Request',
            'message' => "Field '$field' is required"
        ]);
        exit();
    }
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Récupérer l'ID utilisateur depuis la base
    $user_query = "SELECT id FROM users WHERE employee_id = :employee_id LIMIT 1";
    $user_stmt = $db->prepare($user_query);
    $user_stmt->bindParam(':employee_id', $data->employee_id);
    $user_stmt->execute();

    if ($user_stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode([
            'error' => 'Not Found',
            'message' => 'Employee not found'
        ]);
        exit();
    }

    $user = $user_stmt->fetch(PDO::FETCH_ASSOC);
    $user_id = $user['id'];

    // Insérer la présence
    $query = "INSERT INTO attendances
              (user_id, employee_id, employee_name, timestamp, confidence, photo_url, location, device_info)
              VALUES
              (:user_id, :employee_id, :employee_name, :timestamp, :confidence, :photo_url, :location, :device_info)";

    $stmt = $db->prepare($query);

    $timestamp = isset($data->timestamp) ? $data->timestamp : date('Y-m-d H:i:s');
    $photo_url = $data->photo_url ?? null;
    $location = $data->location ?? null;
    $device_info = $data->device_info ?? null;

    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':employee_id', $data->employee_id);
    $stmt->bindParam(':employee_name', $data->employee_name);
    $stmt->bindParam(':timestamp', $timestamp);
    $stmt->bindParam(':confidence', $data->confidence);
    $stmt->bindParam(':photo_url', $photo_url);
    $stmt->bindParam(':location', $location);
    $stmt->bindParam(':device_info', $device_info);

    if ($stmt->execute()) {
        $attendance_id = $db->lastInsertId();

        http_response_code(201);
        echo json_encode([
            'id' => (int)$attendance_id,
            'employee_id' => $data->employee_id,
            'employee_name' => $data->employee_name,
            'timestamp' => $timestamp,
            'confidence' => (float)$data->confidence,
            'photo_url' => $photo_url,
            'message' => 'Attendance recorded successfully'
        ]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
