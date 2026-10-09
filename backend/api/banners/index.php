<?php
/**
 * Promotional Banners
 * GET /api/banners/index.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

try {
    $stmt = $pdo->query("SELECT id, title, subtitle, image, link_product_id, sort_order FROM banners WHERE is_active = 1 ORDER BY sort_order ASC, id ASC");
    $banners = $stmt->fetchAll();

    $formatted = array_map(function($b) {
        return [
            'id'              => (int)$b['id'],
            'title'           => $b['title'] ?? '',
            'subtitle'        => $b['subtitle'] ?? '',
            'image'           => $b['image'],
            'link_product_id' => $b['link_product_id'] ? (int)$b['link_product_id'] : null,
            'sort_order'      => (int)$b['sort_order']
        ];
    }, $banners);

    sendSuccess($formatted, 'Banners fetched successfully');
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
