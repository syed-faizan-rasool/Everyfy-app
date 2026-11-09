<?php
/**
 * Delivery Boy Accepts an Order
 * POST /api/delivery/orders/accept.php
 * Body: { order_id: 1 }
 */

require_once __DIR__ . '/../../../config/config.php';
require_once __DIR__ . '/../../../config/db.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/auth.php';

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
$orderId = isset($data['order_id']) ? (int)$data['order_id'] : (isset($data['id']) ? (int)$data['id'] : 0);

if ($orderId <= 0) {
    sendError('Valid order ID is required', 422);
}

try {
    $stmt = $pdo->prepare("SELECT id, order_status, delivery_boy_id FROM orders WHERE id = ? LIMIT 1");
    $stmt->execute([$orderId]);
    $order = $stmt->fetch();

    if (!$order) {
        sendError('Order not found', 404);
    }

    if (!empty($order['delivery_boy_id']) && (int)$order['delivery_boy_id'] !== $riderId) {
        sendError('This order has already been accepted by another rider', 400);
    }

    // Assign order to this rider and update status to ready / on_the_way
    $updateStmt = $pdo->prepare("UPDATE orders SET delivery_boy_id = ?, order_status = 'ready' WHERE id = ?");
    $updateStmt->execute([$riderId, $orderId]);

    // Record status history
    $pdo->prepare("INSERT INTO order_status_history (order_id, status, notes, changed_by) VALUES (?, 'ready', 'Accepted by rider', 'rider')")
        ->execute([$orderId]);

    sendSuccess([
        'order_id' => $orderId,
        'status'   => 'ready',
        'rider_id' => $riderId
    ], 'Order accepted successfully. Head to the store for pickup.');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
