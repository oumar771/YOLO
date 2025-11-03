<?php
/**
 * Endpoint: GET /api/employees
 * Récupérer la liste des employés
 */

require_once '../../config/config.php';
require_once '../../config/database.php';
require_once '../../utils/JWTHandler.php';

// Vérifier l'authentification
$auth_data = JWTHandler::requireAuth();

try {
    $database = new Database();
    $db = $database->getConnection();

    // Paramètres de filtrage
    $active_only = isset($_GET['active_only']) ? filter_var($_GET['active_only'], FILTER_VALIDATE_BOOLEAN) : true;
    $department = isset($_GET['department']) ? $_GET['department'] : null;

    // Construire la requête
    $query = "SELECT
                id,
                name,
                email,
                employee_id,
                department,
                photo_url,
                role,
                is_active,
                created_at
              FROM users
              WHERE 1=1";

    $params = [];

    if ($active_only) {
        $query .= " AND is_active = 1";
    }

    if ($department) {
        $query .= " AND department = :department";
        $params[':department'] = $department;
    }

    $query .= " ORDER BY name ASC";

    $stmt = $db->prepare($query);

    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }

    $stmt->execute();

    $employees = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $employees[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'email' => $row['email'],
            'employee_id' => $row['employee_id'],
            'department' => $row['department'],
            'photo_url' => $row['photo_url'],
            'role' => $row['role'],
            'is_active' => (bool)$row['is_active'],
            'created_at' => $row['created_at']
        ];
    }

    http_response_code(200);
    echo json_encode([
        'data' => $employees,
        'total' => count($employees)
    ]);

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal Server Error',
        'message' => DEBUG_MODE ? $e->getMessage() : 'An error occurred'
    ]);
}
