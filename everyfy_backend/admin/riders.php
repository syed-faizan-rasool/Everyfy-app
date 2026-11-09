<?php
$pageTitle = 'Delivery Fleet';
$pageHeading = 'Riders & Delivery Fleet';
require_once __DIR__ . '/includes/header.php';

$pdo = Database::getConnection();
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'add_rider') {
        $name          = trim($_POST['name'] ?? '');
        $phone         = trim($_POST['phone'] ?? '');
        $password      = trim($_POST['password'] ?? '1234');
        $cnic          = trim($_POST['cnic'] ?? '');
        $vehicleType   = trim($_POST['vehicle_type'] ?? 'Motorcycle');
        $vehicleNumber = trim($_POST['vehicle_number'] ?? '');

        $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
        $hashed = password_hash($password, PASSWORD_BCRYPT);

        try {
            $stmt = $pdo->prepare("INSERT INTO delivery_boys (name, phone, password, cnic, vehicle_type, vehicle_number, is_active, is_online) VALUES (?, ?, ?, ?, ?, ?, 1, 1)");
            $stmt->execute([$name, $cleanPhone, $hashed, $cnic, $vehicleType, $vehicleNumber]);
            $message = "Rider '{$name}' onboarded successfully!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    } elseif ($action === 'toggle_status') {
        $id = (int)($_POST['id'] ?? 0);
        try {
            $pdo->prepare("UPDATE delivery_boys SET is_active = IF(is_active = 1, 0, 1) WHERE id = ?")->execute([$id]);
            $message = "Rider status changed!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
}

$riders = [];
if ($pdo) {
    try {
        $stmt = $pdo->query("SELECT d.*, 
                                    (SELECT COUNT(*) FROM orders o WHERE o.delivery_boy_id = d.id AND o.order_status = 'delivered') as total_completed,
                                    (SELECT order_number FROM orders o WHERE o.delivery_boy_id = d.id AND o.order_status IN ('ready','picked_up','on_the_way') LIMIT 1) as current_order
                             FROM delivery_boys d ORDER BY d.id ASC");
        $riders = $stmt->fetchAll();
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
        <h5 class="fw-bold mb-0">Delivery Fleet (<?= count($riders) ?> Riders)</h5>
        <small class="text-muted">Live rider status, ratings, and vehicle dispatching</small>
    </div>
    <button class="btn btn-primary rounded-pill px-4" data-bs-toggle="modal" data-bs-target="#addRiderModal">
        <i class="fa-solid fa-plus me-2"></i> Onboard New Rider
    </button>
</div>

<!-- Riders Table -->
<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr class="small text-muted">
                    <th class="ps-4">Rider Name</th>
                    <th>Phone / Login</th>
                    <th>Vehicle</th>
                    <th>Rating</th>
                    <th>Duty Status</th>
                    <th>Current Order</th>
                    <th>Completed</th>
                    <th class="text-end pe-4">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($riders as $r): ?>
                    <tr>
                        <td class="ps-4">
                            <div class="d-flex align-items-center gap-3">
                                <div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center fw-bold" style="width: 40px; height: 40px;">
                                    <?= strtoupper(substr($r['name'], 0, 1)) ?>
                                </div>
                                <div>
                                    <div class="fw-bold"><?= htmlspecialchars($r['name']) ?></div>
                                    <small class="text-muted"><?= htmlspecialchars($r['cnic'] ?: 'CNIC on file') ?></small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="fw-semibold font-monospace small"><?= htmlspecialchars($r['phone']) ?></div>
                            <small class="text-muted">Pass: 1234</small>
                        </td>
                        <td>
                            <div class="small fw-semibold"><?= htmlspecialchars($r['vehicle_number']) ?></div>
                            <small class="text-muted"><?= htmlspecialchars($r['vehicle_type']) ?></small>
                        </td>
                        <td>
                            <span class="badge bg-warning-subtle text-dark fw-bold">
                                <i class="fa-solid fa-star text-warning me-1"></i><?= $r['rating'] ?>
                            </span>
                        </td>
                        <td>
                            <?php if ($r['current_order']): ?>
                                <span class="badge bg-primary-subtle text-primary py-1 px-2 fw-bold">
                                    <i class="fa-solid fa-route me-1"></i> On Delivery
                                </span>
                            <?php elseif ($r['is_online']): ?>
                                <span class="badge bg-success-subtle text-success py-1 px-2 fw-bold">
                                    <i class="fa-solid fa-circle me-1" style="font-size: 8px;"></i> Available
                                </span>
                            <?php else: ?>
                                <span class="badge bg-secondary-subtle text-muted py-1 px-2">Offline</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if ($r['current_order']): ?>
                                <span class="badge bg-dark">#<?= htmlspecialchars($r['current_order']) ?></span>
                            <?php else: ?>
                                <span class="text-muted small">&mdash;</span>
                            <?php endif; ?>
                        </td>
                        <td class="fw-bold"><?= $r['total_completed'] ?> trips</td>
                        <td class="text-end pe-4">
                            <form method="POST" class="d-inline">
                                <input type="hidden" name="action" value="toggle_status">
                                <input type="hidden" name="id" value="<?= $r['id'] ?>">
                                <button type="submit" class="btn btn-sm <?= $r['is_active'] ? 'btn-outline-danger' : 'btn-outline-success' ?> rounded-pill px-3">
                                    <?= $r['is_active'] ? 'Suspend' : 'Activate' ?>
                                </button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Add Rider Modal -->
<div class="modal fade" id="addRiderModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0">
            <div class="modal-header border-bottom">
                <h6 class="modal-title fw-bold">Onboard New Delivery Rider</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST">
                <div class="modal-body">
                    <input type="hidden" name="action" value="add_rider">

                    <div class="mb-3">
                        <label class="form-label small fw-bold">Full Name</label>
                        <input type="text" name="name" class="form-control" placeholder="e.g. Asad Mehmood" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-bold">Mobile Phone (Login)</label>
                        <input type="text" name="phone" class="form-control" placeholder="03001234567" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-bold">App Password</label>
                        <input type="password" name="password" class="form-control" value="1234" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label small fw-bold">CNIC Number</label>
                        <input type="text" name="cnic" class="form-control" placeholder="35201-1234567-1">
                    </div>

                    <div class="row g-2">
                        <div class="col-6">
                            <label class="form-label small fw-bold">Vehicle Model</label>
                            <input type="text" name="vehicle_type" class="form-control" value="Honda CD70">
                        </div>
                        <div class="col-6">
                            <label class="form-label small fw-bold">Number Plate</label>
                            <input type="text" name="vehicle_number" class="form-control" placeholder="LEB-4921" required>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-light rounded-3" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-3 px-4">Register Rider</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
