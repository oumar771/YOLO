<?php
/**
 * Classe de gestion de la connexion à la base de données
 */

class Database {
    private $host = DB_HOST;
    private $db_name = DB_NAME;
    private $username = DB_USER;
    private $password = DB_PASS;
    private $conn = null;

    /**
     * Obtenir la connexion à la base de données
     */
    public function getConnection() {
        try {
            $dsn = "mysql:host={$this->host};dbname={$this->db_name};charset=utf8mb4";

            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
            ];

            $this->conn = new PDO($dsn, $this->username, $this->password, $options);

        } catch(PDOException $e) {
            if (DEBUG_MODE) {
                echo json_encode([
                    'error' => 'Database Connection Error',
                    'message' => $e->getMessage()
                ]);
            } else {
                echo json_encode([
                    'error' => 'Database Connection Error',
                    'message' => 'Unable to connect to database'
                ]);
            }
            exit();
        }

        return $this->conn;
    }

    /**
     * Fermer la connexion
     */
    public function closeConnection() {
        $this->conn = null;
    }

    /**
     * Tester la connexion
     */
    public static function testConnection() {
        try {
            $db = new Database();
            $conn = $db->getConnection();

            if ($conn) {
                return [
                    'status' => 'success',
                    'message' => 'Database connection successful'
                ];
            }
        } catch(Exception $e) {
            return [
                'status' => 'error',
                'message' => $e->getMessage()
            ];
        }
    }
}
