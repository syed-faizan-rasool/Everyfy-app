<?php
/**
 * Admin Delivery Fleet (Riders) Management API
 * GET/POST/DELETE /api/admin/riders.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET') {
        $stmt = $pdo->query("SELECT id, name, phone, cnic, vehicle_type, vehicle_number, rating, is_online, is_active, total_deliveries, current_lat, current_lng, created_at FROM delivery_boys ORDER BY id ASC");
        $riders = $stmt->fetchAll();

        // Check active order for each rider
        $orderStmt = $pdo->prepare("SELECT id, order_number FROM orders WHERE delivery_boy_id = ? AND order_status IN ('ready', 'picked_up', 'on_the_way') LIMIT 1");

        $formatted = array_map(function($r) use ($orderStmt) {
            $orderStmt->execute([$r['id']]);
            $activeOrder = $orderStmt->fetch();

            return [
                'id'               => (int)$r['id'],
                'name'             => $r['name'],
                'phone'            => $r['phone'],
                'cnic'             => $r['cnic'],
                'vehicle_type'     => $r['vehicle_type'],
                'vehicle_number'   => $r['vehicle_number'],
                'rating'           => (float)$r['rating'],
                'is_online'        => (bool)$r['is_online'],
                'is_active'        => (bool)$r['is_active'],
                'total_deliveries' => (int)$r['total_deliveries'],
                'current_order'    => $activeOrder ? $activeOrder['order_number'] : null,
                'status_label'     => $activeOrder ? 'On Delivery' : ($r['is_online'] ? 'Available' : 'Offline')
            ];
        }, $riders);

        sendSuccess($formatted, 'Delivery fleet retrieved');

    } elseif ($method === 'POST') {
        $data          = getRequestData();
        $id            = isset($data['id']) ? (int)$data['id'] : 0;
        $name          = isset($data['name']) ? trim($data['name']) : '';
        $phone         = isset($data['phone']) ? trim($data['phone']) : '';
        $password      = isset($data['password']) ? trim($data['password']) : '1234';
        $cnic          = isset($data['cnic']) ? trim($data['cnic']) : '';
        $vehicleType   = isset($data['vehicle_type']) ? trim($data['vehicle_type']) : 'Motorcycle';
        $vehicleNumber = isset($data['vehicle_number']) ? trim($data['vehicle_number']) : '';
        $isActive      = isset($data['is_active']) ? (int)$data['is_active'] : 1;

        if (empty($name) || empty($phone)) {
            sendError('Rider name and phone number are required', 422);
        }

        $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
        $hashedPass = password_hash($password, PASSWORD_BCRYPT);

        if ($id > 0) {
            $sql = "UPDATE delivery_boys SET name = ?, phone = ?, cnic = ?, vehicle_type = ?, vehicle_number = ?, is_active = ? WHERE id = ?";
            $params = [$name, $cleanPhone, $cnic, $vehicleType, $vehicleNumber, $isActive, $id];
            if (!empty($password) && $password !== '1234') {
                $sql = "UPDATE delivery_boys SET name = ?, phone = ?, password = ?, cnic = ?, vehicle_type = ?, vehicle_number = ?, is_active = ? WHERE id = ?";
                $params = [$name, $cleanPhone, $hashedPass, $cnic, $vehicleType, $vehicleNumber, $isActive, $id];
            }
            $pdo->prepare($sql)->execute($params);
            sendSuccess(['id' => $id], 'Rider details updated');
        } else {
            $stmt = $pdo->prepare("INSERT INTO delivery_boys (name, phone, password, cnic, vehicle_type, vehicle_number, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$name, $cleanPhone, $hashedPass, $cnic, $vehicleType, $vehicleNumber, $isActive]);
            $newId = (int)$pdo->lastInsertId();
            sendSuccess(['id' => $newId], 'Rider added successfully');
        }

    } elseif ($method === 'DELETE') {
        $data = getRequestData();
        $id = isset($data['id']) ? (int)$data['id'] : (isset($_GET['id']) ? (int)$_GET['id'] : 0);
        if ($id <= 0) sendError('Rider ID is required', 422);

        $pdo->prepare("DELETE FROM delivery_boys WHERE id = ?")->execute([$id]);
        sendSuccess(['id' => $id], 'Rider removed successfully');
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
