<?php
/**
 * Place Custom Grocery Order API
 * POST /api/orders/custom.php
 * Body: { notes: "...", address_text: "...", customer_name: "...", customer_phone: "..." }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';
require_once __DIR__ . '/../../helpers/notification_helper.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

// User context
$userId = 1;
$userName = 'Customer';
$userPhone = '03001234567';

$token = AuthHelper::getBearerToken();
if ($token) {
    $payload = AuthHelper::verifyToken($token);
    if ($payload) {
        $userId    = (int)($payload['sub'] ?? 1);
        $userName  = $payload['name'] ?? 'Customer';
        $userPhone = $payload['phone'] ?? '03001234567';
    }
}

$data          = getRequestData();
$notes         = isset($data['notes']) ? trim($data['notes']) : '';
$addressText   = isset($data['address_text']) && !empty(trim($data['address_text'])) ? trim($data['address_text']) : 'new model town, gojra';
$customerName  = isset($data['customer_name']) && !empty(trim($data['customer_name'])) ? trim($data['customer_name']) : $userName;
$customerPhone = isset($data['customer_phone']) && !empty(trim($data['customer_phone'])) ? trim($data['customer_phone']) : $userPhone;
$deliveryFee   = 120.0;
$totalAmount   = 120.0; // Delivery fee only, actual items will be confirmed at shop

if (empty($notes)) {
    sendError('Please describe what items you would like us to bring.', 422);
}

// Generate unique order number (e.g. ORD-CUST-82194)
$orderNumber = 'CUST-' . strtoupper(substr(uniqid(), -6));

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("
        INSERT INTO orders (
            order_number, user_id, customer_name, customer_phone,
            order_type, subtotal, delivery_fee, discount, total_amount,
            payment_method, payment_status, order_status,
            notes, address_text, distance_km, rider_earning
        ) VALUES (
            ?, ?, ?, ?,
            'custom', 0.00, ?, 0.00, ?,
            'cod', 'pending', 'placed',
            ?, ?, 3.5, 120.00
        )
    ");

    $stmt->execute([
        $orderNumber, $userId, $customerName, $customerPhone,
        $deliveryFee, $totalAmount,
        $notes, $addressText
    ]);

    $orderId = (int)$pdo->lastInsertId();

    // Insert dummy line item for custom order
    $itemStmt = $pdo->prepare("
        INSERT INTO order_items (order_id, product_id, product_name, product_price, quantity, subtotal)
        VALUES (?, 0, ?, 0.00, 1, 0.00)
    ");
    $itemStmt->execute([$orderId, 'Custom Order: ' . (strlen($notes) > 40 ? substr($notes, 0, 37) . '...' : $notes)]);

    $pdo->commit();

    NotificationHelper::create(
        $pdo,
        'customer',
        'Custom Order Received! 🛍️',
        "Your custom request #{$orderNumber} has been received. Our team is procuring your items.",
        $userId,
        $orderId,
        $orderNumber
    );

    NotificationHelper::create(
        $pdo,
        'admin',
        'New Custom Order! 🛒',
        "New Custom Order #{$orderNumber}: \"{$notes}\". Please check availability and assign rider.",
        null,
        $orderId,
        $orderNumber
    );

    sendSuccess([
        'order_id'       => $orderId,
        'order_number'   => $orderNumber,
        'order_status'   => 'placed',
        'subtotal'       => 0.0,
        'delivery_fee'   => $deliveryFee,
        'discount'       => 0.0,
        'total'          => $totalAmount,
        'payment_method' => 'cod',
        'address_text'   => $addressText,
        'notes'          => $notes,
        'created_at'     => date('Y-m-d H:i:s'),
        'items'          => [
            [
                'product_id'   => 0,
                'name'         => 'Custom Grocery Order',
                'price'        => 0.0,
                'quantity'     => 1,
                'instructions' => $notes,
                'product'      => [
                    'id'    => 0,
                    'name'  => 'Custom Grocery Order',
                    'price' => 0.0,
                    'image' => 'assets/images/app_logo.png'
                ]
            ]
        ]
    ], 'Custom order placed successfully!', 201);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    sendError('Failed to place custom order: ' . $e->getMessage(), 500);
}

