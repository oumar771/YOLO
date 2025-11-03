<?php
/**
 * Endpoint: GET /api/attendances
 * Récupérer les présences (avec authentification)
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Vérifier l'authentification
$auth_data = JWTHandler::requireAuth();

try {
    $database = new Database();
    $db = $database->getConnection();

    // Paramètres de pagination et filtrage
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = ($page - 1) * $limit;

    $employee_id = isset($_GET['employee_id']) ? $_GET['employee_id'] : null;
    $date_from = isset($_GET['date_from']) ? $_GET['date_from'] : null;
    $date_to = isset($_GET['date_to']) ? $_GET['date_to'] : null;

    // Construire la requête
    $query = "SELECT
                a.id,
                a.user_id,
                a.employee_id,
                a.employee_name,
                a.timestamp,
                a.confidence,
                a.photo_url,
                a.location,
                a.device_info,
                u.department,
                u.email
              FROM attendances a
              LEFT JOIN users u ON a.user_id = u.id
              WHERE 1=1";

    $params = [];

    // Filtrer par employee_id si fourni
    if ($employee_id) {
        $query .= " AND a.employee_id = :employee_id";
        $params[':employee_id'] = $employee_id;
    }

    // Filtrer par date de début
    if ($date_from) {
        $query .= " AND DATE(a.timestamp) >= :date_from";
        $params[':date_from'] = $date_from;
    }

    // Filtrer par date de fin
    if ($date_to) {
        $query .= " AND DATE(a.timestamp) <= :date_to";
        $params[':date_to'] = $date_to;
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
    $query .= " ORDER BY a.timestamp DESC LIMIT :limit OFFSET :offset";

    $stmt = $db->prepare($query);

    // Bind les paramètres
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

    $stmt->execute();

    $attendances = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $attendances[] = [
            'id' => (int)$row['id'],
            'employee_id' => $row['employee_id'],
            'employee_name' => $row['employee_name'],
            'timestamp' => $row['timestamp'],
            'confidence' => (float)$row['confidence'],
            'photo_url' => $row['photo_url'],
            'location' => $row['location'],
            'device_info' => $row['device_info'],
            'department' => $row['department'],
            'email' => $row['email']
        ];
    }

    // Retourner la réponse
    http_response_code(200);
    echo json_encode([
        'data' => $attendances,
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
