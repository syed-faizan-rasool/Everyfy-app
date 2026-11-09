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

if (!empty($email) && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendError('Please provide a valid email address!', 422);
}

if (strlen($password) < 4) {
    sendError('Password must be at least 4 characters!', 422);
}

$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// Helper to get columns for a table safely
function getCols(PDO $pdo, string $table): array {
    try {
        $stmt = $pdo->query("SHOW COLUMNS FROM `{$table}`");
        return $stmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
    } catch (Throwable $e) {
        return [];
    }
}

// Helper to auto-add missing columns safely
function addColIfMissing(PDO $pdo, string $table, string $column, string $def) {
    try {
        $pdo->exec("ALTER TABLE `{$table}` ADD COLUMN `{$column}` {$def}");
    } catch (Throwable $e) {}
}

try {
    if ($role === 'rider') {
        $riderCols = getCols($pdo, 'delivery_boys');
        if (!in_array('email', $riderCols)) {
            addColIfMissing($pdo, 'delivery_boys', 'email', 'VARCHAR(120) NULL AFTER phone');
            $riderCols = getCols($pdo, 'delivery_boys');
        }

        // Check phone duplicate
        $checkSql = in_array('email', $riderCols) && !empty($email)
            ? "SELECT id FROM delivery_boys WHERE phone = ? OR (email IS NOT NULL AND email != '' AND LOWER(email) = LOWER(?)) LIMIT 1"
            : "SELECT id FROM delivery_boys WHERE phone = ? LIMIT 1";
        
        $stmt = $pdo->prepare($checkSql);
        $stmt->execute(in_array('email', $riderCols) && !empty($email) ? [$phone, $email] : [$phone]);
        if ($stmt->fetch()) {
            sendError('A delivery partner with this phone or email already exists! Please log in.', 409);
        }

        $vehicleType   = trim($data['vehicle_type'] ?? 'Motorcycle');
        $vehicleNumber = trim($data['vehicle_number'] ?? 'LEB-1234');
        $cnic          = trim($data['cnic'] ?? '');

        if (in_array('email', $riderCols)) {
            $ins = $pdo->prepare("INSERT INTO delivery_boys (name, phone, email, password, cnic, vehicle_type, vehicle_number, is_online, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1)");
            $ins->execute([$name, $phone, !empty($email) ? $email : null, $hashedPassword, $cnic, $vehicleType, $vehicleNumber]);
        } else {
            $ins = $pdo->prepare("INSERT INTO delivery_boys (name, phone, password, cnic, vehicle_type, vehicle_number, is_online, is_active) VALUES (?, ?, ?, ?, ?, ?, 1, 1)");
            $ins->execute([$name, $phone, $hashedPassword, $cnic, $vehicleType, $vehicleNumber]);
        }
        $newId = (int)$pdo->lastInsertId();

        $token = AuthHelper::generateToken([
            'sub'   => $newId,
            'role'  => 'rider',
            'phone' => $phone,
            'email' => $email,
            'name'  => $name
        ]);

        sendSuccess([
            'token' => $token,
            'role'  => 'rider',
            'user'  => [
                'id'             => $newId,
                'name'           => $name,
                'email'          => $email,
                'phone'          => $phone,
                'vehicle'        => "$vehicleType · $vehicleNumber",
                'rating'         => 5.0,
                'is_online'      => true,
                'role'           => 'rider'
            ]
        ], 'Rider registered successfully!', 201);

    } else {
        // Customer Registration
        $userCols = getCols($pdo, 'users');
        if (!in_array('email', $userCols)) {
            addColIfMissing($pdo, 'users', 'email', 'VARCHAR(120) NULL AFTER phone');
            $userCols = getCols($pdo, 'users');
        }
        if (!in_array('password', $userCols)) {
            addColIfMissing($pdo, 'users', 'password', 'VARCHAR(255) NULL AFTER email');
            $userCols = getCols($pdo, 'users');
        }

        $hasEmailCol = in_array('email', $userCols);

        if ($hasEmailCol && !empty($email)) {
            $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? OR LOWER(email) = LOWER(?) LIMIT 1");
            $stmt->execute([$phone, $email]);
        } else {
            $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? LIMIT 1");
            $stmt->execute([$phone]);
        }
        if ($stmt->fetch()) {
            sendError('An account with this phone number or email already exists! Please log in.', 409);
        }

        if ($hasEmailCol) {
            $ins = $pdo->prepare("INSERT INTO users (name, phone, email, password, is_active) VALUES (?, ?, ?, ?, 1)");
            $ins->execute([$name, $phone, !empty($email) ? $email : null, $hashedPassword]);
        } else {
            $ins = $pdo->prepare("INSERT INTO users (name, phone, password, is_active) VALUES (?, ?, ?, 1)");
            $ins->execute([$name, $phone, $hashedPassword]);
        }
        $newId = (int)$pdo->lastInsertId();

        $token = AuthHelper::generateToken([
            'sub'   => $newId,
            'role'  => 'customer',
            'phone' => $phone,
            'name'  => $name
        ]);

        sendSuccess([
            'token' => $token,
            'role'  => 'customer',
            'user'  => [
                'id'    => $newId,
                'name'  => $name,
                'phone' => $phone,
                'email' => $email,
                'role'  => 'customer'
            ]
        ], 'Account created successfully!', 201);
    }
} catch (PDOException $e) {
    sendError('Registration database error: ' . $e->getMessage(), 500);
}
