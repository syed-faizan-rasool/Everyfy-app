<?php
/**
 * Delivery Boy Profile & Earnings Summary
 * GET /api/delivery/profile.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$riderId = 1; // Demo fallback
$token = AuthHelper::getBearerToken();
if ($token) {
    $payload = AuthHelper::verifyToken($token);
    if ($payload && isset($payload['sub'])) {
        $riderId = (int)$payload['sub'];
    }
}

try {
    $stmt = $pdo->prepare("SELECT * FROM delivery_boys WHERE id = ? LIMIT 1");
    $stmt->execute([$riderId]);
    $rider = $stmt->fetch();

    if (!$rider) {
        sendError('Rider not found', 404);
    }

    // Calculate today's earnings and deliveries
    $today = date('Y-m-d');
    $earningsStmt = $pdo->prepare("SELECT COUNT(*) as today_count, COALESCE(SUM(rider_earning), 0) as today_earnings, COALESCE(SUM(distance_km), 0) as today_km
                                  FROM orders
                                  WHERE delivery_boy_id = ? AND order_status = 'delivered' AND DATE(updated_at) = ?");
    $earningsStmt->execute([$riderId, $today]);
    $stats = $earningsStmt->fetch();

    sendSuccess([
        'id'               => (int)$rider['id'],
        'name'             => $rider['name'],
        'phone'            => $rider['phone'],
        'vehicle_type'     => $rider['vehicle_type'],
        'vehicle_number'   => $rider['vehicle_number'],
        'rating'           => (float)$rider['rating'],
        'is_online'        => (bool)$rider['is_online'],
        'total_deliveries' => (int)$rider['total_deliveries'],
        'today_deliveries' => (int)$stats['today_count'],
        'today_earnings'   => (float)$stats['today_earnings'],
        'today_distance_km'=> (float)$stats['today_km']
    ], 'Rider profile retrieved');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
