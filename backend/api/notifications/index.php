<?php
/**
 * Notifications API for Customers, Admins, and Riders
 * GET  /api/notifications/index.php - List notifications for a role
 * POST /api/notifications/index.php - Mark notification(s) as read
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/notification_helper.php';

// Enable CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

// -------------------------------------------------------------
// POST: Mark As Read
// -------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getRequestData();
    $id = isset($data['id']) ? (int)$data['id'] : null;
    $markAll = !empty($data['mark_all']);
    $role = isset($data['role']) ? trim($data['role']) : 'customer';
    $userId = isset($data['user_id']) ? (int)$data['user_id'] : null;

    if ($id && $id > 0) {
        $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = ?");
        $stmt->execute([$id]);
        sendSuccess(['id' => $id], 'Notification marked as read');
    }

    if ($markAll) {
        if ($role === 'admin') {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE role = 'admin'");
            $stmt->execute();
        } elseif ($userId) {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE (user_id = ? OR (role = ? AND user_id IS NULL))");
            $stmt->execute([$userId, $role]);
        } else {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE role = ?");
            $stmt->execute([$role]);
        }
        sendSuccess([], 'All notifications marked as read');
    }

    sendError('Invalid request parameters', 400);
}

// -------------------------------------------------------------
// GET: Fetch Notifications
// -------------------------------------------------------------
$role = isset($_GET['role']) ? trim($_GET['role']) : 'customer';
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
$limit = isset($_GET['limit']) ? min((int)$_GET['limit'], 50) : 30;

$where = [];
$params = [];

if ($role === 'admin') {
    $where[] = "(role = 'admin' OR role = 'all')";
} elseif ($role === 'rider') {
    if ($userId) {
        $where[] = "((role = 'rider' AND (user_id = ? OR user_id IS NULL)) OR role = 'all')";
        $params[] = $userId;
    } else {
        $where[] = "(role = 'rider' OR role = 'all')";
    }
} else {
    // Customer
    if ($userId) {
        $where[] = "((role = 'customer' AND (user_id = ? OR user_id IS NULL)) OR role = 'all')";
        $params[] = $userId;
    } else {
        $where[] = "(role = 'customer' OR role = 'all')";
    }
}

$whereSql = !empty($where) ? "WHERE " . implode(' AND ', $where) : "";

$sql = "SELECT id, user_id, role, title, message, type, order_id, order_number, is_read, created_at
        FROM notifications
        {$whereSql}
        ORDER BY id DESC
        LIMIT {$limit}";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$notifications = $stmt->fetchAll();

// Count unread
$countSql = "SELECT COUNT(*) as unread FROM notifications {$whereSql} " . (!empty($whereSql) ? "AND" : "WHERE") . " is_read = 0";
$countStmt = $pdo->prepare($countSql);
$countStmt->execute($params);
$unreadCount = (int)($countStmt->fetchColumn() ?: 0);

sendSuccess([
    'unread_count'  => $unreadCount,
    'notifications' => array_map(function($n) {
        return [
            'id'           => (int)$n['id'],
            'user_id'      => $n['user_id'] ? (int)$n['user_id'] : null,
            'role'         => $n['role'],
            'title'        => $n['title'],
            'message'      => $n['message'],
            'type'         => $n['type'],
            'order_id'     => $n['order_id'] ? (int)$n['order_id'] : null,
            'order_number' => $n['order_number'] ?? null,
            'is_read'      => (bool)$n['is_read'],
            'created_at'   => $n['created_at'],
        ];
    }, $notifications),
], 'Notifications retrieved successfully');

