<?php
/**
 * Endpoint: GET /api/unknown-faces
 * Récupérer les visages inconnus
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Vérifier l'authentification
$auth_data = JWTHandler::requireAuth();

try {
    $database = new Database();
    $db = $database->getConnection();

    // Paramètres de pagination
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = ($page - 1) * $limit;

    $is_notified = isset($_GET['is_notified']) ? $_GET['is_notified'] : null;

    // Construire la requête
    $query = "SELECT
                uf.id,
                uf.timestamp,
                uf.photo_url,
                uf.confidence,
                uf.is_notified,
                uf.notes,
                uf.resolved_at,
                u.name as resolved_by_name
              FROM unknown_faces uf
              LEFT JOIN users u ON uf.resolved_by = u.id
              WHERE 1=1";

    $params = [];

    if ($is_notified !== null) {
        $query .= " AND uf.is_notified = :is_notified";
        $params[':is_notified'] = $is_notified;
    }

    // Compter le total
    $count_query = "SELECT COUNT(*) as total FROM ($query) as count_table";
    $count_stmt = $db->prepare($count_query);
    foreach ($params as $key => $value) {
        $count_stmt->bindValue($key, $value);
    }
    $count_stmt->execute();
    $total = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Ajouter l'ordre et la pagination
    $query .= " ORDER BY uf.timestamp DESC LIMIT :limit OFFSET :offset";

    $stmt = $db->prepare($query);

    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

    $stmt->execute();

    $unknown_faces = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $unknown_faces[] = [
            'id' => (int)$row['id'],
            'timestamp' => $row['timestamp'],
            'photo_url' => $row['photo_url'],
            'confidence' => (float)$row['confidence'],
            'is_notified' => (bool)$row['is_notified'],
            'notes' => $row['notes'],
            'resolved_at' => $row['resolved_at'],
            'resolved_by_name' => $row['resolved_by_name']
        ];
    }

    http_response_code(200);
    echo json_encode([
        'data' => $unknown_faces,
        'pagination' => [
            'total' => (int)$total,
            'page' => $page,
            'limit' => $limit,
            'pages' => ceil($total / $limit)
        ]
    ]);

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
