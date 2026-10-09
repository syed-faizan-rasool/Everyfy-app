<?php
/**
 * Admin Orders Management
 * GET/POST /api/admin/orders.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET') {
        $status = isset($_GET['status']) ? trim($_GET['status']) : '';
        $where = [];
        $params = [];

        if (!empty($status) && $status !== 'all') {
            $where[] = "o.order_status = ?";
            $params[] = $status;
        }

        $whereClause = !empty($where) ? "WHERE " . implode(' AND ', $where) : "";

        $sql = "SELECT o.*, d.name as rider_name, d.phone as rider_phone
                FROM orders o
                LEFT JOIN delivery_boys d ON d.id = o.delivery_boy_id
                {$whereClause}
                ORDER BY o.id DESC LIMIT 100";

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $orders = $stmt->fetchAll();

        // Get items for each order
        $itemStmt = $pdo->prepare("SELECT product_id, product_name, product_price, quantity, subtotal FROM order_items WHERE order_id = ?");

        $result = [];
        foreach ($orders as $o) {
            $itemStmt->execute([$o['id']]);
            $items = $itemStmt->fetchAll();

            $result[] = [
                'id'             => (int)$o['id'],
                'order_number'   => $o['order_number'],
                'customer_name'  => $o['customer_name'] ?: 'Customer',
                'customer_phone' => $o['customer_phone'] ?: '',
                'address'        => $o['address_text'],
                'status'         => $o['order_status'],
                'subtotal'       => (float)$o['subtotal'],
                'delivery_fee'   => (float)$o['delivery_fee'],
                'discount'       => (float)$o['discount'],
                'total'          => (float)$o['total_amount'],
                'payment_method' => $o['payment_method'],
                'payment_status' => $o['payment_status'],
                'notes'          => $o['notes'] ?? '',
                'delivery_boy_id'=> $o['delivery_boy_id'] ? (int)$o['delivery_boy_id'] : null,
                'rider_name'     => $o['rider_name'] ?? null,
                'rider_phone'    => $o['rider_phone'] ?? null,
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

        sendSuccess($result, 'Admin orders retrieved');

    } elseif ($method === 'POST') {
        $data           = getRequestData();
        $orderId        = isset($data['order_id']) ? (int)$data['order_id'] : (isset($data['id']) ? (int)$data['id'] : 0);
        $status         = isset($data['status']) ? trim($data['status']) : null;
        $deliveryBoyId  = isset($data['delivery_boy_id']) ? (int)$data['delivery_boy_id'] : null;
        $notes          = isset($data['notes']) ? trim($data['notes']) : 'Updated by Admin';

        if ($orderId <= 0) {
            sendError('Order ID is required', 422);
        }

        $updates = [];
        $params  = [];

        if ($status !== null) {
            $updates[] = "order_status = ?";
            $params[] = $status;
        }

        if ($deliveryBoyId !== null) {
            $updates[] = "delivery_boy_id = ?";
            $params[] = ($deliveryBoyId > 0) ? $deliveryBoyId : null;
        }

        if (empty($updates)) {
            sendError('Nothing to update', 400);
        }

        $params[] = $orderId;
        $sql = "UPDATE orders SET " . implode(', ', $updates) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($status !== null) {
            $pdo->prepare("INSERT INTO order_status_history (order_id, status, notes, changed_by) VALUES (?, ?, ?, 'admin')")
                ->execute([$orderId, $status, $notes]);
        }

        sendSuccess(['order_id' => $orderId, 'status' => $status], 'Order updated successfully');
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
