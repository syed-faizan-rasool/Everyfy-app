<?php
$pageTitle = 'Dashboard';
$pageHeading = 'Store Operations Overview';
require_once __DIR__ . '/includes/header.php';

$pdo = Database::getConnection();

// Fetch Real-time KPIs
$today = date('Y-m-d');

$todayRev = 0.0;
$todayOrdersCount = 0;
$pendingOrdersCount = 0;
$activeRidersCount = 0;
$recentOrders = [];
$lowStock = [];

if ($pdo) {
    try {
        // Today Revenue
        $s = $pdo->prepare("SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE order_status = 'delivered' AND DATE(created_at) = ?");
        $s->execute([$today]);
        $todayRev = (float)$s->fetchColumn();

        // Today Orders
        $s = $pdo->prepare("SELECT COUNT(*) FROM orders WHERE DATE(created_at) = ?");
        $s->execute([$today]);
        $todayOrdersCount = (int)$s->fetchColumn();

        // Pending Orders
        $pendingOrdersCount = (int)$pdo->query("SELECT COUNT(*) FROM orders WHERE order_status IN ('placed', 'confirmed')")->fetchColumn();

        // Active Riders
        $activeRidersCount = (int)$pdo->query("SELECT COUNT(*) FROM delivery_boys WHERE is_online = 1 AND is_active = 1")->fetchColumn();

        // Recent Orders
        $stmt = $pdo->query("SELECT o.*, d.name as rider_name FROM orders o LEFT JOIN delivery_boys d ON d.id = o.delivery_boy_id ORDER BY o.id DESC LIMIT 8");
        $recentOrders = $stmt->fetchAll();

        // Low Stock Products
        $stmt = $pdo->query("SELECT id, name, stock_qty, unit, price FROM products WHERE stock_qty <= 15 ORDER BY stock_qty ASC LIMIT 5");
        $lowStock = $stmt->fetchAll();
    } catch (Exception $e) {}
}
?>

<!-- KPI Cards -->
<div class="row g-3 mb-4">
    <div class="col-xl-3 col-sm-6">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between mb-3">
                <span class="text-muted fw-bold small text-uppercase">Today's Revenue</span>
                <div class="stat-icon-wrapper bg-success-subtle text-success">
                    <i class="fa-solid fa-money-bill-wave"></i>
                </div>
            </div>
            <h3 class="fw-bold mb-1">Rs <?= number_format($todayRev) ?></h3>
            <span class="small text-muted"><i class="fa-solid fa-arrow-up text-success me-1"></i>Delivered orders today</span>
        </div>
    </div>

    <div class="col-xl-3 col-sm-6">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between mb-3">
                <span class="text-muted fw-bold small text-uppercase">Today's Orders</span>
                <div class="stat-icon-wrapper bg-primary-subtle text-primary">
                    <i class="fa-solid fa-bag-shopping"></i>
                </div>
            </div>
            <h3 class="fw-bold mb-1"><?= $todayOrdersCount ?></h3>
            <span class="small text-muted">Total placed orders today</span>
        </div>
    </div>

    <div class="col-xl-3 col-sm-6">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between mb-3">
                <span class="text-muted fw-bold small text-uppercase">Pending Orders</span>
                <div class="stat-icon-wrapper bg-warning-subtle text-warning">
                    <i class="fa-solid fa-clock"></i>
                </div>
            </div>
            <h3 class="fw-bold mb-1 text-warning"><?= $pendingOrdersCount ?></h3>
            <span class="small text-muted">Awaiting confirmation</span>
        </div>
    </div>

    <div class="col-xl-3 col-sm-6">
        <div class="stat-card">
            <div class="d-flex align-items-center justify-content-between mb-3">
                <span class="text-muted fw-bold small text-uppercase">Active Fleet</span>
                <div class="stat-icon-wrapper bg-info-subtle text-info">
                    <i class="fa-solid fa-motorcycle"></i>
                </div>
            </div>
            <h3 class="fw-bold mb-1 text-info"><?= $activeRidersCount ?></h3>
            <span class="small text-muted">Riders currently online</span>
        </div>
    </div>
</div>

