<?php
/**
 * Verify OTP
 * POST /api/auth/verify_otp.php
 * Body: { identifier: "phone or email", otp: "1234" }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed. Please configure config/db.php', 500);
}

$data       = getRequestData();
$identifier = isset($data['identifier']) ? trim($data['identifier']) : (isset($data['phone']) ? trim($data['phone']) : (isset($data['email']) ? trim($data['email']) : ''));
$otp        = isset($data['otp']) ? trim($data['otp']) : '';

if (empty($identifier) || empty($otp)) {
    sendError('Both email/phone and OTP code are required', 422);
}

$isEmail    = filter_var($identifier, FILTER_VALIDATE_EMAIL) || str_contains($identifier, '@');
$cleanPhone = preg_replace('/[^0-9]/', '', $identifier);

try {
    $user = null;
    if ($isEmail && Database::hasColumn($pdo, 'users', 'email')) {
        $stmt = $pdo->prepare("SELECT id, name, phone, email, otp, otp_expires_at, is_active FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
        $stmt->execute([$identifier]);
        $user = $stmt->fetch();
    } else {
        $stmt = $pdo->prepare("SELECT id, name, phone, email, otp, otp_expires_at, is_active FROM users WHERE phone = ? LIMIT 1");
        $stmt->execute([$cleanPhone]);
        $user = $stmt->fetch();
    }

    $isValidOtp = false;

    // Universal test OTP '1234' is accepted for hassle-free testing
    if ($otp === '1234' || (defined('OTP_DEMO_CODE') && $otp === OTP_DEMO_CODE)) {
        $isValidOtp = true;
    } elseif ($user && $user['otp'] === $otp) {
        if (!empty($user['otp_expires_at']) && strtotime($user['otp_expires_at']) >= time()) {
            $isValidOtp = true;
        } else {
            sendError('OTP code has expired. Please request a new one.', 400);
        }
    }

    if (!$isValidOtp) {
        sendError('Invalid OTP code. Please enter the correct code.', 400);
    }

    $userId = $user ? (int)$user['id'] : 0;
    $token = AuthHelper::generateToken([
        'sub'   => $userId,
        'role'  => 'customer',
        'phone' => $user['phone'] ?? $cleanPhone,
        'email' => $user['email'] ?? ($isEmail ? $identifier : ''),
        'name'  => $user['name'] ?? 'Customer'
    ]);

    sendSuccess([
        'token'      => $token,
        'identifier' => $identifier,
        'verified'   => true,
        'message'    => 'OTP verified successfully'
    ], 'OTP verified successfully');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
