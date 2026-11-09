<?php
/**
 * Admin Products CRUD API
 * GET/POST/DELETE /api/admin/products.php
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
        $stmt = $pdo->query("SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON c.id = p.category_id ORDER BY p.id DESC");
        $products = $stmt->fetchAll();

        $formatted = array_map(function($p) {
            return [
                'id'             => (int)$p['id'],
                'category_id'    => (int)$p['category_id'],
                'category_name'  => $p['category_name'] ?? '',
                'name'           => $p['name'],
                'description'    => $p['description'] ?? '',
                'image'          => $p['image'],
                'price'          => (float)$p['price'],
                'discount_price' => $p['discount_price'] !== null ? (float)$p['discount_price'] : null,
                'unit'           => $p['unit'],
                'stock_qty'      => (int)$p['stock_qty'],
                'is_featured'    => (bool)$p['is_featured'],
                'is_available'   => (bool)$p['is_available']
            ];
        }, $products);

        sendSuccess($formatted, 'Products list retrieved');

    } elseif ($method === 'POST') {
        $data = getRequestData();
        $id            = isset($data['id']) ? (int)$data['id'] : 0;
        $categoryId    = isset($data['category_id']) ? (int)$data['category_id'] : 1;
        $name          = isset($data['name']) ? trim($data['name']) : '';
        $description   = isset($data['description']) ? trim($data['description']) : '';
        $price         = isset($data['price']) ? (float)$data['price'] : 0.0;
        $discountPrice = isset($data['discount_price']) && is_numeric($data['discount_price']) ? (float)$data['discount_price'] : null;
        $unit          = isset($data['unit']) ? trim($data['unit']) : '1 kg';
        $stockQty      = isset($data['stock_qty']) ? (int)$data['stock_qty'] : 50;
        $isFeatured    = !empty($data['is_featured']) ? 1 : 0;
        $isAvailable   = isset($data['is_available']) ? (int)$data['is_available'] : 1;

        // Image handling: either uploaded file or URL string
        $image = isset($data['image']) ? trim($data['image']) : '';
        if (isset($_FILES['image_file'])) {
            $uploadResult = UploadHelper::uploadImage('image_file', 'products');
            if ($uploadResult['success']) {
                $image = $uploadResult['url'];
            }
        }

        if (empty($name) || $price < 0) {
            sendError('Product name and valid price are required', 422);
        }

        if (empty($image) && $id > 0) {
            $existing = $pdo->prepare("SELECT image FROM products WHERE id = ?");
            $existing->execute([$id]);
            $image = $existing->fetchColumn() ?: '';
        }

        if (empty($image)) {
            $image = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500';
        }

        if ($id > 0) {
            // Update
            $sql = "UPDATE products SET category_id = ?, name = ?, description = ?, image = ?, price = ?, discount_price = ?, unit = ?, stock_qty = ?, is_featured = ?, is_available = ? WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$categoryId, $name, $description, $image, $price, $discountPrice, $unit, $stockQty, $isFeatured, $isAvailable, $id]);
            sendSuccess(['id' => $id], 'Product updated successfully');
        } else {
            // Insert
            $sql = "INSERT INTO products (category_id, name, description, image, price, discount_price, unit, stock_qty, is_featured, is_available) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$categoryId, $name, $description, $image, $price, $discountPrice, $unit, $stockQty, $isFeatured, $isAvailable]);
            $newId = (int)$pdo->lastInsertId();
            sendSuccess(['id' => $newId], 'Product added successfully');
        }

    } elseif ($method === 'DELETE') {
        $data = getRequestData();
        $id = isset($data['id']) ? (int)$data['id'] : (isset($_GET['id']) ? (int)$_GET['id'] : 0);

        if ($id <= 0) {
            sendError('Product ID is required', 422);
        }

        $stmt = $pdo->prepare("DELETE FROM products WHERE id = ?");
        $stmt->execute([$id]);

        sendSuccess(['id' => $id], 'Product deleted successfully');
    }
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
