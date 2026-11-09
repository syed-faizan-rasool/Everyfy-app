<?php
/**
 * Everyfy Automated Setup & Database Installer
 * Run via browser: https://everyfy.net/setup.php
 */

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/db.php';

$message = '';
$messageType = '';
$step = 'check';

// Handle Form Submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'save_config') {
        $dbHost = trim($_POST['db_host'] ?? 'localhost');
        $dbName = trim($_POST['db_name'] ?? '');
        $dbUser = trim($_POST['db_user'] ?? '');
        $dbPass = trim($_POST['db_pass'] ?? '');

        if (empty($dbName) || empty($dbUser)) {
            $message = 'Database name and database username are required!';
            $messageType = 'danger';
        } else {
            // Test connection first
            try {
                $testPdo = new PDO("mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4", $dbUser, $dbPass, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
                ]);

                // Write into config/db.php
                $dbConfigFile = __DIR__ . '/config/db.php';
                $dbConfigContent = file_get_contents($dbConfigFile);

                $dbConfigContent = preg_replace("/private static \\\$host = '.*?';/", "private static \$host = '{$dbHost}';", $dbConfigContent);
                $dbConfigContent = preg_replace("/private static \\\$db_name = '.*?';/", "private static \$db_name = '{$dbName}';", $dbConfigContent);
                $dbConfigContent = preg_replace("/private static \\\$username = '.*?';/", "private static \$username = '{$dbUser}';", $dbConfigContent);
                $dbConfigContent = preg_replace("/private static \\\$password = '.*?';/", "private static \$password = '{$dbPass}';", $dbConfigContent);

                file_put_contents($dbConfigFile, $dbConfigContent);

                $message = 'Database connection verified and config saved successfully!';
                $messageType = 'success';
                $step = 'install';
            } catch (PDOException $e) {
                $message = 'Connection Failed: ' . htmlspecialchars($e->getMessage());
                $messageType = 'danger';
            }
        }
    } elseif ($action === 'install_db') {
        $sqlFile = __DIR__ . '/database/everyfy_db.sql';
        if (!file_exists($sqlFile)) {
            $message = 'SQL schema file not found in database/everyfy_db.sql';
            $messageType = 'danger';
        } else {
            $pdo = Database::getConnection();
            if (!$pdo) {
                $message = 'Cannot connect to database. Please check credentials first.';
                $messageType = 'danger';
            } else {
                try {
                    $sql = file_get_contents($sqlFile);
                    $pdo->exec($sql);

                    // Ensure delivery_boys has email column
                    try {
                        $pdo->exec("ALTER TABLE delivery_boys ADD COLUMN email VARCHAR(120) NULL UNIQUE AFTER phone;");
                    } catch (Exception $e) {}

                    // If custom admin credentials provided during installation
                    $adminEmail = trim($_POST['admin_email'] ?? '');
                    $adminPass  = trim($_POST['admin_pass'] ?? '');
                    $adminName  = trim($_POST['admin_name'] ?? 'Super Admin');

                    if (!empty($adminEmail) && !empty($adminPass)) {
                        $hash = password_hash($adminPass, PASSWORD_BCRYPT);
                        $stmt = $pdo->prepare("UPDATE admins SET name = ?, email = ?, password = ? WHERE id = 1");
                        $stmt->execute([$adminName, $adminEmail, $hash]);
                    }

                    $message = 'Clean database tables imported successfully without any dummy accounts!';
                    $messageType = 'success';
                    $step = 'complete';
                } catch (PDOException $e) {
                    $message = 'Import failed: ' . htmlspecialchars($e->getMessage());
                    $messageType = 'danger';
                }
            }
        }
    } elseif ($action === 'wipe_dummy_data') {
        $pdo = Database::getConnection();
        if ($pdo) {
            try {
                $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");
                $pdo->exec("TRUNCATE TABLE users;");
                $pdo->exec("TRUNCATE TABLE addresses;");
                $pdo->exec("TRUNCATE TABLE delivery_boys;");
                $pdo->exec("TRUNCATE TABLE orders;");
                $pdo->exec("TRUNCATE TABLE order_items;");
                $pdo->exec("TRUNCATE TABLE order_status_history;");
                $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

                // Ensure email column exists in delivery_boys table
                try {
                    $pdo->exec("ALTER TABLE delivery_boys ADD COLUMN email VARCHAR(120) NULL UNIQUE AFTER phone;");
                } catch (Exception $e) {}

                $message = 'All dummy customer accounts, dummy riders, and dummy orders have been permanently wiped!';
                $messageType = 'success';
            } catch (PDOException $e) {
                $message = 'Wipe failed: ' . htmlspecialchars($e->getMessage());
                $messageType = 'danger';
            }
        }
    } elseif ($action === 'save_admin') {
        $pdo = Database::getConnection();
        $adminName  = trim($_POST['admin_name'] ?? 'Super Admin');
        $adminEmail = trim($_POST['admin_email'] ?? '');
        $adminPass  = trim($_POST['admin_pass'] ?? '');

        if (empty($adminEmail) || empty($adminPass)) {
            $message = 'Admin email and password are required!';
            $messageType = 'danger';
        } elseif ($pdo) {
            try {
                $hash = password_hash($adminPass, PASSWORD_BCRYPT);
                $stmt = $pdo->query("SELECT id FROM admins ORDER BY id ASC LIMIT 1");
                $row = $stmt->fetch();

                if ($row) {
                    $up = $pdo->prepare("UPDATE admins SET name = ?, email = ?, password = ? WHERE id = ?");
                    $up->execute([$adminName, $adminEmail, $hash, $row['id']]);
                } else {
                    $ins = $pdo->prepare("INSERT INTO admins (name, email, password, role) VALUES (?, ?, ?, 'super_admin')");
                    $ins->execute([$adminName, $adminEmail, $hash]);
                }

                $message = "Admin credentials updated! You can now log in with email: {$adminEmail}";
                $messageType = 'success';
            } catch (PDOException $e) {
                $message = 'Admin update failed: ' . htmlspecialchars($e->getMessage());
                $messageType = 'danger';
            }
        }
    }
}

