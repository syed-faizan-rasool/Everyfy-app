<?php
/**
 * Delivery Boy Completed Deliveries History
 * GET /api/delivery/orders/history.php
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

try {
    $stmt = $pdo->prepare("SELECT * FROM orders WHERE delivery_boy_id = ? AND order_status = 'delivered' ORDER BY id DESC LIMIT 50");
    $stmt->execute([$riderId]);
    $orders = $stmt->fetchAll();

    $itemStmt = $pdo->prepare("SELECT product_id, product_name, product_price, quantity, subtotal FROM order_items WHERE order_id = ?");

    $result = [];
    foreach ($orders as $o) {
        $itemStmt->execute([$o['id']]);
        $items = $itemStmt->fetchAll();

        $result[] = [
            'id'             => (string)$o['id'],
            'order_number'   => $o['order_number'],
            'customer_name'  => $o['customer_name'] ?: 'Customer',
            'customer_phone' => $o['customer_phone'] ?: '',
            'address'        => $o['address_text'],
            'store_address'  => 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
            'items'          => array_map(function($i) {
                return [
                    'product' => [
                        'id'    => (int)$i['product_id'],
                        'name'  => $i['product_name'],
                        'price' => (float)$i['product_price'],
                    ],
                    'quantity' => (int)$i['quantity']
                ];
            }, $items),
            'subtotal'       => (float)$o['subtotal'],
            'delivery_fee'   => (float)$o['delivery_fee'],
            'total'          => (float)$o['total_amount'],
            'payment_method' => $o['payment_method'],
            'distance_km'    => (float)($o['distance_km'] ?? 3.0),
            'earning'        => (float)($o['rider_earning'] ?? 120.00),
            'status'         => 'delivered',
            'is_available'   => false,
            'notes'          => $o['notes'] ?? '',
            'created_at'     => $o['created_at'],
            'delivered_at'   => $o['updated_at']
        ];
    }

    sendSuccess($result, 'Completed deliveries fetched successfully');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
