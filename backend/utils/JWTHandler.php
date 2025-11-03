<?php
/**
 * Classe de gestion des tokens JWT
 * Utilise une implémentation simple de JWT sans dépendances externes
 */

class JWTHandler {

    /**
     * Générer un token JWT
     */
    public static function generateToken($userId, $email, $employeeId) {
        $issuedAt = time();
        $expirationTime = $issuedAt + JWT_EXPIRATION_TIME;

        $payload = [
            'iss' => JWT_ISSUER,
            'iat' => $issuedAt,
            'exp' => $expirationTime,
            'userId' => $userId,
            'email' => $email,
            'employeeId' => $employeeId
        ];

        return self::encode($payload);
    }

    /**
     * Valider et décoder un token JWT
     */
    public static function validateToken($token) {
        try {
            $payload = self::decode($token);

            // Vérifier l'expiration
            if (isset($payload->exp) && $payload->exp < time()) {
                return [
                    'valid' => false,
                    'error' => 'Token has expired'
                ];
            }

            // Vérifier l'émetteur
            if (!isset($payload->iss) || $payload->iss !== JWT_ISSUER) {
                return [
                    'valid' => false,
                    'error' => 'Invalid token issuer'
                ];
            }

            return [
                'valid' => true,
                'data' => $payload
            ];

        } catch (Exception $e) {
            return [
                'valid' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Extraire le token du header Authorization
     */
    public static function getBearerToken() {
        $headers = self::getAuthorizationHeader();

        if (!empty($headers)) {
            if (preg_match('/Bearer\s+(.*)$/i', $headers, $matches)) {
                return $matches[1];
            }
        }

        return null;
    }

    /**
     * Obtenir le header Authorization
     */
    public static function getAuthorizationHeader() {
        $headers = null;

        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER['Authorization']);
        } else if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
        } else if (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            $requestHeaders = array_combine(
                array_map('ucwords', array_keys($requestHeaders)),
                array_values($requestHeaders)
            );

            if (isset($requestHeaders['Authorization'])) {
                $headers = trim($requestHeaders['Authorization']);
            }
        }

        return $headers;
    }

    /**
     * Encoder le payload en JWT
     */
    private static function encode($payload) {
        $header = [
            'typ' => 'JWT',
            'alg' => JWT_ALGORITHM
        ];

        $headerEncoded = self::base64UrlEncode(json_encode($header));
        $payloadEncoded = self::base64UrlEncode(json_encode($payload));

        $signature = hash_hmac(
            'sha256',
            $headerEncoded . '.' . $payloadEncoded,
            JWT_SECRET_KEY,
            true
        );
        $signatureEncoded = self::base64UrlEncode($signature);

        return $headerEncoded . '.' . $payloadEncoded . '.' . $signatureEncoded;
    }

    /**
     * Décoder un token JWT
     */
    private static function decode($token) {
        $parts = explode('.', $token);

        if (count($parts) !== 3) {
            throw new Exception('Invalid token format');
        }

        list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;

        // Vérifier la signature
        $signature = hash_hmac(
            'sha256',
            $headerEncoded . '.' . $payloadEncoded,
            JWT_SECRET_KEY,
            true
        );
        $signatureCheck = self::base64UrlEncode($signature);

        if ($signatureEncoded !== $signatureCheck) {
            throw new Exception('Invalid token signature');
        }

        $payload = json_decode(self::base64UrlDecode($payloadEncoded));

        if (!$payload) {
            throw new Exception('Invalid token payload');
        }

        return $payload;
    }

    /**
     * Encoder en Base64 URL-safe
     */
    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Décoder depuis Base64 URL-safe
     */
    private static function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    /**
     * Middleware pour protéger les routes
     */
    public static function requireAuth() {
        $token = self::getBearerToken();

        if (!$token) {
            http_response_code(401);
            echo json_encode([
                'error' => 'Unauthorized',
                'message' => 'No token provided'
            ]);
            exit();
        }

        $validation = self::validateToken($token);

        if (!$validation['valid']) {
            http_response_code(401);
            echo json_encode([
                'error' => 'Unauthorized',
                'message' => $validation['error']
            ]);
            exit();
        }

        return $validation['data'];
    }
}
