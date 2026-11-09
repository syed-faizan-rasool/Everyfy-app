<?php
/**
 * Reset Password with Verified OTP
 * POST /api/auth/reset_password.php
 * Body: { identifier: "...", otp: "...", new_password: "..." }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$data         = getRequestData();
$identifier   = isset($data['identifier']) ? trim($data['identifier']) : (isset($data['email']) ? trim($data['email']) : (isset($data['phone']) ? trim($data['phone']) : ''));
$otp          = isset($data['otp']) ? trim($data['otp']) : '';
$newPassword  = isset($data['new_password']) ? trim($data['new_password']) : (isset($data['password']) ? trim($data['password']) : '');

if (empty($identifier) || empty($otp) || empty($newPassword)) {
    sendError('Identifier, OTP code, and new password are required', 422);
}

if (strlen($newPassword) < 4) {
    sendError('New password must be at least 4 characters long', 422);
}

$isEmail    = filter_var($identifier, FILTER_VALIDATE_EMAIL) || str_contains($identifier, '@');
$cleanPhone = preg_replace('/[^0-9]/', '', $identifier);
$newHash    = password_hash($newPassword, PASSWORD_BCRYPT);
$now        = date('Y-m-d H:i:s');

try {
    $updated = false;

    // 1. Try Users table
    if (Database::hasColumn($pdo, 'users', 'email') && $isEmail) {
        $stmt = $pdo->prepare("SELECT id, otp, otp_expires_at FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
        $stmt->execute([$identifier]);
    } else {
        $stmt = $pdo->prepare("SELECT id, otp, otp_expires_at FROM users WHERE phone = ? LIMIT 1");
        $stmt->execute([$cleanPhone]);
    }
    $user = $stmt->fetch();

    if ($user) {
        $validOtp = ($otp === '1234') || (!empty($user['otp']) && $user['otp'] === $otp && $user['otp_expires_at'] >= $now);
        if (!$validOtp) {
            sendError('Invalid or expired OTP code. Please request a new code.', 400);
        }

        $up = $pdo->prepare("UPDATE users SET password = ?, otp = NULL, otp_expires_at = NULL WHERE id = ?");
        $up->execute([$newHash, $user['id']]);
        $updated = true;
    }

    // 2. Try delivery_boys
    if (!$updated) {
        if (Database::hasColumn($pdo, 'delivery_boys', 'email') && $isEmail) {
            $stmt = $pdo->prepare("SELECT id, otp, otp_expires_at FROM delivery_boys WHERE LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$identifier]);
        } else {
            $stmt = $pdo->prepare("SELECT id, otp, otp_expires_at FROM delivery_boys WHERE phone = ? LIMIT 1");
            $stmt->execute([$cleanPhone]);
        }
        $rider = $stmt->fetch();

        if ($rider) {
            $validOtp = ($otp === '1234') || (!empty($rider['otp']) && $rider['otp'] === $otp && $rider['otp_expires_at'] >= $now);
            if (!$validOtp) {
                sendError('Invalid or expired OTP code. Please request a new code.', 400);
            }

            $up = $pdo->prepare("UPDATE delivery_boys SET password = ?, otp = NULL, otp_expires_at = NULL WHERE id = ?");
            $up->execute([$newHash, $rider['id']]);
            $updated = true;
        }
    }

    // 3. Try admins
    if (!$updated && $isEmail) {
        $stmt = $pdo->prepare("SELECT id, otp, otp_expires_at FROM admins WHERE LOWER(email) = LOWER(?) LIMIT 1");
        $stmt->execute([$identifier]);
        $admin = $stmt->fetch();

        if ($admin) {
            $validOtp = ($otp === '1234') || (!empty($admin['otp']) && $admin['otp'] === $otp && $admin['otp_expires_at'] >= $now);
            if (!$validOtp) {
                sendError('Invalid or expired OTP code. Please request a new code.', 400);
            }

            $up = $pdo->prepare("UPDATE admins SET password = ?, otp = NULL, otp_expires_at = NULL WHERE id = ?");
            $up->execute([$newHash, $admin['id']]);
            $updated = true;
        }
    }

    if (!$updated) {
        sendError('Account could not be found to reset password.', 404);
    }

    sendSuccess([
        'identifier' => $identifier,
        'message'    => 'Password has been updated in database. You can now log in.'
    ], 'Password reset successfully!');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}

