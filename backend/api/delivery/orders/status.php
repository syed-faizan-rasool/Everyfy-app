<?php
/**
 * Delivery Boy Updates Order Status
 * POST /api/delivery/orders/status.php
 * Body: { order_id: 1, status: "picked_up|on_the_way|delivered", notes: "Delivered to customer" }
 */

require_once __DIR__ . '/../../../config/config.php';
require_once __DIR__ . '/../../../config/db.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/auth.php';
require_once __DIR__ . '/../../../helpers/notification_helper.php';

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

$data     = getRequestData();
$orderId  = isset($data['order_id']) ? (int)$data['order_id'] : (isset($data['id']) ? (int)$data['id'] : 0);
$rawStatus = isset($data['status']) ? trim($data['status']) : '';
$notes    = isset($data['notes']) ? trim($data['notes']) : '';

$statusMap = [
    'ontheway'   => 'on_the_way',
    'on_the_way' => 'on_the_way',
    'pickedup'   => 'picked_up',
    'picked_up'  => 'picked_up',
    'ready'      => 'ready',
    'preparing'  => 'preparing',
    'delivered'  => 'delivered',
    'cancelled'  => 'cancelled',
];
$cleanKey = strtolower(str_replace(['-', ' ', '_'], '', $rawStatus));
$status = $statusMap[$cleanKey] ?? $rawStatus;

$validStatuses = ['placed', 'confirmed', 'preparing', 'ready', 'picked_up', 'on_the_way', 'delivered', 'cancelled'];

if ($orderId <= 0 || !in_array($status, $validStatuses)) {
    sendError('Valid order ID and valid status are required', 422);
}

try {
    $stmt = $pdo->prepare("SELECT id, order_status, total_amount, rider_earning FROM orders WHERE id = ? LIMIT 1");
    $stmt->execute([$orderId]);
    $order = $stmt->fetch();

    if (!$order) {
        sendError('Order not found', 404);
    }

    $updateSql = "UPDATE orders SET order_status = ?";
    $params = [$status];

    // If delivered, mark payment_status = paid (if COD) and update rider stats
    if ($status === 'delivered') {
        $updateSql .= ", payment_status = 'paid'";
    }

    $updateSql .= " WHERE id = ?";
    $params[] = $orderId;

    $pdo->prepare($updateSql)->execute($params);

    // If delivered, increment rider total deliveries
    if ($status === 'delivered') {
        $pdo->prepare("UPDATE delivery_boys SET total_deliveries = total_deliveries + 1 WHERE id = ?")->execute([$riderId]);
    }

    // Insert into status timeline
    $historyStmt = $pdo->prepare("INSERT INTO order_status_history (order_id, status, notes, changed_by) VALUES (?, ?, ?, 'rider')");
    $historyStmt->execute([$orderId, $status, $notes ?: "Rider changed status to {$status}"]);

    // Fetch order number and user_id for notification
    $ordStmt = $pdo->prepare("SELECT order_number, user_id FROM orders WHERE id = ?");
    $ordStmt->execute([$orderId]);
    $oData = $ordStmt->fetch();
    $orderNumber = $oData['order_number'] ?? "ORD-$orderId";
    $custUserId = $oData['user_id'] ? (int)$oData['user_id'] : null;

    if ($status === 'picked_up') {
        NotificationHelper::create(
            $pdo,
            'customer',
            'Order Picked Up! 🛵',
            "Rider has picked up your order #{$orderNumber} and is on the way.",
            $custUserId,
            $orderId,
            $orderNumber
        );
        NotificationHelper::create(
            $pdo,
            'admin',
            'Order Picked Up 🛵',
            "Order #{$orderNumber} has been picked up by the delivery rider.",
            null,
            $orderId,
            $orderNumber
        );
    } elseif ($status === 'on_the_way') {
        NotificationHelper::create(
            $pdo,
            'customer',
            'Out For Delivery! ⚡',
            "Your order #{$orderNumber} is arriving soon! Delivery time: 10-15 mins.",
            $custUserId,
            $orderId,
            $orderNumber
        );
    } elseif ($status === 'delivered') {
        NotificationHelper::create(
            $pdo,
            'customer',
            'Order Delivered! 🎊',
            "Your order #{$orderNumber} has been delivered successfully. Thank you for shopping with Everyfy!",
            $custUserId,
            $orderId,
            $orderNumber
        );
        NotificationHelper::create(
            $pdo,
            'admin',
            'Order Delivered ✅',
            "Order #{$orderNumber} has been completed and delivered by the rider.",
            null,
            $orderId,
            $orderNumber
        );
    }

    sendSuccess([
        'order_id' => $orderId,
        'status'   => $status,
        'message'  => "Order status updated to {$status}"
    ], 'Status updated successfully');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
