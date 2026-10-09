<?php
/**
 * Admin Categories Management API
 * GET/POST/DELETE /api/admin/categories.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/upload.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    if ($method === 'GET') {
        $stmt = $pdo->query("SELECT c.*, COUNT(p.id) as product_count FROM categories c LEFT JOIN products p ON p.category_id = c.id GROUP BY c.id ORDER BY c.sort_order ASC, c.id ASC");
        $categories = $stmt->fetchAll();
        sendSuccess($categories, 'Categories retrieved');

    } elseif ($method === 'POST') {
        $data      = getRequestData();
        $id        = isset($data['id']) ? (int)$data['id'] : 0;
        $name      = isset($data['name']) ? trim($data['name']) : '';
        $sortOrder = isset($data['sort_order']) ? (int)$data['sort_order'] : 0;
        $isActive  = isset($data['is_active']) ? (int)$data['is_active'] : 1;
        $image     = isset($data['image']) ? trim($data['image']) : '';

        if (isset($_FILES['image_file'])) {
            $uploadResult = UploadHelper::uploadImage('image_file', 'categories');
            if ($uploadResult['success']) {
                $image = $uploadResult['url'];
            }
        }

        if (empty($name)) {
            sendError('Category name is required', 422);
        }

        if (empty($image)) {
            $image = 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400';
        }

        if ($id > 0) {
            $stmt = $pdo->prepare("UPDATE categories SET name = ?, image = ?, sort_order = ?, is_active = ? WHERE id = ?");
            $stmt->execute([$name, $image, $sortOrder, $isActive, $id]);
            sendSuccess(['id' => $id], 'Category updated successfully');
        } else {
            $stmt = $pdo->prepare("INSERT INTO categories (name, image, sort_order, is_active) VALUES (?, ?, ?, ?)");
            $stmt->execute([$name, $image, $sortOrder, $isActive]);
            $newId = (int)$pdo->lastInsertId();
            sendSuccess(['id' => $newId], 'Category created successfully');
        }

    } elseif ($method === 'DELETE') {
        $data = getRequestData();
        $id = isset($data['id']) ? (int)$data['id'] : (isset($_GET['id']) ? (int)$_GET['id'] : 0);
        if ($id <= 0) sendError('Category ID is required', 422);

        $pdo->prepare("DELETE FROM categories WHERE id = ?")->execute([$id]);
        sendSuccess(['id' => $id], 'Category deleted successfully');
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
