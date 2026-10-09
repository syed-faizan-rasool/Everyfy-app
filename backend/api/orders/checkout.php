<?php
/**
 * Checkout / Place Grocery Order
 * POST /api/orders/checkout.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

// User context
$userId = 1; // Fallback demo customer
$userName = 'Customer';
$userPhone = '03001234567';

$token = AuthHelper::getBearerToken();
if ($token) {
    $payload = AuthHelper::verifyToken($token);
    if ($payload) {
        $userId = (int)($payload['sub'] ?? 1);
        $userName = $payload['name'] ?? 'Customer';
        $userPhone = $payload['phone'] ?? '03001234567';
    }
}

$data = getRequestData();
$items          = isset($data['items']) && is_array($data['items']) ? $data['items'] : [];
$subtotal       = isset($data['subtotal']) ? (float)$data['subtotal'] : 0.0;
$deliveryFee    = isset($data['delivery_fee']) ? (float)$data['delivery_fee'] : 0.0;
$discount       = isset($data['discount']) ? (float)$data['discount'] : 0.0;
$totalAmount    = isset($data['total']) ? (float)$data['total'] : ($subtotal + $deliveryFee - $discount);
$paymentMethod  = isset($data['payment_method']) ? strtolower($data['payment_method']) : 'cod';
$orderType      = isset($data['order_type']) ? strtolower($data['order_type']) : 'delivery';
$addressText    = isset($data['address_text']) ? trim($data['address_text']) : 'Store Pickup';
$notes          = isset($data['notes']) ? trim($data['notes']) : '';
$couponCode     = isset($data['coupon_code']) ? trim(strtoupper($data['coupon_code'])) : null;
$customerName   = isset($data['customer_name']) ? trim($data['customer_name']) : $userName;
$customerPhone  = isset($data['customer_phone']) ? trim($data['customer_phone']) : $userPhone;

if (empty($items)) {
    sendError('Cart is empty. Please add items before checking out.', 422);
}

// Ensure total is valid
$totalAmount = max(0.0, $totalAmount);

// Generate unique order number (e.g. ORD-9821 or ORD + timestamp substring)
$orderNumber = 'ORD-' . strtoupper(substr(uniqid(), -6));

try {
    $pdo->beginTransaction();

    // 1. Insert Order
    $sql = "INSERT INTO orders (
                order_number, user_id, customer_name, customer_phone,
                order_type, subtotal, delivery_fee, discount, total_amount,
                payment_method, payment_status, order_status,
                coupon_code, notes, address_text, distance_km, rider_earning
            ) VALUES (
                ?, ?, ?, ?,
                ?, ?, ?, ?, ?,
                ?, 'pending', 'placed',
                ?, ?, ?, 3.5, 120.00
            )";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $orderNumber, $userId, $customerName, $customerPhone,
        $orderType, $subtotal, $deliveryFee, $discount, $totalAmount,
        $paymentMethod,
        $couponCode, $notes, $addressText
    ]);

    $orderId = (int)$pdo->lastInsertId();

    // 2. Insert Order Items & Update Stock
    $itemStmt = $pdo->prepare("INSERT INTO order_items (order_id, product_id, product_name, product_price, quantity, subtotal) VALUES (?, ?, ?, ?, ?, ?)");
    $stockStmt = $pdo->prepare("UPDATE products SET stock_qty = GREATEST(0, stock_qty - ?) WHERE id = ?");

    $insertedItems = [];
    foreach ($items as $item) {
        $productId = (int)($item['product_id'] ?? ($item['product']['id'] ?? 0));
        $name      = $item['name'] ?? ($item['product']['name'] ?? 'Grocery Item');
        $price     = (float)($item['price'] ?? ($item['product']['price'] ?? 0.0));
        $qty       = (int)($item['quantity'] ?? 1);
        $itemTotal = $price * $qty;

        $itemStmt->execute([$orderId, $productId, $name, $price, $qty, $itemTotal]);
        if ($productId > 0) {
            $stockStmt->execute([$qty, $productId]);
        }

        $insertedItems[] = [
            'product_id' => $productId,
            'name'       => $name,
            'price'      => $price,
            'quantity'   => $qty,
            'subtotal'   => $itemTotal
        ];
    }

    // 3. Record Initial Status History
    $historyStmt = $pdo->prepare("INSERT INTO order_status_history (order_id, status, notes, changed_by) VALUES (?, 'placed', 'Order placed by customer', 'customer')");
    $historyStmt->execute([$orderId]);

    // 4. Update coupon usage count if used
    if (!empty($couponCode)) {
        $pdo->prepare("UPDATE coupons SET times_used = times_used + 1 WHERE code = ?")->execute([$couponCode]);
    }

    $pdo->commit();

    sendSuccess([
        'id'             => $orderId,
        'order_number'   => $orderNumber,
        'status'         => 'placed',
        'subtotal'       => $subtotal,
        'delivery_fee'   => $deliveryFee,
        'discount'       => $discount,
        'total'          => $totalAmount,
        'payment_method' => $paymentMethod,
        'address_text'   => $addressText,
        'items'          => $insertedItems,
        'created_at'     => date('Y-m-d H:i:s')
    ], 'Order placed successfully! Thank you for ordering with Everyfy.');

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Failed to place order: ' . $e->getMessage(), 500);
}
