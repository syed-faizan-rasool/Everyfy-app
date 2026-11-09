<?php
/**
 * Available Orders Ready for Rider Pickup
 * GET /api/delivery/orders/available.php
 */

require_once __DIR__ . '/../../../config/config.php';
require_once __DIR__ . '/../../../config/db.php';
require_once __DIR__ . '/../../../helpers/response.php';
require_once __DIR__ . '/../../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

try {
    $riderId = 1;
    $token = AuthHelper::getBearerToken();
    if ($token) {
        $payload = AuthHelper::verifyToken($token);
        if ($payload && isset($payload['sub'])) {
            $riderId = (int)$payload['sub'];
        }
    }
    if (isset($_GET['rider_id']) && is_numeric($_GET['rider_id'])) {
        $riderId = (int)$_GET['rider_id'];
    }

    // Orders that are either assigned to this rider OR available in store pipeline
    $sql = "SELECT o.*
            FROM orders o
            WHERE ((o.delivery_boy_id = ?) AND o.order_status NOT IN ('delivered', 'cancelled'))
               OR ((o.delivery_boy_id IS NULL OR o.delivery_boy_id = 0) AND o.order_status IN ('placed', 'confirmed', 'preparing', 'ready'))
            ORDER BY
                CASE WHEN o.delivery_boy_id = ? THEN 0 ELSE 1 END,
                o.id DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$riderId, $riderId]);
    $orders = $stmt->fetchAll();

    $itemStmt = $pdo->prepare("SELECT product_id, product_name, product_price, quantity, subtotal FROM order_items WHERE order_id = ?");

    $result = [];
    foreach ($orders as $o) {
        $itemStmt->execute([$o['id']]);
        $items = $itemStmt->fetchAll();

        $isAssigned = ((int)$o['delivery_boy_id'] === $riderId);

        $result[] = [
            'id'             => (string)$o['id'],
            'order_number'   => $o['order_number'],
            'customer_name'  => $o['customer_name'] ?: 'Customer',
            'customer_phone' => $o['customer_phone'] ?: '03001234567',
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
            'distance_km'    => (float)($o['distance_km'] ?? 3.2),
            'earning'        => (float)($o['rider_earning'] ?? 120.00),
            'status'         => $o['order_status'],
            'is_available'   => empty($o['delivery_boy_id']),
            'is_assigned'    => $isAssigned,
            'notes'          => $o['notes'] ?: 'Deliver with care',
            'created_at'     => $o['created_at']
        ];
    }

    sendSuccess($result, 'Available delivery orders retrieved');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
