<?php
/**
 * Admin Login API
 * POST /api/admin/login.php
 * Body: { email: "admin@everyfy.net", password: "..." }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$data     = getRequestData();
$email    = isset($data['email']) ? trim($data['email']) : (isset($data['identifier']) ? trim($data['identifier']) : '');
$password = isset($data['password']) ? trim($data['password']) : '';

if (empty($email) || empty($password)) {
    sendError('Email and password are required', 422);
}

$cleanPhone = preg_replace('/[^0-9]/', '', $email);

try {
    $stmt = $pdo->prepare("SELECT * FROM admins WHERE LOWER(email) = LOWER(?) OR (phone = ? AND phone != '') LIMIT 1");
    $stmt->execute([$email, $cleanPhone]);
    $admin = $stmt->fetch();

    if ($admin) {
        $storedPass = $admin['password'] ?? '';
        $passValid = ($storedPass === $password) || (!empty($storedPass) && password_verify($password, $storedPass));

        if ($passValid) {
            if ($storedPass === $password) {
                $newHash = password_hash($password, PASSWORD_BCRYPT);
                $pdo->prepare("UPDATE admins SET password = ? WHERE id = ?")->execute([$newHash, $admin['id']]);
            }

            $token = AuthHelper::generateToken([
                'sub'   => (int)$admin['id'],
                'role'  => 'admin',
                'email' => $admin['email'],
                'name'  => $admin['name']
            ]);

            sendSuccess([
                'token' => $token,
                'admin' => [
                    'id'    => (int)$admin['id'],
                    'name'  => $admin['name'],
                    'email' => $admin['email'],
                    'role'  => $admin['role'],
                    'phone' => $admin['phone']
                ]
            ], 'Admin logged in successfully');
        } else {
            sendError('Invalid admin email or password', 401);
        }
    } else {
        sendError('Invalid admin email or password', 401);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
