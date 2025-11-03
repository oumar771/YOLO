-- ================================================
-- Script SQL pour la base de données JWTAUTH
-- Application: YOLO Face Recognition Attendance
-- ================================================

-- Créer la base de données
CREATE DATABASE IF NOT EXISTS jwtauth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE jwtauth;

-- ================================================
-- Table: users
-- Description: Stocke les informations des employés/utilisateurs
-- ================================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    employee_id VARCHAR(50) NOT NULL UNIQUE,
    department VARCHAR(100) DEFAULT NULL,
    photo_url TEXT DEFAULT NULL,
    role ENUM('admin', 'employee', 'hr') DEFAULT 'employee',
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_employee_id (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- Table: attendances
-- Description: Enregistre les présences des employés
-- ================================================
CREATE TABLE IF NOT EXISTS attendances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    employee_id VARCHAR(50) NOT NULL,
    employee_name VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    confidence DECIMAL(5,2) NOT NULL COMMENT 'Confiance de reconnaissance faciale (0-100)',
    photo_url TEXT DEFAULT NULL,
    location VARCHAR(255) DEFAULT NULL,
    device_info VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_employee_id (employee_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_date (DATE(timestamp))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- Table: unknown_faces
-- Description: Stocke les détections de visages inconnus
-- ================================================
CREATE TABLE IF NOT EXISTS unknown_faces (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    photo_url TEXT NOT NULL,
    confidence DECIMAL(5,2) NOT NULL,
    is_notified TINYINT(1) DEFAULT 0 COMMENT 'HR a été notifié',
    notes TEXT DEFAULT NULL,
    resolved_by INT DEFAULT NULL COMMENT 'ID de l\'admin qui a résolu',
    resolved_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_timestamp (timestamp),
    INDEX idx_is_notified (is_notified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- Table: refresh_tokens
-- Description: Gère les tokens JWT pour la session
-- ================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- Table: notifications
-- Description: Notifications pour les visages inconnus
-- ================================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'Destinataire (HR/Admin)',
    type ENUM('unknown_face', 'system', 'alert') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    reference_id INT DEFAULT NULL COMMENT 'ID de unknown_face ou autre',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- DONNÉES DE TEST
-- ================================================

-- Insérer un utilisateur admin par défaut
-- Mot de passe: admin123 (hashé avec password_hash())
INSERT INTO users (name, email, password, employee_id, department, role) VALUES
('Admin User', 'admin@yolo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'EMP001', 'Administration', 'admin'),
('John Doe', 'john@yolo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'EMP002', 'Engineering', 'employee'),
('HR Manager', 'hr@yolo.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'HR001', 'Human Resources', 'hr');

-- Insérer quelques présences de test
INSERT INTO attendances (user_id, employee_id, employee_name, timestamp, confidence, photo_url) VALUES
(2, 'EMP002', 'John Doe', NOW(), 95.5, 'https://example.com/photos/john_doe_1.jpg'),
(2, 'EMP002', 'John Doe', DATE_SUB(NOW(), INTERVAL 1 DAY), 92.3, 'https://example.com/photos/john_doe_2.jpg');

-- ================================================
-- VUES UTILES
-- ================================================

-- Vue pour les statistiques de présence journalières
CREATE OR REPLACE VIEW daily_attendance_stats AS
SELECT
    DATE(timestamp) as date,
    COUNT(DISTINCT user_id) as unique_employees,
    COUNT(*) as total_check_ins,
    AVG(confidence) as avg_confidence
FROM attendances
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- Vue pour les employés actifs
CREATE OR REPLACE VIEW active_employees AS
SELECT
    id,
    name,
    email,
    employee_id,
    department,
    role,
    created_at
FROM users
WHERE is_active = 1
ORDER BY name;

-- ================================================
-- PROCÉDURES STOCKÉES
-- ================================================

DELIMITER //

-- Procédure pour nettoyer les anciens tokens expirés
CREATE PROCEDURE IF NOT EXISTS clean_expired_tokens()
BEGIN
    DELETE FROM refresh_tokens WHERE expires_at < NOW();
END //

-- Procédure pour obtenir les présences d'un employé
CREATE PROCEDURE IF NOT EXISTS get_employee_attendance(IN emp_id VARCHAR(50), IN days INT)
BEGIN
    SELECT
        id,
        employee_name,
        timestamp,
        confidence,
        photo_url,
        location
    FROM attendances
    WHERE employee_id = emp_id
    AND timestamp >= DATE_SUB(NOW(), INTERVAL days DAY)
    ORDER BY timestamp DESC;
END //

DELIMITER ;

-- ================================================
-- ÉVÉNEMENTS AUTOMATIQUES
-- ================================================

-- Activer l'événement scheduler
SET GLOBAL event_scheduler = ON;

-- Événement pour nettoyer les tokens expirés tous les jours à minuit
CREATE EVENT IF NOT EXISTS clean_tokens_daily
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY)
DO
    CALL clean_expired_tokens();

-- ================================================
-- FIN DU SCRIPT
-- ================================================

-- Afficher les informations de connexion par défaut
SELECT
    '==================================================' as '',
    'BASE DE DONNÉES CRÉÉE AVEC SUCCÈS !' as '',
    '==================================================' as '',
    '' as '',
    'Nom de la base de données: jwtauth' as '',
    '' as '',
    'COMPTES DE TEST:' as '',
    '------------------------------------------------' as '',
    'Admin:' as '',
    '  Email: admin@yolo.com' as '',
    '  Password: admin123' as '',
    '  Employee ID: EMP001' as '',
    '' as '',
    'Employé:' as '',
    '  Email: john@yolo.com' as '',
    '  Password: admin123' as '',
    '  Employee ID: EMP002' as '',
    '' as '',
    'RH:' as '',
    '  Email: hr@yolo.com' as '',
    '  Password: admin123' as '',
    '  Employee ID: HR001' as '',
    '==================================================' as '';
