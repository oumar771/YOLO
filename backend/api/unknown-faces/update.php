<?php
/**
 * Endpoint: PUT /api/unknown-faces/{id}
 * Mettre à jour un visage inconnu (notes, statut de notification)
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Vérifier l'authentification
$auth_data = JWTHandler::requireAuth();

// Obtenir l'ID depuis l'URL
$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($id === 0) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Bad Request',
        'message' => 'Unknown face ID is required'
    ]);
    exit();
}

// Obtenir les données PUT
$data = json_decode(file_get_contents("php://input"));

try {
    $database = new Database();
    $db = $database->getConnection();

    // Vérifier que l'enregistrement existe
    $check_query = "SELECT id FROM unknown_faces WHERE id = :id";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(':id', $id);
    $check_stmt->execute();

    if ($check_stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode([
            'error' => 'Not Found',
            'message' => 'Unknown face not found'
        ]);
        exit();
    }

    // Construire la requête de mise à jour dynamique
    $update_fields = [];
    $params = [':id' => $id];

    if (isset($data->is_notified)) {
        $update_fields[] = "is_notified = :is_notified";
        $params[':is_notified'] = $data->is_notified ? 1 : 0;
    }

    if (isset($data->notes)) {
        $update_fields[] = "notes = :notes";
        $params[':notes'] = $data->notes;
    }

    if (isset($data->resolved)) {
        if ($data->resolved) {
            $update_fields[] = "resolved_by = :resolved_by";
            $update_fields[] = "resolved_at = :resolved_at";
            $params[':resolved_by'] = $auth_data->userId;
            $params[':resolved_at'] = date('Y-m-d H:i:s');
        } else {
            $update_fields[] = "resolved_by = NULL";
            $update_fields[] = "resolved_at = NULL";
        }
    }

    if (empty($update_fields)) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Bad Request',
            'message' => 'No valid fields to update'
        ]);
        exit();
    }

    $query = "UPDATE unknown_faces SET " . implode(', ', $update_fields) . " WHERE id = :id";

    $stmt = $db->prepare($query);

    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode([
            'id' => $id,
            'message' => 'Unknown face updated successfully'
        ]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
