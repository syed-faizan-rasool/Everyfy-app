<?php
/**
 * Single Order Detail & Tracking
 * GET /api/orders/detail.php?id=1 or ?order_number=ORD-9821
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$orderNumber = isset($_GET['order_number']) ? trim($_GET['order_number']) : '';

if ($id <= 0 && empty($orderNumber)) {
    sendError('Order ID or Order Number is required', 422);
}

try {
    if ($id > 0) {
        $stmt = $pdo->prepare("SELECT o.*, d.name as rider_name, d.phone as rider_phone, d.vehicle_type as rider_vehicle_type, d.vehicle_number as rider_vehicle_number, d.rating as rider_rating, d.current_lat, d.current_lng
                               FROM orders o
                               LEFT JOIN delivery_boys d ON d.id = o.delivery_boy_id
                               WHERE o.id = ? LIMIT 1");
        $stmt->execute([$id]);
    } else {
        $stmt = $pdo->prepare("SELECT o.*, d.name as rider_name, d.phone as rider_phone, d.vehicle_type as rider_vehicle_type, d.vehicle_number as rider_vehicle_number, d.rating as rider_rating, d.current_lat, d.current_lng
                               FROM orders o
                               LEFT JOIN delivery_boys d ON d.id = o.delivery_boy_id
                               WHERE o.order_number = ? LIMIT 1");
        $stmt->execute([$orderNumber]);
    }

    $o = $stmt->fetch();
    if (!$o) {
        sendError('Order not found', 404);
    }

    $orderId = (int)$o['id'];

    // Items
    $itemStmt = $pdo->prepare("SELECT product_id, product_name, product_price, quantity, subtotal FROM order_items WHERE order_id = ?");
    $itemStmt->execute([$orderId]);
    $items = $itemStmt->fetchAll();

    // Timeline History
    $historyStmt = $pdo->prepare("SELECT status, notes, changed_by, changed_at FROM order_status_history WHERE order_id = ? ORDER BY id ASC");
    $historyStmt->execute([$orderId]);
    $history = $historyStmt->fetchAll();

    sendSuccess([
        'id'             => $orderId,
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
        'distance_km'    => (float)($o['distance_km'] ?? 3.5),
        'rider'          => $o['rider_name'] ? [
            'name'           => $o['rider_name'],
            'phone'          => $o['rider_phone'],
            'vehicle'        => $o['rider_vehicle_type'] . ' · ' . $o['rider_vehicle_number'],
            'rating'         => (float)$o['rider_rating'],
            'current_lat'    => (float)$o['current_lat'],
            'current_lng'    => (float)$o['current_lng']
        ] : null,
        'items'          => array_map(function($i) {
            return [
                'product_id' => (int)$i['product_id'],
                'name'       => $i['product_name'],
                'price'      => (float)$i['product_price'],
                'quantity'   => (int)$i['quantity'],
                'subtotal'   => (float)$i['subtotal']
            ];
        }, $items),
        'timeline'       => $history,
        'created_at'     => $o['created_at']
    ], 'Order details retrieved');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
