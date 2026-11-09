<?php
$pageTitle = 'Settings & Profile';
$pageHeading = 'Store & Admin Settings';
require_once __DIR__ . '/includes/header.php';

$pdo = Database::getConnection();
$adminId = $_SESSION['admin_id'] ?? 1;
$success = '';
$error = '';

// Fetch current admin profile
try {
    $stmt = $pdo->prepare("SELECT * FROM admins WHERE id = ? LIMIT 1");
    $stmt->execute([$adminId]);
    $admin = $stmt->fetch();
} catch (PDOException $e) {
    $admin = null;
}

// Fetch store settings from `settings` table
$settings = [];
try {
    $stmt = $pdo->query("SELECT `setting_key`, `setting_value` FROM settings");
    while ($row = $stmt->fetch()) {
        $settings[$row['setting_key']] = $row['setting_value'];
    }
} catch (PDOException $e) {}

$deliveryFee = $settings['delivery_fee'] ?? '100';
$freeDeliveryMin = $settings['free_delivery_threshold'] ?? '1000';
$storePhone = $settings['support_phone'] ?? '03001234567';
$storeName = $settings['store_name'] ?? 'Everyfy Grocery';
$operatingOpen = $settings['operating_hours_open'] ?? '08:00';
$operatingClose = $settings['operating_hours_close'] ?? '23:00';

// Handle Profile & Password Update
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action_profile'])) {
    $name            = trim($_POST['name'] ?? '');
    $email           = trim($_POST['email'] ?? '');
    $phone           = trim($_POST['phone'] ?? '');
    $newPassword     = trim($_POST['new_password'] ?? '');
    $confirmPassword = trim($_POST['confirm_password'] ?? '');

    if (empty($name) || empty($email)) {
        $error = 'Name and Email are required!';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = 'Please enter a valid email address!';
    } else {
        try {
            // Check if email taken by another admin
            $check = $pdo->prepare("SELECT id FROM admins WHERE email = ? AND id != ? LIMIT 1");
            $check->execute([$email, $adminId]);
            if ($check->fetch()) {
                $error = 'This email is already used by another account!';
            } else {
                if (!empty($newPassword)) {
                    if (strlen($newPassword) < 6) {
                        $error = 'Password must be at least 6 characters long!';
                    } elseif ($newPassword !== $confirmPassword) {
                        $error = 'New password and confirm password do not match!';
                    } else {
                        $hash = password_hash($newPassword, PASSWORD_BCRYPT);
                        $up = $pdo->prepare("UPDATE admins SET name = ?, email = ?, phone = ?, password = ? WHERE id = ?");
                        $up->execute([$name, $email, $phone, $hash, $adminId]);
                        $success = 'Admin profile and password updated successfully!';
                    }
                } else {
                    $up = $pdo->prepare("UPDATE admins SET name = ?, email = ?, phone = ? WHERE id = ?");
                    $up->execute([$name, $email, $phone, $adminId]);
                    $success = 'Admin profile updated successfully!';
                }

                if (empty($error)) {
                    $_SESSION['admin_name'] = $name;
                    $_SESSION['admin_email'] = $email;

                    // Refresh
                    $stmt = $pdo->prepare("SELECT * FROM admins WHERE id = ? LIMIT 1");
                    $stmt->execute([$adminId]);
                    $admin = $stmt->fetch();
                }
            }
        } catch (PDOException $e) {
            $error = 'Database Error: ' . $e->getMessage();
        }
    }
}

