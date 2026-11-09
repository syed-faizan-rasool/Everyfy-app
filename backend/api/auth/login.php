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
    sendError('Database connection failed. Please verify your MySQL server connection.', 500);
}

$data       = getRequestData();
$identifier = isset($data['identifier']) ? trim($data['identifier']) : (isset($data['phone']) ? trim($data['phone']) : (isset($data['email']) ? trim($data['email']) : ''));
$password   = isset($data['password']) ? trim($data['password']) : '';
$role       = isset($data['role']) ? trim($data['role']) : 'auto';

if (empty($identifier) || empty($password)) {
    sendError('Please provide both username/email/phone and password', 422);
}

// Helper to get columns for a table safely
function getTableCols(PDO $pdo, string $table): array {
    try {
        $stmt = $pdo->query("SHOW COLUMNS FROM `{$table}`");
        return $stmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
    } catch (Throwable $e) {
        return [];
    }
}

// Helper to auto-add missing columns safely
function tryAddColumn(PDO $pdo, string $table, string $column, string $def) {
    try {
        $pdo->exec("ALTER TABLE `{$table}` ADD COLUMN `{$column}` {$def}");
    } catch (Throwable $e) {}
}

$isEmail    = filter_var($identifier, FILTER_VALIDATE_EMAIL) || str_contains($identifier, '@');
$cleanPhone = preg_replace('/[^0-9]/', '', $identifier);
$hasPhone   = strlen($cleanPhone) >= 7;

$phoneVariants = [$identifier];
if ($hasPhone) {
    $p1 = $cleanPhone;
    $p2 = ltrim($cleanPhone, '0');
    $p3 = '0' . $p2;
    $p4 = '92' . ltrim(ltrim($p2, '92'), '0');
    $p5 = '+92' . ltrim(ltrim($p2, '92'), '0');
    $phoneVariants = array_values(array_unique(array_filter([$p1, $p2, $p3, $p4, $p5, $identifier])));
}
$phonePlaceholders = implode(',', array_fill(0, count($phoneVariants), '?'));

// ==============================================================
// 1. ADMIN CHECK (if role is admin or auto)
// ==============================================================
if ($role === 'admin' || $role === 'auto') {
    try {
        $adminCols = getTableCols($pdo, 'admins');
        if (!empty($adminCols)) {
            if (!in_array('phone', $adminCols)) {
                tryAddColumn($pdo, 'admins', 'phone', 'VARCHAR(25) NULL');
                $adminCols = getTableCols($pdo, 'admins');
            }

            $hasAdminPhone = in_array('phone', $adminCols);
            $hasAdminEmail = in_array('email', $adminCols);

            $admin = null;
            if ($isEmail && $hasAdminEmail) {
                $stmt = $pdo->prepare("SELECT id, name, email, password, role FROM admins WHERE LOWER(email) = LOWER(?) LIMIT 1");
                $stmt->execute([$identifier]);
                $admin = $stmt->fetch();
            } else if (!$isEmail) {
                if ($hasAdminPhone && $hasAdminEmail) {
                    $stmt = $pdo->prepare("SELECT id, name, email, password, role FROM admins WHERE (phone IN ($phonePlaceholders) AND phone != '') OR LOWER(email) = LOWER(?) LIMIT 1");
                    $stmt->execute(array_merge($phoneVariants, [$identifier]));
                } else if ($hasAdminEmail) {
                    $stmt = $pdo->prepare("SELECT id, name, email, password, role FROM admins WHERE LOWER(email) = LOWER(?) LIMIT 1");
                    $stmt->execute([$identifier]);
                }
                if ($stmt) {
                    $admin = $stmt->fetch();
                }
            }

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
                        'email' => $admin['email'] ?? '',
                        'name'  => $admin['name']
                    ]);

                    sendSuccess([
                        'token' => $token,
                        'role'  => 'admin',
                        'user'  => [
                            'id'    => (int)$admin['id'],
                            'name'  => $admin['name'],
                            'email' => $admin['email'] ?? '',
                            'phone' => $admin['phone'] ?? '',
                            'role'  => 'admin'
                        ]
                    ], 'Admin login successful');
                } elseif ($role === 'admin') {
                    sendError('Invalid email or password', 401);
                }
            }
        }
    } catch (Throwable $e) {
        if ($role === 'admin') {
            sendError('Database error in admin check: ' . $e->getMessage(), 500);
        }
    }
}

