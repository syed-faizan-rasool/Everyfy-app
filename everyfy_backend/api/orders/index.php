<?php
/**
 * Customer Orders List
 * GET /api/orders/index.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$userId = 1; // Demo fallback
$token = AuthHelper::getBearerToken();
if ($token) {
    $payload = AuthHelper::verifyToken($token);
    if ($payload && isset($payload['sub'])) {
        $userId = (int)$payload['sub'];
    }
}

try {
    // Get orders for this user
    $stmt = $pdo->prepare("SELECT o.*, d.name as rider_name, d.phone as rider_phone, d.vehicle_number as rider_vehicle
                           FROM orders o
                           LEFT JOIN delivery_boys d ON d.id = o.delivery_boy_id
                           WHERE o.user_id = ?
                           ORDER BY o.id DESC");
    $stmt->execute([$userId]);
    $orders = $stmt->fetchAll();

    // Fetch items for each order
    $itemStmt = $pdo->prepare("SELECT product_id, product_name, product_price, quantity, subtotal FROM order_items WHERE order_id = ?");

    $result = [];
    foreach ($orders as $o) {
        $itemStmt->execute([$o['id']]);
        $items = $itemStmt->fetchAll();

        $result[] = [
            'id'             => (int)$o['id'],
            'order_number'   => $o['order_number'],
            'order_type'     => $o['order_type'],
            'status'         => $o['order_status'],
            'subtotal'       => (float)$o['subtotal'],
            'delivery_fee'   => (float)$o['delivery_fee'],
            'discount'       => (float)$o['discount'],
            'total'          => (float)$o['total_amount'],
            'payment_method' => $o['payment_method'],
            'payment_status' => $o['payment_status'],
            'address_text'   => $o['address_text'],
            'notes'          => $o['notes'] ?? '',
            'rider'          => $o['rider_name'] ? [
                'name'    => $o['rider_name'],
                'phone'   => $o['rider_phone'],
                'vehicle' => $o['rider_vehicle']
            ] : null,
            'items_count'    => count($items),
            'items'          => array_map(function($i) {
                return [
                    'product_id' => (int)$i['product_id'],
                    'name'       => $i['product_name'],
                    'price'      => (float)$i['product_price'],
                    'quantity'   => (int)$i['quantity'],
                    'subtotal'   => (float)$i['subtotal']
                ];
            }, $items),
            'created_at'     => $o['created_at']
        ];
    }

    sendSuccess($result, 'Orders retrieved successfully');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
