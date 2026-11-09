<?php
/**
 * Everyfy REST API Root & Health Check
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/response.php';

$pdo = Database::getConnection();
$dbConnected = ($pdo !== null);

sendSuccess([
    'app_name'    => 'Everyfy Grocery & Delivery API',
    'version'     => '1.0.0',
    'status'      => 'online',
    'database'    => $dbConnected ? 'connected' : 'disconnected (run /setup.php or check config/db.php)',
    'server_time' => date('Y-m-d H:i:s'),
    'endpoints'   => [
        'auth'       => [
            'POST /api/auth/send_otp.php'   => 'Send phone verification code',
            'POST /api/auth/verify_otp.php' => 'Verify code & get JWT token',
            'POST /api/auth/login.php'      => 'Customer login with password',
            'GET  /api/auth/profile.php'    => 'Get customer profile'
        ],
        'catalog'    => [
            'GET /api/categories/index.php' => 'List categories',
            'GET /api/products/index.php'   => 'List products (filter by category_id, search, featured)',
            'GET /api/products/detail.php'  => 'Single product details',
            'GET /api/banners/index.php'    => 'Home promotional banners',
            'POST /api/coupons/apply.php'   => 'Validate coupon code'
        ],
        'customer'   => [
            'GET/POST /api/addresses/index.php' => 'Customer address book',
            'POST /api/orders/checkout.php'     => 'Place grocery order',
            'GET  /api/orders/index.php'        => 'Customer order history',
            'GET  /api/orders/detail.php'       => 'Order tracking & detail',
            'POST /api/orders/cancel.php'       => 'Cancel order'
        ],
        'rider'      => [
            'POST /api/delivery/login.php'             => 'Delivery boy login',
            'GET  /api/delivery/orders/available.php'  => 'Available orders for pickup',
            'POST /api/delivery/orders/accept.php'     => 'Accept order delivery',
            'POST /api/delivery/orders/status.php'     => 'Update delivery status',
            'POST /api/delivery/toggle_online.php'     => 'Go online/offline',
            'POST /api/delivery/location.php'          => 'Update live coordinates'
        ],
        'admin'      => [
            'POST /api/admin/login.php'    => 'Admin dashboard login',
            'GET  /api/admin/stats.php'    => 'Revenue & order statistics',
            'GET  /api/admin/orders.php'   => 'Manage orders & assign riders'
        ]
    ]
], 'Everyfy API is running successfully');
