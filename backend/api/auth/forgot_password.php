<?php
/**
 * Request Password Reset OTP
 * POST /api/auth/forgot_password.php
 * Body: { identifier: "email or phone" }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$data = getRequestData();
$identifier = isset($data['identifier']) ? trim($data['identifier']) : (isset($data['email']) ? trim($data['email']) : (isset($data['phone']) ? trim($data['phone']) : ''));

if (empty($identifier)) {
    sendError('Please provide your registered email or phone number', 422);
}

$isEmail    = filter_var($identifier, FILTER_VALIDATE_EMAIL) || str_contains($identifier, '@');
$cleanPhone = preg_replace('/[^0-9]/', '', $identifier);

// Generate 4-digit OTP
$otp = (string)rand(1000, 9999);
$expiresAt = date('Y-m-d H:i:s', time() + 900); // Valid for 15 minutes

try {
    $foundUser = false;
    $targetRole = 'customer';

    // 1. Check in users (Customers)
    if (Database::hasColumn($pdo, 'users', 'email') && $isEmail) {
        $stmt = $pdo->prepare("SELECT id, name, email FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
        $stmt->execute([$identifier]);
    } else {
        $stmt = $pdo->prepare("SELECT id, name, phone FROM users WHERE phone = ? LIMIT 1");
        $stmt->execute([$cleanPhone]);
    }
    $user = $stmt->fetch();

    if ($user) {
        $foundUser = true;
        $targetRole = 'customer';
        $update = $pdo->prepare("UPDATE users SET otp = ?, otp_expires_at = ? WHERE id = ?");
        $update->execute([$otp, $expiresAt, $user['id']]);
    }

    // 2. If not found in users, check delivery_boys
    if (!$foundUser) {
        if (Database::hasColumn($pdo, 'delivery_boys', 'email') && $isEmail) {
            $stmt = $pdo->prepare("SELECT id, name, email FROM delivery_boys WHERE LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$identifier]);
        } else {
            $stmt = $pdo->prepare("SELECT id, name, phone FROM delivery_boys WHERE phone = ? LIMIT 1");
            $stmt->execute([$cleanPhone]);
        }
        $rider = $stmt->fetch();

        if ($rider) {
            $foundUser = true;
            $targetRole = 'rider';
            // Ensure delivery_boys has otp column
            if (!Database::hasColumn($pdo, 'delivery_boys', 'otp')) {
                $pdo->exec("ALTER TABLE delivery_boys ADD COLUMN otp VARCHAR(6) NULL, ADD COLUMN otp_expires_at DATETIME NULL");
            }
            $update = $pdo->prepare("UPDATE delivery_boys SET otp = ?, otp_expires_at = ? WHERE id = ?");
            $update->execute([$otp, $expiresAt, $rider['id']]);
        }
    }

    // 3. If not found, check admins
    if (!$foundUser && $isEmail) {
        $stmt = $pdo->prepare("SELECT id, name, email FROM admins WHERE LOWER(email) = LOWER(?) LIMIT 1");
        $stmt->execute([$identifier]);
        $admin = $stmt->fetch();

        if ($admin) {
            $foundUser = true;
            $targetRole = 'admin';
            if (!Database::hasColumn($pdo, 'admins', 'otp')) {
                $pdo->exec("ALTER TABLE admins ADD COLUMN otp VARCHAR(6) NULL, ADD COLUMN otp_expires_at DATETIME NULL");
            }
            $update = $pdo->prepare("UPDATE admins SET otp = ?, otp_expires_at = ? WHERE id = ?");
            $update->execute([$otp, $expiresAt, $admin['id']]);
        }
    }

    if (!$foundUser) {
        sendError('No account found with this email or phone number. Please check and try again.', 404);
    }

    sendSuccess([
        'identifier' => $identifier,
        'role'       => $targetRole,
        'otp'        => $otp, // Included for instant real-time verification in demo/testing
        'expires_in' => '15 minutes',
        'message'    => "Verification code sent to $identifier. Your OTP is: $otp"
    ], 'Verification code dispatched successfully');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}

