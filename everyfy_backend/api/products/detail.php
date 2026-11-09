<?php
/**
 * Single Product Details
 * GET /api/products/detail.php?id=1
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) {
    sendError('Valid product ID is required', 422);
}

try {
    $stmt = $pdo->prepare("SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON c.id = p.category_id WHERE p.id = ? LIMIT 1");
    $stmt->execute([$id]);
    $p = $stmt->fetch();

    if (!$p) {
        sendError('Product not found', 404);
    }

    sendSuccess([
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
        'in_stock'       => (int)$p['stock_qty'] > 0
    ], 'Product retrieved successfully');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
