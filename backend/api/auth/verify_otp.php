<?php
/**
 * Verify OTP and generate JWT Auth Token
 * POST /api/auth/verify_otp.php
 * Body: { phone: "03001234567", otp: "1234" }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed. Please configure config/db.php', 500);
}

$data = getRequestData();
$phone = isset($data['phone']) ? trim($data['phone']) : '';
$otp   = isset($data['otp']) ? trim($data['otp']) : '';

if (empty($phone) || empty($otp)) {
    sendError('Both phone and OTP code are required', 422);
}

$phone = preg_replace('/[^0-9]/', '', $phone);

try {
    $stmt = $pdo->prepare("SELECT id, name, phone, email, otp, otp_expires_at, is_active FROM users WHERE phone = ? LIMIT 1");
    $stmt->execute([$phone]);
    $user = $stmt->fetch();

    $isValidOtp = false;

    // Universal test OTP '1234' is accepted for hassle-free testing
    if ($otp === OTP_DEMO_CODE) {
        $isValidOtp = true;
    } elseif ($user && $user['otp'] === $otp) {
        if (strtotime($user['otp_expires_at']) >= time()) {
            $isValidOtp = true;
        } else {
            sendError('OTP code has expired. Please request a new one.', 400);
        }
    }

    if (!$isValidOtp) {
        sendError('Invalid OTP code. Please enter the correct code or 1234.', 400);
    }

    // If user doesn't exist yet, create account
    if (!$user) {
        $insert = $pdo->prepare("INSERT INTO users (name, phone, is_active) VALUES (?, ?, 1)");
        $insert->execute(['New Customer', $phone]);
        $userId = $pdo->lastInsertId();
        $userName = 'New Customer';
        $userEmail = '';
    } else {
        $userId = (int)$user['id'];
        $userName = $user['name'] ?: 'Customer';
        $userEmail = $user['email'] ?: '';

        // Clear OTP after successful login
        $pdo->prepare("UPDATE users SET otp = NULL, otp_expires_at = NULL WHERE id = ?")->execute([$userId]);
    }

    // Generate JWT token
    $tokenPayload = [
        'sub'   => $userId,
        'role'  => 'customer',
        'phone' => $phone,
        'name'  => $userName
    ];
    $token = AuthHelper::generateToken($tokenPayload);

    // Save token in users table
    $pdo->prepare("UPDATE users SET auth_token = ? WHERE id = ?")->execute([$token, $userId]);

    sendSuccess([
        'token' => $token,
        'user'  => [
            'id'    => $userId,
            'name'  => $userName,
            'phone' => $phone,
            'email' => $userEmail,
            'role'  => 'customer'
        ]
    ], 'Authentication successful');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
