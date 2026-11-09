<?php
/**
 * Unified Login API (Customer, Rider & Admin)
 * POST /api/auth/login.php
 * Body: { identifier: "phone or email", password: "...", role: "auto|customer|rider|admin" }
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$data       = getRequestData();
$identifier = isset($data['identifier']) ? trim($data['identifier']) : (isset($data['phone']) ? trim($data['phone']) : (isset($data['email']) ? trim($data['email']) : ''));
$password   = isset($data['password']) ? trim($data['password']) : '';
$role       = isset($data['role']) ? trim($data['role']) : 'auto';

if (empty($identifier) || empty($password)) {
    sendError('Please provide both username/email/phone and password', 422);
}

$isEmail    = filter_var($identifier, FILTER_VALIDATE_EMAIL) || str_contains($identifier, '@');
$cleanPhone = preg_replace('/[^0-9]/', '', $identifier);
$hasPhone   = strlen($cleanPhone) >= 7;

try {
    // 1. ADMIN CHECK (if role is admin or auto)
    if ($role === 'admin' || $role === 'auto') {
        if ($isEmail) {
            $stmt = $pdo->prepare("SELECT id, name, email, phone, password, role FROM admins WHERE LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$identifier]);
        } else {
            $stmt = $pdo->prepare("SELECT id, name, email, phone, password, role FROM admins WHERE (phone = ? AND phone != '') OR LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$cleanPhone, $identifier]);
        }
        $admin = $stmt->fetch();

        if ($admin) {
            $storedPass = $admin['password'] ?? '';
            $passValid = ($storedPass === $password) || (!empty($storedPass) && password_verify($password, $storedPass));

            if ($passValid) {
                // Auto-upgrade plain text to bcrypt hash in DB
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
                    'role'  => 'admin',
                    'user'  => [
                        'id'    => (int)$admin['id'],
                        'name'  => $admin['name'],
                        'email' => $admin['email'],
                        'phone' => $admin['phone'] ?? '',
                        'role'  => 'admin'
                    ]
                ], 'Admin login successful');
            } elseif ($role === 'admin') {
                sendError('Invalid email or password', 401);
            }
        }
    }

    // 2. RIDER CHECK (if role is rider or auto)
    if ($role === 'rider' || $role === 'auto') {
        if ($isEmail) {
            $stmt = $pdo->prepare("SELECT id, name, phone, email, password, vehicle_type, vehicle_number, is_online, rating FROM delivery_boys WHERE (email IS NOT NULL AND LOWER(email) = LOWER(?)) LIMIT 1");
            $stmt->execute([$identifier]);
        } else {
            $stmt = $pdo->prepare("SELECT id, name, phone, email, password, vehicle_type, vehicle_number, is_online, rating FROM delivery_boys WHERE phone = ? OR (email IS NOT NULL AND LOWER(email) = LOWER(?)) LIMIT 1");
            $stmt->execute([$cleanPhone, $identifier]);
        }
        $rider = $stmt->fetch();

        if ($rider) {
            $storedPass = $rider['password'] ?? '';
            $passValid = ($storedPass === $password) || (!empty($storedPass) && password_verify($password, $storedPass));

            if ($passValid) {
                // Auto-upgrade plain text to bcrypt hash in DB
                if ($storedPass === $password) {
                    $newHash = password_hash($password, PASSWORD_BCRYPT);
                    $pdo->prepare("UPDATE delivery_boys SET password = ? WHERE id = ?")->execute([$newHash, $rider['id']]);
                }

                $token = AuthHelper::generateToken([
                    'sub'   => (int)$rider['id'],
                    'role'  => 'rider',
                    'phone' => $rider['phone'],
                    'email' => $rider['email'] ?? '',
                    'name'  => $rider['name']
                ]);

                sendSuccess([
                    'token' => $token,
                    'role'  => 'rider',
                    'user'  => [
                        'id'             => (int)$rider['id'],
                        'name'           => $rider['name'],
                        'phone'          => $rider['phone'],
                        'email'          => $rider['email'] ?? '',
                        'vehicle'        => ($rider['vehicle_type'] ?? 'Motorcycle') . ' · ' . ($rider['vehicle_number'] ?? ''),
                        'rating'         => (float)($rider['rating'] ?? 5.0),
                        'is_online'      => (bool)($rider['is_online'] ?? 1),
                        'role'           => 'rider'
                    ]
                ], 'Rider login successful');
            } elseif ($role === 'rider') {
                sendError('Invalid rider phone number or password', 401);
            }
        }
    }

    // 3. CUSTOMER CHECK (if role is customer or auto)
    if ($role === 'customer' || $role === 'auto') {
        if ($isEmail) {
            $stmt = $pdo->prepare("SELECT id, name, phone, email, password FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$identifier]);
        } else {
            $stmt = $pdo->prepare("SELECT id, name, phone, email, password FROM users WHERE phone = ? OR LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$cleanPhone, $identifier]);
        }
        $user = $stmt->fetch();

        if ($user) {
            $storedPass = $user['password'] ?? '';
            $passValid = ($storedPass === $password) || (!empty($storedPass) && password_verify($password, $storedPass));

            if ($passValid) {
                // Auto-upgrade plain text to bcrypt hash in DB
                if ($storedPass === $password) {
                    $newHash = password_hash($password, PASSWORD_BCRYPT);
                    $pdo->prepare("UPDATE users SET password = ? WHERE id = ?")->execute([$newHash, $user['id']]);
                }

                $token = AuthHelper::generateToken([
                    'sub'   => (int)$user['id'],
                    'role'  => 'customer',
                    'phone' => $user['phone'],
                    'name'  => $user['name']
                ]);

                sendSuccess([
                    'token' => $token,
                    'role'  => 'customer',
                    'user'  => [
                        'id'    => (int)$user['id'],
                        'name'  => $user['name'],
                        'phone' => $user['phone'],
                        'email' => $user['email'] ?? '',
                        'role'  => 'customer'
                    ]
                ], 'Customer login successful');
            } elseif ($role === 'customer') {
                sendError('Invalid customer phone number or password', 401);
            }
        }
    }

    // If reached here and role was auto:
    sendError('Invalid email/phone or password. Please verify your credentials.', 401);

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
