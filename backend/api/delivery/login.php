<?php
/**
 * Delivery Boy Login
 * POST /api/delivery/login.php
 * Body: { phone: "03019876543", password: "..." }
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
$identifier = isset($data['phone']) ? trim($data['phone']) : (isset($data['email']) ? trim($data['email']) : (isset($data['identifier']) ? trim($data['identifier']) : ''));
$password   = isset($data['password']) ? trim($data['password']) : '';

if (empty($identifier) || empty($password)) {
    sendError('Phone number or email and password are required', 422);
}

$cleanPhone = preg_replace('/[^0-9]/', '', $identifier);
$isEmail    = filter_var($identifier, FILTER_VALIDATE_EMAIL) || str_contains($identifier, '@');

try {
    if ($isEmail) {
        $stmt = $pdo->prepare("SELECT * FROM delivery_boys WHERE (email IS NOT NULL AND LOWER(email) = LOWER(?)) AND is_active = 1 LIMIT 1");
        $stmt->execute([$identifier]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM delivery_boys WHERE (phone = ? OR (email IS NOT NULL AND LOWER(email) = LOWER(?))) AND is_active = 1 LIMIT 1");
        $stmt->execute([$cleanPhone, $identifier]);
    }
    $rider = $stmt->fetch();

    if ($rider) {
        $storedPass = $rider['password'] ?? '';
        $passValid = ($storedPass === $password) || (!empty($storedPass) && password_verify($password, $storedPass));

        if ($passValid) {
            if ($storedPass === $password) {
                $newHash = password_hash($password, PASSWORD_BCRYPT);
                $pdo->prepare("UPDATE delivery_boys SET password = ? WHERE id = ?")->execute([$newHash, $rider['id']]);
            }

            $token = AuthHelper::generateToken([
                'sub'   => (int)$rider['id'],
                'role'  => 'rider',
                'phone' => $rider['phone'],
                'name'  => $rider['name']
            ]);

            sendSuccess([
                'token' => $token,
                'rider' => [
                    'id'               => (int)$rider['id'],
                    'name'             => $rider['name'],
                    'phone'            => $rider['phone'],
                    'vehicle_type'     => $rider['vehicle_type'] ?? 'Motorcycle',
                    'vehicle_number'   => $rider['vehicle_number'] ?? '',
                    'rating'           => (float)($rider['rating'] ?? 5.0),
                    'is_online'        => (bool)($rider['is_online'] ?? 1),
                    'total_deliveries' => (int)($rider['total_deliveries'] ?? 0),
                    'role'             => 'rider'
                ]
            ], 'Rider login successful');
        } else {
            sendError('Invalid rider phone number or password', 401);
        }
    } else {
        sendError('Invalid rider phone number or password', 401);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