<div class="row g-4">
    <!-- Recent Orders Table -->
    <div class="col-xl-8">
        <div class="card border-0 shadow-sm rounded-4 overflow-hidden">
            <div class="card-header bg-white py-3 px-4 d-flex justify-content-between align-items-center border-bottom">
                <h6 class="fw-bold mb-0"><i class="fa-solid fa-receipt me-2 text-primary"></i>Recent Orders</h6>
                <a href="orders.php" class="btn btn-sm btn-light border fw-semibold">View All</a>
            </div>
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr class="small text-muted">
                            <th class="ps-4">Order #</th>
                            <th>Customer</th>
                            <th>Total</th>
                            <th>Status</th>
                            <th>Rider</th>
                            <th class="text-end pe-4">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($recentOrders)): ?>
                            <tr><td colspan="6" class="text-center py-4 text-muted">No orders found yet</td></tr>
                        <?php else: ?>
                            <?php foreach ($recentOrders as $ro): ?>
                                <?php
                                    $badgeClass = 'bg-secondary';
                                    if ($ro['order_status'] === 'placed') $badgeClass = 'bg-warning text-dark';
                                    elseif ($ro['order_status'] === 'confirmed') $badgeClass = 'bg-info text-dark';
                                    elseif ($ro['order_status'] === 'preparing') $badgeClass = 'bg-primary';
                                    elseif ($ro['order_status'] === 'on_the_way') $badgeClass = 'bg-info text-white';
                                    elseif ($ro['order_status'] === 'delivered') $badgeClass = 'bg-success';
                                    elseif ($ro['order_status'] === 'cancelled') $badgeClass = 'bg-danger';
                                ?>
                                <tr>
                                    <td class="ps-4 fw-bold">#<?= htmlspecialchars($ro['order_number']) ?></td>
                                    <td>
                                        <div class="fw-semibold"><?= htmlspecialchars($ro['customer_name'] ?: 'Customer') ?></div>
                                        <small class="text-muted"><?= htmlspecialchars($ro['customer_phone'] ?: '') ?></small>
                                    </td>
                                    <td class="fw-bold">Rs <?= number_format($ro['total_amount']) ?></td>
                                    <td><span class="badge <?= $badgeClass ?> rounded-pill text-uppercase px-2 py-1" style="font-size: 10px;"><?= $ro['order_status'] ?></span></td>
                                    <td>
                                        <?php if ($ro['rider_name']): ?>
                                            <span class="small fw-semibold"><i class="fa-solid fa-motorcycle text-success me-1"></i><?= htmlspecialchars($ro['rider_name']) ?></span>
                                        <?php else: ?>
                                            <span class="text-muted small">Unassigned</span>
                                        <?php endif; ?>
                                    </td>
                                    <td class="text-end pe-4">
                                        <a href="orders.php?search=<?= urlencode($ro['order_number']) ?>" class="btn btn-sm btn-outline-primary rounded-pill px-3">Manage</a>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Low Stock Alert -->
    <div class="col-xl-4">
        <div class="card border-0 shadow-sm rounded-4 overflow-hidden mb-4">
            <div class="card-header bg-white py-3 px-4 border-bottom d-flex justify-content-between align-items-center">
                <h6 class="fw-bold mb-0 text-danger"><i class="fa-solid fa-triangle-exclamation me-2"></i>Low Stock Watchlist</h6>
                <a href="products.php" class="btn btn-sm btn-light border fw-semibold">Products</a>
            </div>
            <div class="card-body p-0">
                <ul class="list-group list-group-flush">
                    <?php if (empty($lowStock)): ?>
                        <li class="list-group-item text-center py-4 text-muted small">All products well-stocked!</li>
                    <?php else: ?>
                        <?php foreach ($lowStock as $ls): ?>
                            <li class="list-group-item px-4 py-3 d-flex justify-content-between align-items-center">
                                <div>
                                    <div class="fw-semibold small"><?= htmlspecialchars($ls['name']) ?></div>
                                    <small class="text-muted">Rs <?= number_format($ls['price']) ?> / <?= htmlspecialchars($ls['unit']) ?></small>
                                </div>
                                <span class="badge bg-danger-subtle text-danger rounded-pill fw-bold">
                                    <?= $ls['stock_qty'] ?> left
                                </span>
                            </li>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </ul>
            </div>
        </div>

        <!-- Store Quick Actions Card -->
        <div class="card border-0 shadow-sm rounded-4 p-4 text-white" style="background: linear-gradient(135deg, #1E293B, #0F172A);">
            <h6 class="fw-bold mb-2"><i class="fa-solid fa-bolt me-2 text-warning"></i>Quick Store Actions</h6>
            <p class="small text-white-50 mb-3">
                Quickly manage inventory, dispatch delivery fleet, or configure store rules.
            </p>
            <div class="d-grid gap-2">
                <a href="products.php" class="btn btn-success btn-sm fw-bold rounded-3 py-2">
                    <i class="fa-solid fa-plus me-1"></i> Add New Product
                </a>
                <a href="orders.php" class="btn btn-primary btn-sm fw-bold rounded-3 py-2">
                    <i class="fa-solid fa-receipt me-1"></i> Process Orders
                </a>
                <a href="settings.php" class="btn btn-outline-light btn-sm fw-semibold rounded-3 py-2">
                    <i class="fa-solid fa-gear me-1"></i> Store & Profile Settings
                </a>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
