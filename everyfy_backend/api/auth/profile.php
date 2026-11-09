<?php
/**
 * Customer Profile (View / Update)
 * GET/POST /api/auth/profile.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$auth = AuthHelper::requireAuth(['customer', 'admin']);
$userId = (int)$auth['sub'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getRequestData();
    $name  = isset($data['name']) ? trim($data['name']) : null;
    $email = isset($data['email']) ? trim($data['email']) : null;

    $updates = [];
    $params  = [];

    if ($name !== null) {
        $updates[] = "name = ?";
        $params[] = $name;
    }
    if ($email !== null) {
        $updates[] = "email = ?";
        $params[] = $email;
    }

    if (!empty($updates)) {
        $params[] = $userId;
        $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
    }
}

// Fetch updated profile
$stmt = $pdo->prepare("SELECT id, name, phone, email, profile_image, created_at FROM users WHERE id = ? LIMIT 1");
$stmt->execute([$userId]);
$profile = $stmt->fetch();

if (!$profile) {
    sendError('User not found', 404);
}

sendSuccess($profile, 'User profile retrieved');