// Current status
$pdo = Database::getConnection();
$isConnected = ($pdo !== null);

$tableCount = 0;
$adminCount = 0;
$customerCount = 0;
$riderCount = 0;
$orderCount = 0;
$activeAdminEmail = 'admin@everyfy.net';

if ($isConnected) {
    try {
        $stmt = $pdo->query("SHOW TABLES");
        $tableCount = count($stmt->fetchAll());

        if ($tableCount >= 5) {
            $adminCount = (int)$pdo->query("SELECT COUNT(*) FROM admins")->fetchColumn();
            $customerCount = (int)$pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
            $riderCount = (int)$pdo->query("SELECT COUNT(*) FROM delivery_boys")->fetchColumn();
            $orderCount = (int)$pdo->query("SELECT COUNT(*) FROM orders")->fetchColumn();

            $adminRow = $pdo->query("SELECT email FROM admins ORDER BY id ASC LIMIT 1")->fetch();
            if ($adminRow) {
                $activeAdminEmail = $adminRow['email'];
            }

            if ($step !== 'complete') {
                $step = 'already_installed';
            }
        } elseif ($step !== 'complete') {
            $step = 'install';
        }
    } catch (Exception $e) {}
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Everyfy Backend Setup & Database Wizard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #334155;
            padding: 30px 15px;
        }
        .setup-card {
            background: #FFFFFF;
            border-radius: 24px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.35);
            max-width: 680px;
            width: 100%;
            overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .setup-header {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            padding: 35px 30px;
            color: white;
            text-align: center;
        }
        .setup-header h1 {
            font-size: 26px;
            font-weight: 800;
            margin: 0;
            letter-spacing: -0.5px;
        }
        .setup-body {
            padding: 35px 30px;
        }
        .form-control {
            border-radius: 12px;
            padding: 12px 16px;
            border: 1.5px solid #E2E8F0;
            font-size: 15px;
        }
        .form-control:focus {
            border-color: #10B981;
            box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.15);
        }
        .btn-brand {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            color: white;
            font-weight: 700;
            border-radius: 12px;
            padding: 14px 24px;
            border: none;
            width: 100%;
            font-size: 16px;
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
            transition: all 0.2s;
        }
        .btn-brand:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 18px rgba(16, 185, 129, 0.4);
            color: white;
        }
        .badge-status {
            padding: 8px 14px;
            border-radius: 50px;
            font-weight: 700;
            font-size: 13px;
        }
        .card-info {
            background: #F8FAFC;
            border-radius: 16px;
            padding: 20px;
            border: 1px solid #E2E8F0;
        }
        .stat-badge {
            background: white;
            border: 1px solid #E2E8F0;
            border-radius: 12px;
            padding: 10px 14px;
            text-align: center;
        }
    </style>