// ==============================================================
// 2. RIDER CHECK (if role is rider or auto)
// ==============================================================
if ($role === 'rider' || $role === 'auto') {
    try {
        $riderCols = getTableCols($pdo, 'delivery_boys');
        if (!empty($riderCols)) {
            if (!in_array('email', $riderCols)) {
                tryAddColumn($pdo, 'delivery_boys', 'email', 'VARCHAR(120) NULL AFTER phone');
                $riderCols = getTableCols($pdo, 'delivery_boys');
            }

            $riderHasEmail = in_array('email', $riderCols);
            $rider = null;

            if ($riderHasEmail) {
                if ($isEmail) {
                    $stmt = $pdo->prepare("SELECT id, name, phone, email, password, vehicle_type, vehicle_number, is_online, rating FROM delivery_boys WHERE (email IS NOT NULL AND LOWER(email) = LOWER(?)) LIMIT 1");
                    $stmt->execute([$identifier]);
                    $rider = $stmt->fetch();
                } else {
                    $stmt = $pdo->prepare("SELECT id, name, phone, email, password, vehicle_type, vehicle_number, is_online, rating FROM delivery_boys WHERE phone IN ($phonePlaceholders) OR (email IS NOT NULL AND LOWER(email) = LOWER(?)) LIMIT 1");
                    $stmt->execute(array_merge($phoneVariants, [$identifier]));
                    $rider = $stmt->fetch();
                }
            } else if (!$isEmail) {
                $stmt = $pdo->prepare("SELECT id, name, phone, password, vehicle_type, vehicle_number, is_online, rating FROM delivery_boys WHERE phone IN ($phonePlaceholders) LIMIT 1");
                $stmt->execute($phoneVariants);
                $rider = $stmt->fetch();
            }

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
    } catch (Throwable $e) {
        if ($role === 'rider') {
            sendError('Database error in rider check: ' . $e->getMessage(), 500);
        }
    }
}

// ==============================================================
// 3. CUSTOMER CHECK (if role is customer or auto)
// ==============================================================
if ($role === 'customer' || $role === 'auto') {
    try {
        $userCols = getTableCols($pdo, 'users');
        if (!empty($userCols)) {
            // Auto-heal missing email/password/otp columns in users table
            if (!in_array('email', $userCols)) {
                tryAddColumn($pdo, 'users', 'email', 'VARCHAR(120) NULL AFTER phone');
                $userCols = getTableCols($pdo, 'users');
            }
            if (!in_array('password', $userCols)) {
                tryAddColumn($pdo, 'users', 'password', 'VARCHAR(255) NULL AFTER email');
                $userCols = getTableCols($pdo, 'users');
            }

            $usersHasEmail = in_array('email', $userCols);
            $user = null;

            if ($usersHasEmail) {
                if ($isEmail) {
                    $stmt = $pdo->prepare("SELECT id, name, phone, email, password FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
                    $stmt->execute([$identifier]);
                    $user = $stmt->fetch();
                } else {
                    $stmt = $pdo->prepare("SELECT id, name, phone, email, password FROM users WHERE phone IN ($phonePlaceholders) OR LOWER(email) = LOWER(?) LIMIT 1");
                    $stmt->execute(array_merge($phoneVariants, [$identifier]));
                    $user = $stmt->fetch();
                }
            } else {
                if (!$isEmail) {
                    $stmt = $pdo->prepare("SELECT id, name, phone, password FROM users WHERE phone IN ($phonePlaceholders) LIMIT 1");
                    $stmt->execute($phoneVariants);
                    $user = $stmt->fetch();
                }
            }

            if ($user) {
                $storedPass = $user['password'] ?? '';
                $passValid = ($storedPass === $password) || (!empty($storedPass) && password_verify($password, $storedPass));

                if ($passValid) {
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
                    sendError('Invalid customer password', 401);
                }
            }
        }
    } catch (Throwable $e) {
        sendError('Database error: ' . $e->getMessage(), 500);
    }
}

// If reached here:
sendError('Invalid email/phone or password. Please verify your credentials or register for an account.', 401);
