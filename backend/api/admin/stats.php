<?php
/**
 * Admin Dashboard KPIs & Realtime Statistics
 * GET /api/admin/stats.php
 */

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/auth.php';

$pdo = Database::getConnection();
if (!$pdo) {
    sendError('Database connection failed', 500);
}

try {
    $today = date('Y-m-d');

    // Total Revenue (all delivered orders)
    $revStmt = $pdo->query("SELECT COALESCE(SUM(total_amount), 0) as total_rev FROM orders WHERE order_status = 'delivered'");
    $totalRevenue = (float)$revStmt->fetch()['total_rev'];

    // Today Revenue
    $todayRevStmt = $pdo->prepare("SELECT COALESCE(SUM(total_amount), 0) as today_rev FROM orders WHERE order_status = 'delivered' AND DATE(created_at) = ?");
    $todayRevStmt->execute([$today]);
    $todayRevenue = (float)$todayRevStmt->fetch()['today_rev'];

    // Today Orders Count
    $todayOrdersStmt = $pdo->prepare("SELECT COUNT(*) as cnt FROM orders WHERE DATE(created_at) = ?");
    $todayOrdersStmt->execute([$today]);
    $todayOrders = (int)$todayOrdersStmt->fetch()['cnt'];

    // Total Orders Count
    $totalOrders = (int)$pdo->query("SELECT COUNT(*) as cnt FROM orders")->fetch()['cnt'];

    // Pending Orders (placed or confirmed)
    $pendingOrders = (int)$pdo->query("SELECT COUNT(*) as cnt FROM orders WHERE order_status IN ('placed', 'confirmed')")->fetch()['cnt'];

    // Preparing Orders
    $preparingOrders = (int)$pdo->query("SELECT COUNT(*) as cnt FROM orders WHERE order_status = 'preparing'")->fetch()['cnt'];

    // Out for Delivery Orders
    $outForDeliveryOrders = (int)$pdo->query("SELECT COUNT(*) as cnt FROM orders WHERE order_status = 'on_the_way'")->fetch()['cnt'];

    // Total Customers
    $totalCustomers = (int)$pdo->query("SELECT COUNT(*) as cnt FROM users")->fetch()['cnt'];

    // Fleet Summary
    $activeRiders = (int)$pdo->query("SELECT COUNT(*) as cnt FROM delivery_boys WHERE is_online = 1 AND is_active = 1")->fetch()['cnt'];
    $totalRiders = (int)$pdo->query("SELECT COUNT(*) as cnt FROM delivery_boys WHERE is_active = 1")->fetch()['cnt'];

    // Low Stock Alert (stock <= 5)
    $lowStockStmt = $pdo->query("SELECT id, name, stock_qty, unit, price FROM products WHERE stock_qty <= 15 AND is_available = 1 ORDER BY stock_qty ASC LIMIT 10");
    $lowStockProducts = $lowStockStmt->fetchAll();

    sendSuccess([
        'total_revenue'          => $totalRevenue,
        'today_revenue'          => $todayRevenue,
        'total_orders'           => $totalOrders,
        'today_orders'           => $todayOrders,
        'pending_orders'         => $pendingOrders,
        'preparing_orders'       => $preparingOrders,
        'out_for_delivery'       => $outForDeliveryOrders,
        'total_customers'        => $totalCustomers,
        'active_riders'          => $activeRiders,
        'total_riders'           => $totalRiders,
        'low_stock_count'        => count($lowStockProducts),
        'low_stock_products'     => $lowStockProducts
    ], 'Admin dashboard statistics retrieved');

} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
}
