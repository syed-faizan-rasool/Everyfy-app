<?php
$pageTitle = 'Coupons';
$pageHeading = 'Discount Coupons';
require_once __DIR__ . '/includes/header.php';

$pdo = Database::getConnection();
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'add_coupon') {
        $code      = trim(strtoupper($_POST['code'] ?? ''));
        $type      = $_POST['discount_type'] ?? 'flat';
        $val       = (float)($_POST['value'] ?? 0);
        $minAmount = (float)($_POST['min_order_amount'] ?? 0);
        $expiry    = !empty($_POST['expiry_date']) ? $_POST['expiry_date'] : null;

        try {
            $stmt = $pdo->prepare("INSERT INTO coupons (code, discount_type, value, min_order_amount, expiry_date, is_active) VALUES (?, ?, ?, ?, ?, 1)");
            $stmt->execute([$code, $type, $val, $minAmount, $expiry]);
            $message = "Coupon '{$code}' created successfully!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    } elseif ($action === 'delete_coupon') {
        $id = (int)($_POST['id'] ?? 0);
        try {
            $pdo->prepare("DELETE FROM coupons WHERE id = ?")->execute([$id]);
            $message = "Coupon deleted!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
}

$coupons = [];
if ($pdo) {
    try {
        $coupons = $pdo->query("SELECT * FROM coupons ORDER BY id DESC")->fetchAll();
    } catch (Exception $e) {}
}
?>

<?php if (!empty($message)): ?>
    <div class="alert alert-success alert-dismissible fade show rounded-3 mb-4">
        <?= htmlspecialchars($message) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h5 class="fw-bold mb-0">Promo Coupons</h5>
        <small class="text-muted">Marketing discount codes and promotional offers</small>
    </div>
    <button class="btn btn-primary rounded-pill px-4" data-bs-toggle="modal" data-bs-target="#addCouponModal">
        <i class="fa-solid fa-plus me-2"></i> Create Coupon
    </button>
</div>

<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr class="small text-muted">
                    <th class="ps-4">Coupon Code</th>
                    <th>Discount</th>
                    <th>Min Cart Required</th>
                    <th>Expires</th>
                    <th>Times Used</th>
                    <th>Status</th>
                    <th class="text-end pe-4">Action</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($coupons as $c): ?>
                    <tr>
                        <td class="ps-4">
                            <span class="badge bg-primary-subtle text-primary fs-6 px-3 py-2 font-monospace fw-bold">
                                <?= htmlspecialchars($c['code']) ?>
                            </span>
                        </td>
                        <td class="fw-bold">
                            <?= $c['discount_type'] === 'percent' ? $c['value'] . '%' : 'Rs ' . number_format($c['value']) ?> OFF
                        </td>
                        <td>Rs <?= number_format($c['min_order_amount']) ?></td>
                        <td><?= $c['expiry_date'] ? date('M d, Y', strtotime($c['expiry_date'])) : '<span class="text-muted">No Expiry</span>' ?></td>
                        <td><span class="fw-semibold"><?= $c['times_used'] ?></span> times</td>
                        <td><?= $c['is_active'] ? '<span class="badge bg-success-subtle text-success">Active</span>' : '<span class="badge bg-secondary">Disabled</span>' ?></td>
                        <td class="text-end pe-4">
                            <form method="POST" class="d-inline" onsubmit="return confirm('Delete this coupon?');">
                                <input type="hidden" name="action" value="delete_coupon">
                                <input type="hidden" name="id" value="<?= $c['id'] ?>">
                                <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill px-3">Delete</button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Add Coupon Modal -->
<div class="modal fade" id="addCouponModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0">
            <div class="modal-header border-bottom">
                <h6 class="modal-title fw-bold">Create Discount Coupon</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST">
                <div class="modal-body">
                    <input type="hidden" name="action" value="add_coupon">

                    <div class="mb-3">
                        <label class="form-label small fw-bold">Promo Code</label>
                        <input type="text" name="code" class="form-control text-uppercase fw-bold" placeholder="e.g. SUMMER50" required>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label small fw-bold">Discount Type</label>
                            <select name="discount_type" class="form-select">
                                <option value="flat">Flat PKR Amount (Rs)</option>
                                <option value="percent">Percentage (%)</option>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="form-label small fw-bold">Discount Value</label>
                            <input type="number" step="0.01" name="value" class="form-control" placeholder="50" required>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label small fw-bold">Min Order Cart (Rs)</label>
                            <input type="number" step="0.01" name="min_order_amount" class="form-control" value="500">
                        </div>
                        <div class="col-6">
                            <label class="form-label small fw-bold">Expiry Date</label>
                            <input type="date" name="expiry_date" class="form-control" value="2027-12-31">
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-light rounded-3" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-3 px-4">Create Coupon</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