</head>
<body>

<div class="setup-card">
    <div class="setup-header">
        <div class="mb-2">
            <i class="fa-solid fa-basket-shopping fa-2x"></i>
        </div>
        <h1>Everyfy Backend Installation</h1>
        <p class="mb-0 text-white-50 mt-1">Hostinger Server & MySQL Database Setup Wizard</p>
    </div>

    <div class="setup-body">
        <?php if (!empty($message)): ?>
            <div class="alert alert-<?= $messageType ?> alert-dismissible fade show rounded-3" role="alert">
                <?= $message ?>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        <?php endif; ?>

        <!-- DB Connection Status Card -->
        <div class="d-flex justify-content-between align-items-center card-info mb-4">
            <div>
                <h6 class="fw-bold mb-1"><i class="fa-solid fa-database me-2 text-primary"></i>MySQL Database Status</h6>
                <small class="text-muted">Domain: <strong>everyfy.net</strong></small>
            </div>
            <div>
                <?php if ($isConnected): ?>
                    <span class="badge-status bg-success-subtle text-success">
                        <i class="fa-solid fa-circle-check me-1"></i> Connected
                    </span>
                <?php else: ?>
                    <span class="badge-status bg-danger-subtle text-danger">
                        <i class="fa-solid fa-circle-xmark me-1"></i> Disconnected
                    </span>
                <?php endif; ?>
            </div>
        </div>

        <?php if ($isConnected && $step === 'already_installed'): ?>
            <div class="py-2">
                <!-- Live Stats -->
                <div class="row g-2 mb-4">
                    <div class="col-6 col-md-3">
                        <div class="stat-badge">
                            <small class="text-muted d-block">Admins</small>
                            <span class="fw-bold fs-5 text-dark"><?= $adminCount ?></span>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="stat-badge">
                            <small class="text-muted d-block">Customers</small>
                            <span class="fw-bold fs-5 text-primary"><?= $customerCount ?></span>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="stat-badge">
                            <small class="text-muted d-block">Riders</small>
                            <span class="fw-bold fs-5 text-success"><?= $riderCount ?></span>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="stat-badge">
                            <small class="text-muted d-block">Live Orders</small>
                            <span class="fw-bold fs-5 text-warning"><?= $orderCount ?></span>
                        </div>
                    </div>
                </div>

                <div class="card-info mb-4">
                    <h6 class="fw-bold mb-2"><i class="fa-solid fa-shield-halved me-2 text-success"></i>Current Admin Account</h6>
                    <p class="mb-0 small text-muted">Login Email: <strong class="text-dark"><?= htmlspecialchars($activeAdminEmail) ?></strong></p>
                </div>

                <!-- Update Admin Credentials Form -->
                <div class="card-info mb-4">
                    <h6 class="fw-bold mb-3"><i class="fa-solid fa-user-gear me-2 text-primary"></i>Update Admin Email & Password</h6>
                    <form method="POST">
                        <input type="hidden" name="action" value="save_admin">
                        <div class="mb-2">
                            <label class="form-label small fw-bold text-muted">Admin Name</label>
                            <input type="text" name="admin_name" class="form-control form-control-sm" value="Super Admin" required>
                        </div>
                        <div class="mb-2">
                            <label class="form-label small fw-bold text-muted">Admin Email</label>
                            <input type="email" name="admin_email" class="form-control form-control-sm" value="<?= htmlspecialchars($activeAdminEmail) ?>" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">New Admin Password</label>
                            <input type="password" name="admin_pass" class="form-control form-control-sm" placeholder="Enter new strong password" required>
                        </div>
                        <button type="submit" class="btn btn-primary btn-sm rounded-3 fw-bold w-100 py-2">
                            <i class="fa-solid fa-check me-1"></i> Save Admin Credentials
                        </button>
                    </form>
                </div>

                <!-- Wipe Dummy Accounts & Orders Button -->
                <div class="card-info mb-4 border-danger-subtle bg-danger-subtle bg-opacity-10">
                    <h6 class="fw-bold text-danger mb-2"><i class="fa-solid fa-trash-can me-2"></i>Wipe Dummy Accounts & Test Data</h6>
                    <p class="small text-muted mb-3">
                        This will permanently delete any dummy riders, demo customers, and dummy orders. Products and categories catalog will remain intact.
                    </p>
                    <form method="POST" onsubmit="return confirm('Are you sure you want to delete all dummy accounts and fake orders? Real signups will now start fresh.');">
                        <input type="hidden" name="action" value="wipe_dummy_data">
                        <button type="submit" class="btn btn-outline-danger btn-sm rounded-3 fw-bold w-100 py-2">
                            <i class="fa-solid fa-broom me-1"></i> Wipe All Dummy Data Now
                        </button>
                    </form>
                </div>

                <div class="d-grid gap-2">
                    <a href="admin/login.php" class="btn btn-brand">
                        <i class="fa-solid fa-gauge me-2"></i> Open Web Admin Panel
                    </a>
                    <a href="api/index.php" class="btn btn-outline-secondary rounded-3 py-2 fw-semibold">
                        <i class="fa-solid fa-network-wired me-2"></i> Test Live REST APIs
                    </a>
                </div>
            </div>

        <?php elseif ($isConnected): ?>
            <!-- Ready to Install Clean Database Schema -->
            <div class="text-center py-2 mb-4">
                <h5 class="fw-bold">Connection Established!</h5>
                <p class="text-muted small">
                    Click the button below to create all tables without any fake accounts or dummy orders.
                </p>
                <form method="POST" class="text-start card-info mb-3">
                    <input type="hidden" name="action" value="install_db">
                    <h6 class="fw-bold mb-3"><i class="fa-solid fa-user-shield me-2 text-primary"></i>Set Your Admin Account</h6>
                    <div class="mb-2">
                        <label class="form-label small fw-bold text-muted">Admin Full Name</label>
                        <input type="text" name="admin_name" class="form-control form-control-sm" value="Super Admin" required>
                    </div>
                    <div class="mb-2">
                        <label class="form-label small fw-bold text-muted">Admin Email Address</label>
                        <input type="email" name="admin_email" class="form-control form-control-sm" placeholder="e.g. yourname@gmail.com" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-bold text-muted">Admin Password</label>
                        <input type="password" name="admin_pass" class="form-control form-control-sm" placeholder="Enter your chosen password" required>
                    </div>
                    <button type="submit" class="btn btn-brand">
                        <i class="fa-solid fa-cloud-arrow-up me-2"></i> Import Clean Database & Create Admin
                    </button>
                </form>
            </div>

        <?php else: ?>
            <!-- Form to Configure Database Credentials -->
            <form method="POST">
                <input type="hidden" name="action" value="save_config">
                <h5 class="fw-bold mb-3">Configure Hostinger Database</h5>
                <p class="text-muted small mb-3">
                    In your Hostinger hPanel, go to <strong>Databases &gt; MySQL Databases</strong> to create your database, then enter the details below:
                </p>

                <div class="mb-3">
                    <label class="form-label fw-bold small text-muted">MySQL Host</label>
                    <input type="text" name="db_host" class="form-control" value="localhost" required>
                    <div class="form-text">Usually <code>localhost</code> on Hostinger</div>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-bold small text-muted">Database Name</label>
                    <input type="text" name="db_name" class="form-control" placeholder="e.g. u123456789_everyfy" required>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-bold small text-muted">Database Username</label>
                    <input type="text" name="db_user" class="form-control" placeholder="e.g. u123456789_admin" required>
                </div>

                <div class="mb-4">
                    <label class="form-label fw-bold small text-muted">Database Password</label>
                    <input type="password" name="db_pass" class="form-control" placeholder="Database password">
                </div>

                <button type="submit" class="btn btn-brand">
                    <i class="fa-solid fa-plug me-2"></i> Test Connection & Save Settings
                </button>
            </form>
        <?php endif; ?>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
