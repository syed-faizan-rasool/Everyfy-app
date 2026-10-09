<?php
/**
 * Customer Order Cancellation
 * POST /api/orders/cancel.php
 * Body: { order_id: 1, reason: "Placed by mistake" }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$data = getRequestData();
$orderId = isset($data['order_id']) ? (int)$data['order_id'] : (isset($data['id']) ? (int)$data['id'] : 0);
$reason  = isset($data['reason']) ? trim($data['reason']) : 'Customer requested cancellation';

if ($orderId <= 0) {
    sendError('Valid order ID is required', 422);
}

try {
    $stmt = $pdo->prepare("SELECT id, order_status FROM orders WHERE id = ? LIMIT 1");
    $stmt->execute([$orderId]);
    $order = $stmt->fetch();

    if (!$order) {
        sendError('Order not found', 404);
    }

    if (in_array($order['order_status'], ['delivered', 'cancelled', 'on_the_way'])) {
        sendError("Order cannot be cancelled at this stage ({$order['order_status']})", 400);
    }

    // Update status to cancelled
    $pdo->prepare("UPDATE orders SET order_status = 'cancelled' WHERE id = ?")->execute([$orderId]);

    // Record in history
    $pdo->prepare("INSERT INTO order_status_history (order_id, status, notes, changed_by) VALUES (?, 'cancelled', ?, 'customer')")
        ->execute([$orderId, $reason]);

    sendSuccess(['id' => $orderId, 'status' => 'cancelled'], 'Order cancelled successfully');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
