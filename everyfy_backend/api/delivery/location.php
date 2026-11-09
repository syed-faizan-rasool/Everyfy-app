<?php
/**
 * Update Rider Live GPS Location
 * POST /api/delivery/location.php
 * Body: { latitude: 31.5204, longitude: 74.3587 }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$riderId = 1;
$token = AuthHelper::getBearerToken();
if ($token) {
    $payload = AuthHelper::verifyToken($token);
    if ($payload && isset($payload['sub'])) {
        $riderId = (int)$payload['sub'];
    }
}

$data = getRequestData();
$lat  = isset($data['latitude']) ? (float)$data['latitude'] : (isset($data['lat']) ? (float)$data['lat'] : null);
$lng  = isset($data['longitude']) ? (float)$data['longitude'] : (isset($data['lng']) ? (float)$data['lng'] : null);

if ($lat === null || $lng === null) {
    sendError('Latitude and Longitude are required', 422);
}

try {
    $stmt = $pdo->prepare("UPDATE delivery_boys SET current_lat = ?, current_lng = ? WHERE id = ?");
    $stmt->execute([$lat, $lng, $riderId]);

    sendSuccess([
        'rider_id'  => $riderId,
        'latitude'  => $lat,
        'longitude' => $lng,
        'timestamp' => date('Y-m-d H:i:s')
    ], 'Rider location updated');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