// Handle Store Settings Update
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action_store'])) {
    $newStoreName   = trim($_POST['store_name'] ?? 'Everyfy Grocery');
    $newDeliveryFee = trim($_POST['delivery_fee'] ?? '100');
    $newFreeMin     = trim($_POST['free_delivery_threshold'] ?? '1000');
    $newSupport     = trim($_POST['support_phone'] ?? '03001234567');

    try {
        $saveSetting = function($k, $v) use ($pdo) {
            $st = $pdo->prepare("INSERT INTO settings (`setting_key`, `setting_value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `setting_value` = ?");
            $st->execute([$k, $v, $v]);
        };

        $newOpen        = trim($_POST['operating_hours_open'] ?? '08:00');
        $newClose       = trim($_POST['operating_hours_close'] ?? '23:00');

        $saveSetting('store_name', $newStoreName);
        $saveSetting('delivery_fee', $newDeliveryFee);
        $saveSetting('free_delivery_threshold', $newFreeMin);
        $saveSetting('support_phone', $newSupport);
        $saveSetting('operating_hours_open', $newOpen);
        $saveSetting('operating_hours_close', $newClose);

        $storeName       = $newStoreName;
        $deliveryFee     = $newDeliveryFee;
        $freeDeliveryMin = $newFreeMin;
        $storePhone      = $newSupport;
        $operatingOpen   = $newOpen;
        $operatingClose  = $newClose;

        $success = 'Store configuration saved successfully!';
    } catch (PDOException $e) {
        $error = 'Could not save store settings: ' . $e->getMessage();
    }
}
?>

