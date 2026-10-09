<?php
/**
 * Authentication & JWT Token Helper
 * Pure PHP HMAC-SHA256 implementation - No external Composer packages required!
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/response.php';

class AuthHelper {
    private static $secret = JWT_SECRET_KEY;

    /**
     * Generate Base64Url string
     */
    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Decode Base64Url string
     */
    private static function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    /**
     * Generate a signed JWT token
     */
    public static function generateToken($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        
        // Add expiration and issued at
        if (!isset($payload['iat'])) {
            $payload['iat'] = time();
        }
        if (!isset($payload['exp'])) {
            $payload['exp'] = time() + JWT_EXPIRY_SECONDS;
        }

        $base64Header = self::base64UrlEncode($header);
        $base64Payload = self::base64UrlEncode(json_encode($payload));

        $signature = hash_hmac('sha256', "{$base64Header}.{$base64Payload}", self::$secret, true);
        $base64Signature = self::base64UrlEncode($signature);

        return "{$base64Header}.{$base64Payload}.{$base64Signature}";
    }

    /**
     * Verify and decode a JWT token
     */
    public static function verifyToken($token) {
        if (empty($token)) {
            return null;
        }

        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        list($base64Header, $base64Payload, $base64Signature) = $parts;

        // Verify signature
        $expectedSignature = self::base64UrlEncode(
            hash_hmac('sha256', "{$base64Header}.{$base64Payload}", self::$secret, true)
        );

        if (!hash_equals($expectedSignature, $base64Signature)) {
            return null;
        }

        // Decode payload
        $payload = json_decode(self::base64UrlDecode($base64Payload), true);
        if (!$payload) {
            return null;
        }

        // Check expiration
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return null;
        }

        return $payload;
    }

    /**
     * Extract Bearer token from HTTP headers
     */
    public static function getBearerToken() {
        $headers = null;
        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER['Authorization']);
        } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            if (isset($requestHeaders['Authorization'])) {
                $headers = trim($requestHeaders['Authorization']);
            }
        }

        if (!empty($headers)) {
            if (preg_match('/Bearer\s(\S+)/i', $headers, $matches)) {
                return $matches[1];
            }
        }

        // Fallback check in query parameter
        if (!empty($_GET['token'])) {
            return trim($_GET['token']);
        }

        return null;
    }

    /**
     * Guard endpoint: requires authenticated user with optional role check
     * @param array $allowedRoles e.g. ['customer', 'rider', 'admin']
     * @return array decoded payload
     */
    public static function requireAuth($allowedRoles = []) {
        $token = self::getBearerToken();
        if (!$token) {
            sendError('Authentication required. Missing Bearer token.', 401);
        }

        $payload = self::verifyToken($token);
        if (!$payload) {
            sendError('Invalid or expired token. Please log in again.', 401);
        }

        if (!empty($allowedRoles)) {
            $role = isset($payload['role']) ? $payload['role'] : 'customer';
            if (!in_array($role, $allowedRoles)) {
                sendError('Access forbidden. Insufficient permissions.', 403);
            }
        }

        return $payload;
    }
}
