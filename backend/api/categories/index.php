<?php
/**
 * Categories List
 * GET /api/categories/index.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

try {
    $sql = "SELECT c.id, c.name, c.image, c.sort_order, COUNT(p.id) as product_count
            FROM categories c
            LEFT JOIN products p ON p.category_id = c.id AND p.is_available = 1
            WHERE c.is_active = 1
            GROUP BY c.id
            ORDER BY c.sort_order ASC, c.id ASC";
            
    $stmt = $pdo->query($sql);
    $categories = $stmt->fetchAll();

    // Cast fields to expected types
    $formatted = array_map(function($c) {
        return [
            'id'            => (int)$c['id'],
            'name'          => $c['name'],
            'image'         => $c['image'],
            'sort_order'    => (int)$c['sort_order'],
            'product_count' => (int)$c['product_count']
        ];
    }, $categories);

    sendSuccess($formatted, 'Categories fetched successfully');
} catch (PDOException $e) {
    sendError('Failed to fetch categories: ' . $e->getMessage(), 500);
}
