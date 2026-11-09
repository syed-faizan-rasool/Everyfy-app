<?php
/**
 * Available Orders Ready for Rider Pickup
 * GET /api/delivery/orders/available.php
 */

require_once __DIR__ . '/../../../config/config.php';
require_once __DIR__ . '/../../../config/db.php';
require_once __DIR__ . '/../../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

try {
    // Orders that are confirmed or preparing or ready, but have no delivery boy assigned yet
    $sql = "SELECT o.*
            FROM orders o
            WHERE (o.delivery_boy_id IS NULL OR o.delivery_boy_id = 0)
              AND o.order_status IN ('confirmed', 'preparing', 'ready')
              AND o.order_type = 'delivery'
            ORDER BY o.id DESC";

    $stmt = $pdo->query($sql);
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
            'is_available'   => true,
            'notes'          => $o['notes'] ?: 'Deliver with care',
            'created_at'     => $o['created_at']
        ];
    }

    sendSuccess($result, 'Available delivery orders retrieved');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
