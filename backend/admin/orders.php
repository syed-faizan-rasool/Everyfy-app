<?php
$pageTitle = 'Orders Management';
$pageHeading = 'Customer Orders';
require_once __DIR__ . '/includes/header.php';

$pdo = Database::getConnection();
$message = '';

// Handle Status & Rider Assignment POST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $orderId = (int)($_POST['order_id'] ?? 0);
    $action = $_POST['action'];

    if ($action === 'update_order') {
        $status = $_POST['status'] ?? null;
        $riderId = !empty($_POST['delivery_boy_id']) ? (int)$_POST['delivery_boy_id'] : null;

        try {
            $stmt = $pdo->prepare("UPDATE orders SET order_status = ?, delivery_boy_id = ? WHERE id = ?");
            $stmt->execute([$status, $riderId, $orderId]);

            $pdo->prepare("INSERT INTO order_status_history (order_id, status, notes, changed_by) VALUES (?, ?, 'Updated via Admin Panel', 'admin')")
                ->execute([$orderId, $status]);

            $message = "Order #{$orderId} updated successfully!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
}

// Filters
$filterStatus = $_GET['status'] ?? 'all';
$search = trim($_GET['search'] ?? '');

$where = [];
$params = [];

if ($filterStatus !== 'all' && !empty($filterStatus)) {
    $where[] = "o.order_status = ?";
    $params[] = $filterStatus;
}

if (!empty($search)) {
    $where[] = "(o.order_number LIKE ? OR o.customer_phone LIKE ? OR o.customer_name LIKE ?)";
    $params[] = "%{$search}%";
    $params[] = "%{$search}%";
    $params[] = "%{$search}%";
}

$whereClause = !empty($where) ? "WHERE " . implode(' AND ', $where) : "";

$orders = [];
$riders = [];
if ($pdo) {
    try {
        $stmt = $pdo->prepare("SELECT o.*, d.name as rider_name, d.phone as rider_phone FROM orders o LEFT JOIN delivery_boys d ON d.id = o.delivery_boy_id {$whereClause} ORDER BY o.id DESC");
        $stmt->execute($params);
        $orders = $stmt->fetchAll();

        // Get active riders for dropdown
        $riders = $pdo->query("SELECT id, name, vehicle_number, is_online FROM delivery_boys WHERE is_active = 1 ORDER BY name ASC")->fetchAll();
    } catch (Exception $e) {}
}
?>

<?php if (!empty($message)): ?>
    <div class="alert alert-success alert-dismissible fade show rounded-3 mb-4" role="alert">
        <?= htmlspecialchars($message) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<!-- Filter Tabs & Search -->
<div class="card border-0 shadow-sm rounded-4 mb-4">
    <div class="card-body p-3">
        <div class="row g-3 align-items-center">
            <div class="col-lg-8">
                <div class="d-flex flex-wrap gap-2">
                    <?php
                    $tabs = [
                        'all'        => 'All Orders',
                        'placed'     => 'Placed',
                        'preparing'  => 'Preparing',
                        'ready'      => 'Ready',
                        'on_the_way' => 'On the Way',
                        'delivered'  => 'Delivered',
                        'cancelled'  => 'Cancelled'
                    ];
                    foreach ($tabs as $key => $label):
                        $isActive = ($filterStatus === $key);
                    ?>
                        <a href="orders.php?status=<?= $key ?><?= !empty($search) ? '&search='.urlencode($search) : '' ?>"
                           class="btn btn-sm rounded-pill px-3 <?= $isActive ? 'btn-primary fw-bold' : 'btn-light border' ?>">
                            <?= $label ?>
                        </a>
                    <?php endforeach; ?>
                </div>
            </div>

            <div class="col-lg-4">
                <form method="GET" class="d-flex gap-2">
                    <?php if ($filterStatus !== 'all'): ?>
                        <input type="hidden" name="status" value="<?= htmlspecialchars($filterStatus) ?>">
                    <?php endif; ?>
                    <input type="text" name="search" class="form-control form-control-sm rounded-pill px-3" placeholder="Search order # or phone..." value="<?= htmlspecialchars($search) ?>">
                    <button type="submit" class="btn btn-sm btn-dark rounded-pill px-3"><i class="fa-solid fa-magnifying-glass"></i></button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Orders Table -->
<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr class="small text-muted">
                    <th class="ps-4">Order #</th>
                    <th>Customer Details</th>
                    <th>Delivery Address</th>
                    <th>Total (PKR)</th>
                    <th>Status</th>
                    <th>Assigned Rider</th>
                    <th class="text-end pe-4">Manage</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($orders)): ?>
                    <tr><td colspan="7" class="text-center py-5 text-muted">No orders matching this criteria</td></tr>
                <?php else: ?>
                    <?php foreach ($orders as $o): ?>
                        <tr>
                            <td class="ps-4">
                                <div class="fw-bold">#<?= htmlspecialchars($o['order_number']) ?></div>
                                <small class="text-muted"><?= date('M d, H:i', strtotime($o['created_at'])) ?></small>
                            </td>
                            <td>
                                <div class="fw-semibold"><?= htmlspecialchars($o['customer_name'] ?: 'Guest') ?></div>
                                <?php if (!empty($o['customer_phone'])): ?>
                                    <a href="tel:<?= preg_replace('/[^0-9+]/', '', $o['customer_phone']) ?>" class="small text-muted text-decoration-none">
                                        <i class="fa-solid fa-phone me-1 text-success"></i><?= htmlspecialchars($o['customer_phone']) ?>
                                    </a>
                                <?php endif; ?>
                            </td>
                            <td style="max-width: 220px;" class="small text-truncate" title="<?= htmlspecialchars($o['address_text']) ?>">
                                <?= htmlspecialchars($o['address_text']) ?>
                            </td>
                            <td class="fw-bold">
                                Rs <?= number_format($o['total_amount']) ?>
                                <div class="small fw-normal text-muted"><?= strtoupper($o['payment_method']) ?></div>
                            </td>
                            <td>
                                <span class="badge rounded-pill text-uppercase px-2 py-1 bg-secondary">
                                    <?= $o['order_status'] ?>
                                </span>
                            </td>
                            <td>
                                <?php if ($o['rider_name']): ?>
                                    <div class="d-flex align-items-center gap-2">
                                        <span class="badge bg-success-subtle text-success py-1 px-2">
                                            <i class="fa-solid fa-motorcycle me-1"></i><?= htmlspecialchars($o['rider_name']) ?>
                                        </span>
                                        <?php if (!empty($o['rider_phone'])): ?>
                                            <a href="tel:<?= preg_replace('/[^0-9+]/', '', $o['rider_phone']) ?>" class="btn btn-sm btn-outline-success rounded-circle p-1" style="width: 24px; height: 24px; display: inline-flex; align-items: center; justify-content: center;" title="Call Rider">
                                                <i class="fa-solid fa-phone" style="font-size: 10px;"></i>
                                            </a>
                                        <?php endif; ?>
                                    </div>
                                <?php else: ?>
                                    <span class="badge bg-warning-subtle text-warning">Unassigned</span>
                                <?php endif; ?>
                            </td>
                            <td class="text-end pe-4">
                                <button type="button" class="btn btn-sm btn-outline-primary rounded-pill px-3" data-bs-toggle="modal" data-bs-target="#editModal<?= $o['id'] ?>">
                                    Update
                                </button>
                            </td>
                        </tr>

                        <!-- Modal to Update Order -->
                        <div class="modal fade" id="editModal<?= $o['id'] ?>" tabindex="-1">
                            <div class="modal-dialog">
                                <div class="modal-content rounded-4 border-0">
                                    <div class="modal-header border-bottom">
                                        <h6 class="modal-title fw-bold">Manage Order #<?= htmlspecialchars($o['order_number']) ?></h6>
                                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                    </div>
                                    <form method="POST">
                                        <div class="modal-body">
                                            <input type="hidden" name="action" value="update_order">
                                            <input type="hidden" name="order_id" value="<?= $o['id'] ?>">

                                            <div class="mb-3">
                                                <label class="form-label small fw-bold">Order Status</label>
                                                <select name="status" class="form-select rounded-3">
                                                    <?php foreach (['placed', 'confirmed', 'preparing', 'ready', 'on_the_way', 'delivered', 'cancelled'] as $st): ?>
                                                        <option value="<?= $st ?>" <?= $o['order_status'] === $st ? 'selected' : '' ?>><?= strtoupper($st) ?></option>
                                                    <?php endforeach; ?>
                                                </select>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label small fw-bold">Assign Delivery Rider</label>
                                                <select name="delivery_boy_id" class="form-select rounded-3">
                                                    <option value="">-- No Rider Assigned --</option>
                                                    <?php foreach ($riders as $r): ?>
                                                        <option value="<?= $r['id'] ?>" <?= $o['delivery_boy_id'] == $r['id'] ? 'selected' : '' ?>>
                                                            <?= htmlspecialchars($r['name']) ?> (<?= $r['vehicle_number'] ?>) <?= $r['is_online'] ? '🟢' : '⚪' ?>
                                                        </option>
                                                    <?php endforeach; ?>
                                                </select>
                                            </div>

                                            <div class="p-3 bg-light rounded-3 small">
                                                <div><strong>Customer:</strong> <?= htmlspecialchars($o['customer_name']) ?> (<?= htmlspecialchars($o['customer_phone']) ?>)</div>
                                                <div><strong>Total:</strong> Rs <?= number_format($o['total_amount']) ?> (<?= strtoupper($o['payment_method']) ?>)</div>
                                                <div><strong>Address:</strong> <?= htmlspecialchars($o['address_text']) ?></div>
                                                <?php if (!empty($o['notes'])): ?>
                                                    <div><strong>Instructions:</strong> <?= htmlspecialchars($o['notes']) ?></div>
                                                <?php endif; ?>
                                            </div>
                                        </div>
                                        <div class="modal-footer border-0">
                                            <button type="button" class="btn btn-light rounded-3" data-bs-dismiss="modal">Cancel</button>
                                            <button type="submit" class="btn btn-primary rounded-3 px-4">Save Changes</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
