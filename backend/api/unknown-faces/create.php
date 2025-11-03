<?php
/**
 * Endpoint: POST /api/unknown-faces
 * Enregistrer un nouveau visage inconnu
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Vérifier l'authentification
$auth_data = JWTHandler::requireAuth();

// Obtenir les données POST
$data = json_decode(file_get_contents("php://input"));

// Vérifier les champs requis
$required_fields = ['photo_url', 'confidence'];
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

    // Insérer le visage inconnu
    $query = "INSERT INTO unknown_faces (timestamp, photo_url, confidence, notes)
              VALUES (:timestamp, :photo_url, :confidence, :notes)";

    $stmt = $db->prepare($query);

    $timestamp = isset($data->timestamp) ? $data->timestamp : date('Y-m-d H:i:s');
    $notes = $data->notes ?? null;

    $stmt->bindParam(':timestamp', $timestamp);
    $stmt->bindParam(':photo_url', $data->photo_url);
    $stmt->bindParam(':confidence', $data->confidence);
    $stmt->bindParam(':notes', $notes);

    if ($stmt->execute()) {
        $unknown_id = $db->lastInsertId();

        http_response_code(201);
        echo json_encode([
            'id' => (int)$unknown_id,
            'timestamp' => $timestamp,
            'photo_url' => $data->photo_url,
            'confidence' => (float)$data->confidence,
            'notes' => $notes,
            'message' => 'Unknown face recorded successfully'
        ]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
