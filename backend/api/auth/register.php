<?php
/**
 * Unified Registration API for Customers & Riders
 * POST /api/auth/register.php
 * Body: { name, phone, email, password, role: "customer|rider", vehicle_number, vehicle_type, cnic }
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
$name     = trim($data['name'] ?? '');
$phone    = preg_replace('/[^0-9]/', '', trim($data['phone'] ?? ''));
$email    = trim($data['email'] ?? '');
$password = trim($data['password'] ?? '');
$role     = trim($data['role'] ?? 'customer');

if (empty($name) || empty($phone) || empty($password)) {
    sendError('Name, phone number, and password are required!', 422);
}

if (strlen($password) < 4) {
    sendError('Password must be at least 4 characters!', 422);
}

$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

try {
    if ($role === 'rider') {
        // Check phone duplicate in delivery_boys
        $stmt = $pdo->prepare("SELECT id FROM delivery_boys WHERE phone = ? LIMIT 1");
        $stmt->execute([$phone]);
        if ($stmt->fetch()) {
            sendError('A delivery partner with this phone number already exists! Please log in.', 409);
        }

        $vehicleType   = trim($data['vehicle_type'] ?? 'Motorcycle');
        $vehicleNumber = trim($data['vehicle_number'] ?? 'LEB-1234');
        $cnic          = trim($data['cnic'] ?? '');

        $ins = $pdo->prepare("INSERT INTO delivery_boys (name, phone, password, cnic, vehicle_type, vehicle_number, is_online, is_active) VALUES (?, ?, ?, ?, ?, ?, 1, 1)");
        $ins->execute([$name, $phone, $hashedPassword, $cnic, $vehicleType, $vehicleNumber]);
        $newId = $pdo->lastInsertId();

        $token = AuthHelper::generateToken([
            'sub'   => (int)$newId,
            'role'  => 'rider',
            'phone' => $phone,
            'name'  => $name
        ]);

        sendSuccess([
            'token' => $token,
            'user'  => [
                'id'             => (int)$newId,
                'name'           => $name,
                'phone'          => $phone,
                'vehicle'        => "$vehicleType · $vehicleNumber",
                'rating'         => 5.0,
                'is_online'      => true,
                'role'           => 'rider'
            ]
        ], 'Rider registered successfully!', 201);
    } else {
        // Customer Registration
        $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? LIMIT 1");
        $stmt->execute([$phone]);
        if ($stmt->fetch()) {
            sendError('A customer with this phone number already exists! Please log in.', 409);
        }

        $ins = $pdo->prepare("INSERT INTO users (name, phone, email, password, is_active) VALUES (?, ?, ?, ?, 1)");
        $ins->execute([$name, $phone, !empty($email) ? $email : null, $hashedPassword]);
        $newId = $pdo->lastInsertId();

        $token = AuthHelper::generateToken([
            'sub'   => (int)$newId,
            'role'  => 'customer',
            'phone' => $phone,
            'name'  => $name
        ]);

        sendSuccess([
            'token' => $token,
            'user'  => [
                'id'    => (int)$newId,
                'name'  => $name,
                'phone' => $phone,
                'email' => $email,
                'role'  => 'customer'
            ]
        ], 'Account created successfully!', 201);
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
