<?php
/**
 * Delivery Boy Toggle Online / Offline Status
 * POST /api/delivery/toggle_online.php
 * Body: { is_online: 1 or 0 }
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
$isOnline = isset($data['is_online']) ? ($data['is_online'] ? 1 : 0) : null;

try {
    if ($isOnline === null) {
        // Toggle current
        $stmt = $pdo->prepare("UPDATE delivery_boys SET is_online = IF(is_online = 1, 0, 1) WHERE id = ?");
        $stmt->execute([$riderId]);
    } else {
        $stmt = $pdo->prepare("UPDATE delivery_boys SET is_online = ? WHERE id = ?");
        $stmt->execute([$isOnline, $riderId]);
    }

    $curr = $pdo->prepare("SELECT is_online FROM delivery_boys WHERE id = ?");
    $curr->execute([$riderId]);
    $row = $curr->fetch();

    $onlineStatus = (bool)($row['is_online'] ?? 1);
    sendSuccess(['is_online' => $onlineStatus], $onlineStatus ? 'You are now online and ready for orders' : 'You are now offline');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
