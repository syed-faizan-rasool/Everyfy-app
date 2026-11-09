<?php
/**
 * Products Catalog List
 * GET /api/products/index.php
 * Query Params: ?category_id=1&search=apple&featured=1&page=1&limit=50
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

$categoryId = isset($_GET['category_id']) && is_numeric($_GET['category_id']) ? (int)$_GET['category_id'] : null;
$search     = isset($_GET['search']) ? trim($_GET['search']) : '';
$featured   = isset($_GET['featured']) ? (int)$_GET['featured'] : null;
$page       = isset($_GET['page']) && (int)$_GET['page'] > 0 ? (int)$_GET['page'] : 1;
$limit      = isset($_GET['limit']) && (int)$_GET['limit'] > 0 ? min((int)$_GET['limit'], 2000) : 1000;
$offset     = ($page - 1) * $limit;

try {
    $where = ["p.is_available = 1"];
    $params = [];

    if ($categoryId !== null) {
        $where[] = "p.category_id = ?";
        $params[] = $categoryId;
    }

    if (!empty($search)) {
        $where[] = "(p.name LIKE ? OR p.description LIKE ?)";
        $params[] = "%{$search}%";
        $params[] = "%{$search}%";
    }

    if ($featured !== null) {
        $where[] = "p.is_featured = ?";
        $params[] = $featured;
    }

    $whereClause = implode(' AND ', $where);

    $sql = "SELECT p.*, c.name as category_name
            FROM products p
            LEFT JOIN categories c ON c.id = p.category_id
            WHERE {$whereClause}
            ORDER BY p.id ASC
            LIMIT {$limit} OFFSET {$offset}";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
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
            'unit'           => $p['unit'] ?: '1 kg',
            'stock_qty'      => (int)$p['stock_qty'],
            'is_featured'    => (bool)$p['is_featured'],
            'in_stock'       => (int)$p['stock_qty'] > 0
        ];
    }, $products);

    sendSuccess($formatted, 'Products retrieved successfully');
} catch (PDOException $e) {
    sendError('Failed to fetch products: ' . $e->getMessage(), 500);
}
