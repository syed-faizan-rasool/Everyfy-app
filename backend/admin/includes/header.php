<?php
/**
 * Admin Panel Common Header & Navigation
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/db.php';

// Auth Guard
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: login.php');
    exit();
}

$adminName = $_SESSION['admin_name'] ?? 'Super Admin';
$adminEmail = $_SESSION['admin_email'] ?? 'admin@everyfy.net';

if (!function_exists('getAdminImageUrl')) {
    function getAdminImageUrl($img) {
        if (empty($img)) {
            return 'https://placehold.co/200x200?text=No+Image';
        }
        $trimmed = trim($img);
        if (preg_match('/^https?:\/\//i', $trimmed) || strpos($trimmed, 'data:image') === 0) {
            return $trimmed;
        }
        if (strpos($trimmed, '/') === 0) {
            return $trimmed;
        }
        return '../' . ltrim($trimmed, './');
    }
}

$currentPage = basename($_SERVER['PHP_SELF']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= isset($pageTitle) ? htmlspecialchars($pageTitle) . ' - ' : '' ?>Everyfy Admin Panel</title>
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome 6 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --brand-primary: #10B981;
            --brand-dark: #059669;
            --sidebar-bg: #0F172A;
            --sidebar-hover: #1E293B;
            --sidebar-active: #10B981;
            --bg-body: #F8FAFC;
        }

        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: var(--bg-body);
            color: #1E293B;
        }

        /* Sidebar */
        .admin-sidebar {
            width: 260px;
            min-height: 100vh;
            background: var(--sidebar-bg);
            color: #94A3B8;
            position: fixed;
            top: 0;
            left: 0;
            z-index: 1000;
            transition: all 0.3s;
        }

        .sidebar-brand {
            padding: 24px 20px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            align-items: center;
            gap: 12px;
            color: white;
            text-decoration: none;
        }

        .sidebar-brand-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, var(--brand-primary), var(--brand-dark));
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 18px;
        }

        .sidebar-menu {
            padding: 20px 12px;
            list-style: none;
            margin: 0;
        }

        .menu-header {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            color: #64748B;
            padding: 10px 12px 6px;
            font-weight: 700;
        }

        .menu-item a {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            color: #94A3B8;
            text-decoration: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.2s;
            margin-bottom: 4px;
        }

        .menu-item a:hover {
            background: var(--sidebar-hover);
            color: white;
        }

        .menu-item.active a {
            background: var(--brand-primary);
            color: white;
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
        }

        /* Main Content */
        .admin-main {
            margin-left: 260px;
            padding: 24px 30px;
            min-height: 100vh;
        }

        /* Topbar */
        .admin-topbar {
            background: white;
            border-radius: 16px;
            padding: 14px 24px;
            margin-bottom: 24px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.02);
            border: 1px solid #E2E8F0;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .stat-card {
            background: white;
            border-radius: 18px;
            padding: 20px;
            border: 1px solid #E2E8F0;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.02);
            transition: transform 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-2px);
        }

        .stat-icon-wrapper {
            width: 48px;
            height: 48px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .badge-status {
            padding: 6px 12px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 700;
        }
    </style>
</head>
<body>

<!-- Sidebar -->
<aside class="admin-sidebar">
    <a href="index.php" class="sidebar-brand">
        <div class="sidebar-brand-icon">
            <i class="fa-solid fa-basket-shopping"></i>
        </div>
        <div>
            <div class="fw-bold fs-5 text-white">Everyfy</div>
            <small class="text-white-50" style="font-size: 11px;">Operations Hub</small>
        </div>
    </a>

    <ul class="sidebar-menu">
        <li class="menu-header">Overview</li>
        <li class="menu-item <?= $currentPage === 'index.php' ? 'active' : '' ?>">
            <a href="index.php"><i class="fa-solid fa-chart-pie"></i> Dashboard</a>
        </li>
        <li class="menu-item <?= $currentPage === 'orders.php' ? 'active' : '' ?>">
            <a href="orders.php"><i class="fa-solid fa-receipt"></i> Orders Management</a>
        </li>

        <li class="menu-header mt-3">Catalog</li>
        <li class="menu-item <?= $currentPage === 'products.php' ? 'active' : '' ?>">
            <a href="products.php"><i class="fa-solid fa-box-open"></i> Products Catalog</a>
        </li>
        <li class="menu-item <?= $currentPage === 'categories.php' ? 'active' : '' ?>">
            <a href="categories.php"><i class="fa-solid fa-layer-group"></i> Categories</a>
        </li>
        <li class="menu-item <?= $currentPage === 'coupons.php' ? 'active' : '' ?>">
            <a href="coupons.php"><i class="fa-solid fa-ticket"></i> Promo Coupons</a>
        </li>

        <li class="menu-header mt-3">Fleet & People</li>
        <li class="menu-item <?= $currentPage === 'riders.php' ? 'active' : '' ?>">
            <a href="riders.php"><i class="fa-solid fa-motorcycle"></i> Delivery Riders</a>
        </li>

        <li class="menu-header mt-3">Settings & Security</li>
        <li class="menu-item <?= ($currentPage === 'settings.php' || $currentPage === 'profile.php') ? 'active' : '' ?>">
            <a href="settings.php"><i class="fa-solid fa-gear"></i> Settings & Profile</a>
        </li>
        <li class="menu-item mt-4">
            <a href="logout.php" class="text-danger"><i class="fa-solid fa-right-from-bracket"></i> Logout</a>
        </li>
    </ul>
</aside>

<!-- Main Wrapper -->
<main class="admin-main">
    <!-- Topbar -->
    <header class="admin-topbar">
        <div>
            <h5 class="fw-bold mb-0 text-dark"><?= isset($pageHeading) ? htmlspecialchars($pageHeading) : 'Store Dashboard' ?></h5>
            <small class="text-muted">Welcome back, <?= htmlspecialchars($adminName) ?></small>
        </div>

        <div class="d-flex align-items-center gap-3">
            <span class="badge bg-success-subtle text-success py-2 px-3 rounded-pill fw-semibold">
                <i class="fa-solid fa-circle me-1" style="font-size: 8px;"></i> Live Online
            </span>
            <div class="dropdown">
                <button class="btn btn-light rounded-pill px-3 py-2 border d-flex align-items-center gap-2 dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                    <div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center" style="width: 28px; height: 28px; font-size: 12px;">
                        <?= strtoupper(substr($adminName, 0, 1)) ?>
                    </div>
                    <span class="small fw-semibold"><?= htmlspecialchars($adminName) ?></span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0 rounded-3 mt-2">
                    <li><h6 class="dropdown-header small text-muted"><?= htmlspecialchars($adminEmail) ?></h6></li>
                    <li><a class="dropdown-item py-2" href="settings.php"><i class="fa-solid fa-user-gear me-2 text-secondary"></i> Settings & Profile</a></li>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li><a class="dropdown-item py-2 text-danger" href="logout.php"><i class="fa-solid fa-right-from-bracket me-2"></i> Logout</a></li>
                </ul>
            </div>
        </div>
    </header>
