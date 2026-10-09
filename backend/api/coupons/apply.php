<?php
/**
 * Validate and Apply Coupon
 * POST /api/coupons/apply.php
 * Body: { code: "FRESH20", subtotal: 600.00 }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$data     = getRequestData();
$code     = isset($data['code']) ? trim(strtoupper($data['code'])) : '';
$subtotal = isset($data['subtotal']) ? (float)$data['subtotal'] : 0.0;

if (empty($code)) {
    sendError('Please enter a coupon code', 422);
}

try {
    $stmt = $pdo->prepare("SELECT * FROM coupons WHERE code = ? AND is_active = 1 LIMIT 1");
    $stmt->execute([$code]);
    $coupon = $stmt->fetch();

    if (!$coupon) {
        sendError('Invalid promo code. Try FRESH20', 404);
    }

    // Check expiry
    if (!empty($coupon['expiry_date']) && strtotime($coupon['expiry_date']) < strtotime(date('Y-m-d'))) {
        sendError('This coupon has expired', 400);
    }

    // Check minimum order amount
    $minAmount = (float)$coupon['min_order_amount'];
    if ($subtotal < $minAmount) {
        sendError("This coupon requires a minimum cart total of Rs {$minAmount}", 400);
    }

    // Calculate discount amount
    $discount = 0.0;
    if ($coupon['discount_type'] === 'percent') {
        $discount = round(($subtotal * (float)$coupon['value']) / 100, 2);
    } else {
        $discount = (float)$coupon['value'];
    }

    // Discount cannot exceed subtotal
    if ($discount > $subtotal) {
        $discount = $subtotal;
    }

    sendSuccess([
        'code'          => $coupon['code'],
        'discount_type' => $coupon['discount_type'],
        'value'         => (float)$coupon['value'],
        'discount'      => $discount,
        'new_total'     => max(0.0, $subtotal - $discount)
    ], "🎉 Coupon {$coupon['code']} applied successfully! Rs {$discount} discount deducted.");
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