<div class="container-fluid px-0">
    <?php if (!empty($success)): ?>
        <div class="alert alert-success alert-dismissible fade show rounded-4 shadow-sm mb-4" role="alert">
            <i class="fa-solid fa-circle-check me-2"></i> <?= htmlspecialchars($success) ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <?php if (!empty($error)): ?>
        <div class="alert alert-danger alert-dismissible fade show rounded-4 shadow-sm mb-4" role="alert">
            <i class="fa-solid fa-triangle-exclamation me-2"></i> <?= htmlspecialchars($error) ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <div class="row g-4">
        <!-- Admin Profile & Security Card -->
        <div class="col-lg-7">
            <div class="card border-0 shadow-sm rounded-4 h-100">
                <div class="card-header bg-white border-bottom py-3 px-4 d-flex align-items-center gap-3">
                    <div class="bg-success text-white rounded-3 p-2">
                        <i class="fa-solid fa-user-shield fs-5"></i>
                    </div>
                    <div>
                        <h6 class="fw-bold mb-0">Admin Account & Credentials</h6>
                        <small class="text-muted">Edit login email, admin name and security password</small>
                    </div>
                </div>

                <div class="card-body p-4">
                    <form method="POST" action="">
                        <input type="hidden" name="action_profile" value="1">

                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold small text-secondary">Full Name</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-user text-muted"></i></span>
                                    <input type="text" name="name" class="form-control border-start-0" required
                                           value="<?= htmlspecialchars($admin['name'] ?? 'Syed Faizan Rasool') ?>">
                                </div>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label fw-semibold small text-secondary">Email Address (Login ID)</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-envelope text-muted"></i></span>
                                    <input type="email" name="email" class="form-control border-start-0" required
                                           value="<?= htmlspecialchars($admin['email'] ?? 'admin@everyfy.net') ?>">
                                </div>
                                <small class="text-muted" style="font-size: 11px;">Aap is email se Admin Panel me login karenge.</small>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label fw-semibold small text-secondary">Phone Number</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-phone text-muted"></i></span>
                                    <input type="text" name="phone" class="form-control border-start-0"
                                           value="<?= htmlspecialchars($admin['phone'] ?? '03001234567') ?>">
                                </div>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label fw-semibold small text-secondary">Account Role</label>
                                <input type="text" class="form-control bg-light" value="Super Admin" disabled>
                            </div>

                            <div class="col-12 mt-4 pt-3 border-top">
                                <h6 class="fw-bold mb-1"><i class="fa-solid fa-lock text-success me-2"></i>Change Password</h6>
                                <p class="text-muted small mb-3">Password change na karna ho to dono fields khali (blank) chor dein.</p>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label fw-semibold small text-secondary">New Password</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-key text-muted"></i></span>
                                    <input type="password" name="new_password" id="passInput1" class="form-control border-start-0" 
                                           placeholder="Min 6 characters">
                                    <button class="btn btn-outline-secondary" type="button" onclick="togglePass('passInput1', 'passIcon1')">
                                        <i class="fa-regular fa-eye" id="passIcon1"></i>
                                    </button>
                                </div>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label fw-semibold small text-secondary">Confirm New Password</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light border-end-0"><i class="fa-solid fa-lock text-muted"></i></span>
                                    <input type="password" name="confirm_password" id="passInput2" class="form-control border-start-0" 
                                           placeholder="Re-enter password">
                                    <button class="btn btn-outline-secondary" type="button" onclick="togglePass('passInput2', 'passIcon2')">
                                        <i class="fa-regular fa-eye" id="passIcon2"></i>
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div class="mt-4 pt-3 text-end border-top">
                            <button type="submit" class="btn btn-success px-4 fw-semibold rounded-3">
                                <i class="fa-solid fa-floppy-disk me-2"></i> Save Admin Profile
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Store Configuration Card -->
        <div class="col-lg-5">
            <div class="card border-0 shadow-sm rounded-4 h-100">
                <div class="card-header bg-white border-bottom py-3 px-4 d-flex align-items-center gap-3">
                    <div class="bg-primary text-white rounded-3 p-2">
                        <i class="fa-solid fa-store fs-5"></i>
                    </div>
                    <div>
                        <h6 class="fw-bold mb-0">Grocery Store Settings</h6>
                        <small class="text-muted">Delivery fees and store settings</small>
                    </div>
                </div>

                <div class="card-body p-4">
                    <form method="POST" action="">
                        <input type="hidden" name="action_store" value="1">

                        <div class="mb-3">
                            <label class="form-label fw-semibold small text-secondary">Store Display Name</label>
                            <input type="text" name="store_name" class="form-control" required
                                   value="<?= htmlspecialchars($storeName) ?>">
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold small text-secondary">Standard Delivery Fee (Rs)</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light">Rs</span>
                                <input type="number" step="10" name="delivery_fee" class="form-control" required
                                       value="<?= htmlspecialchars($deliveryFee) ?>">
                            </div>
                            <small class="text-muted" style="font-size: 11px;">Default delivery charges per order</small>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold small text-secondary">Free Delivery Threshold (Rs)</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light">Rs</span>
                                <input type="number" step="50" name="free_delivery_threshold" class="form-control" required
                                       value="<?= htmlspecialchars($freeDeliveryMin) ?>">
                            </div>
                            <small class="text-muted" style="font-size: 11px;">Orders above this amount get free delivery</small>
                        </div>

                        <div class="mb-4">
                            <label class="form-label fw-semibold small text-secondary">Customer Support Helpline</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light"><i class="fa-solid fa-headset text-muted"></i></span>
                                <input type="text" name="support_phone" class="form-control" required
                                       value="<?= htmlspecialchars($storePhone) ?>">
                            </div>
                        </div>

                        <div class="mb-4">
                            <label class="form-label fw-semibold small text-secondary">
                                <i class="fa-solid fa-clock text-primary me-1"></i> Store Operating Hours (Timer)
                            </label>
                            <div class="row g-2">
                                <div class="col-6">
                                    <small class="text-muted d-block mb-1">Opening Time</small>
                                    <div class="input-group">
                                        <span class="input-group-text bg-light"><i class="fa-regular fa-clock text-muted"></i></span>
                                        <input type="time" name="operating_hours_open" class="form-control" value="<?= htmlspecialchars($operatingOpen) ?>" required>
                                    </div>
                                </div>
                                <div class="col-6">
                                    <small class="text-muted d-block mb-1">Closing Time</small>
                                    <div class="input-group">
                                        <span class="input-group-text bg-light"><i class="fa-solid fa-clock text-muted"></i></span>
                                        <input type="time" name="operating_hours_close" class="form-control" value="<?= htmlspecialchars($operatingClose) ?>" required>
                                    </div>
                                </div>
                            </div>
                            <small class="text-muted" style="font-size: 11px;">Customer orders are accepted within this daily schedule.</small>
                        </div>

                        <div class="pt-3 text-end border-top">
                            <button type="submit" class="btn btn-primary px-4 fw-semibold rounded-3">
                                <i class="fa-solid fa-check me-2"></i> Save Store Settings
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function togglePass(inputId, iconId) {
    const input = document.getElementById(inputId);
    const icon = document.getElementById(iconId);
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
