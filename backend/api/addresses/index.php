<?php
/**
 * Customer Addresses Management
 * GET/POST/PUT/DELETE /api/addresses/index.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

// Check authorization (allow demo fallback if token not yet saved)
$userId = 1; // Default demo customer fallback
$token = AuthHelper::getBearerToken();
if ($token) {
    $payload = AuthHelper::verifyToken($token);
    if ($payload && isset($payload['sub'])) {
        $userId = (int)$payload['sub'];
    }
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET') {
        $stmt = $pdo->prepare("SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC, id DESC");
        $stmt->execute([$userId]);
        $addresses = $stmt->fetchAll();

        $formatted = array_map(function($a) {
            return [
                'id'           => (int)$a['id'],
                'user_id'      => (int)$a['user_id'],
                'label'        => $a['label'] ?: 'Home',
                'address_line' => $a['address_line'],
                'area'         => $a['area'],
                'city'         => $a['city'] ?: 'Lahore',
                'latitude'     => $a['latitude'] ? (float)$a['latitude'] : null,
                'longitude'    => $a['longitude'] ? (float)$a['longitude'] : null,
                'is_default'   => (bool)$a['is_default']
            ];
        }, $addresses);

        sendSuccess($formatted, 'Addresses retrieved');

    } elseif ($method === 'POST') {
        $data = getRequestData();
        $label        = isset($data['label']) ? trim($data['label']) : 'Home';
        $addressLine  = isset($data['address_line']) ? trim($data['address_line']) : '';
        $area         = isset($data['area']) ? trim($data['area']) : '';
        $city         = isset($data['city']) ? trim($data['city']) : 'Lahore';
        $isDefault    = !empty($data['is_default']) ? 1 : 0;
        $lat          = isset($data['latitude']) ? (float)$data['latitude'] : null;
        $lng          = isset($data['longitude']) ? (float)$data['longitude'] : null;

        if (empty($addressLine) || empty($area)) {
            sendError('Street address and area are required', 422);
        }

        if ($isDefault) {
            $pdo->prepare("UPDATE addresses SET is_default = 0 WHERE user_id = ?")->execute([$userId]);
        }

        $stmt = $pdo->prepare("INSERT INTO addresses (user_id, label, address_line, area, city, is_default, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([$userId, $label, $addressLine, $area, $city, $isDefault, $lat, $lng]);
        $newId = (int)$pdo->lastInsertId();

        sendSuccess([
            'id'           => $newId,
            'label'        => $label,
            'address_line' => $addressLine,
            'area'         => $area,
            'city'         => $city,
            'is_default'   => (bool)$isDefault
        ], 'Delivery address saved successfully');

    } elseif ($method === 'DELETE') {
        $data = getRequestData();
        $addressId = isset($data['id']) ? (int)$data['id'] : (isset($_GET['id']) ? (int)$_GET['id'] : 0);

        if ($addressId <= 0) {
            sendError('Address ID is required', 422);
        }

        $stmt = $pdo->prepare("DELETE FROM addresses WHERE id = ? AND user_id = ?");
        $stmt->execute([$addressId, $userId]);

        sendSuccess(['id' => $addressId], 'Address deleted successfully');
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
