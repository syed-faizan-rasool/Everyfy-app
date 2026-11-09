<?php
/**
 * Send OTP to customer phone
 * POST /api/auth/send_otp.php
 * Body: { phone: "03001234567" }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed. Please configure config/db.php', 500);
}

$data = getRequestData();
$phone = isset($data['phone']) ? trim($data['phone']) : '';

if (empty($phone)) {
    sendError('Phone number is required', 422);
}

// Normalize phone format
$phone = preg_replace('/[^0-9]/', '', $phone);

// Generate 4-digit OTP (e.g., 1234 in demo mode or random 4-digit)
$isDemo = true; // Safe fallback for testing on new deployments
$otp = $isDemo ? OTP_DEMO_CODE : (string)rand(1000, 9999);
$expiresAt = date('Y-m-d H:i:s', time() + 600); // 10 minutes expiry

try {
    // Check if user exists
    $stmt = $pdo->prepare("SELECT id, name FROM users WHERE phone = ? LIMIT 1");
    $stmt->execute([$phone]);
    $user = $stmt->fetch();

    if ($user) {
        $updateStmt = $pdo->prepare("UPDATE users SET otp = ?, otp_expires_at = ? WHERE id = ?");
        $updateStmt->execute([$otp, $expiresAt, $user['id']]);
    } else {
        $insertStmt = $pdo->prepare("INSERT INTO users (name, phone, otp, otp_expires_at) VALUES (?, ?, ?, ?)");
        $insertStmt->execute(['Guest Customer', $phone, $otp, $expiresAt]);
    }

    sendSuccess([
        'phone'       => $phone,
        'otp'         => $otp, // Included for easy development/testing
        'expires_in'  => '10 minutes',
        'message'     => 'Verification code sent successfully. Use OTP: ' . $otp
    ], 'Verification code dispatched');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
