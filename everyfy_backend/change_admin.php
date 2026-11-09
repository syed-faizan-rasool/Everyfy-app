<?php
/**
 * 1-Click Admin Email & Password Updater
 * URL: https://everyfy.net/change_admin.php
 */

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/db.php';

$pdo = Database::getConnection();
$message = '';
$isSuccess = false;

// Fetch current admin
$currentEmail = 'admin@everyfy.net';
if ($pdo) {
    try {
        $stmt = $pdo->query("SELECT email FROM admins ORDER BY id ASC LIMIT 1");
        $res = $stmt->fetch();
        if ($res) {
            $currentEmail = $res['email'];
        }
    } catch (PDOException $e) {}
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_admin'])) {
    $newEmail    = trim($_POST['new_email'] ?? '');
    $newPassword = trim($_POST['new_password'] ?? '');
    $newName     = trim($_POST['new_name'] ?? 'Super Admin');

    if (empty($newEmail) || empty($newPassword)) {
        $message = 'Please provide both new email and new password!';
    } elseif (!filter_var($newEmail, FILTER_VALIDATE_EMAIL)) {
        $message = 'Invalid email address format!';
    } elseif (strlen($newPassword) < 6) {
        $message = 'Password must be at least 6 characters long!';
    } else {
        if (!$pdo) {
            $message = 'Database connection failed. Please check config/db.php.';
        } else {
            try {
                $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);

                // Check if admin exists, if not create, else update
                $stmt = $pdo->query("SELECT id FROM admins ORDER BY id ASC LIMIT 1");
                $admin = $stmt->fetch();

                if ($admin) {
                    $up = $pdo->prepare("UPDATE admins SET name = ?, email = ?, password = ? WHERE id = ?");
                    $up->execute([$newName, $newEmail, $hashedPassword, $admin['id']]);
                } else {
                    $ins = $pdo->prepare("INSERT INTO admins (name, email, password, role) VALUES (?, ?, ?, 'super_admin')");
                    $ins->execute([$newName, $newEmail, $hashedPassword]);
                }

                $message = "Admin credentials updated successfully! You can now log in with: $newEmail";
                $isSuccess = true;
                $currentEmail = $newEmail;
            } catch (PDOException $e) {
                $message = 'Database Error: ' . $e->getMessage();
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Admin Email & Password - Everyfy</title>
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
            padding: 20px;
        }
        .main-card {
            background: white;
            border-radius: 24px;
            max-width: 520px;
            width: 100%;
            padding: 40px 36px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
        }
        .btn-brand {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            color: white;
            font-weight: 700;
            border-radius: 14px;
            padding: 14px;
            border: none;
            width: 100%;
            font-size: 15px;
            transition: all 0.2s;
        }
        .btn-brand:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(16, 185, 129, 0.4);
            color: white;
        }
    </style>
</head>
<body>

<div class="main-card">
    <div class="text-center mb-4">
        <div class="bg-success text-white rounded-4 d-inline-flex p-3 mb-3 shadow">
            <i class="fa-solid fa-key fs-2"></i>
        </div>
        <h4 class="fw-bold text-dark mb-1">Change Admin Credentials</h4>
        <p class="text-secondary small mb-0">Set your personal Admin Email & Password</p>
    </div>

    <?php if (!empty($message)): ?>
        <div class="alert <?= $isSuccess ? 'alert-success' : 'alert-danger' ?> rounded-3 text-center small py-3 mb-4 shadow-sm">
            <i class="fa-solid <?= $isSuccess ? 'fa-circle-check' : 'fa-circle-exclamation' ?> me-2"></i>
            <?= htmlspecialchars($message) ?>
        </div>
    <?php endif; ?>

    <?php if ($isSuccess): ?>
        <div class="text-center">
            <a href="admin/login.php" class="btn btn-brand mb-2">
                <i class="fa-solid fa-right-to-bracket me-2"></i> Go to Admin Login
            </a>
            <p class="text-muted small mt-2">After checking, you can delete this file for security.</p>
        </div>
    <?php else: ?>
        <form method="POST" action="">
            <input type="hidden" name="update_admin" value="1">

            <div class="mb-3">
                <label class="form-label fw-semibold small text-muted">Admin Full Name</label>
                <div class="input-group">
                    <span class="input-group-text bg-light"><i class="fa-solid fa-user text-muted"></i></span>
                    <input type="text" name="new_name" class="form-control" value="Super Admin" required>
                </div>
            </div>

            <div class="mb-3">
                <label class="form-label fw-semibold small text-muted">New Admin Email (Login ID)</label>
                <div class="input-group">
                    <span class="input-group-text bg-light"><i class="fa-solid fa-envelope text-muted"></i></span>
                    <input type="email" name="new_email" class="form-control" placeholder="your_email@gmail.com" required
                           value="<?= htmlspecialchars($currentEmail) ?>">
                </div>
                <small class="text-muted" style="font-size: 11px;">Current: <code><?= htmlspecialchars($currentEmail) ?></code></small>
            </div>

            <div class="mb-4">
                <label class="form-label fw-semibold small text-muted">New Password</label>
                <div class="input-group">
                    <span class="input-group-text bg-light"><i class="fa-solid fa-lock text-muted"></i></span>
                    <input type="password" name="new_password" id="passInput" class="form-control" placeholder="Enter new strong password" required minlength="6">
                    <button class="btn btn-outline-secondary" type="button" onclick="togglePass()">
                        <i class="fa-regular fa-eye" id="passIcon"></i>
                    </button>
                </div>
                <small class="text-muted" style="font-size: 11px;">Minimum 6 characters</small>
            </div>

            <button type="submit" class="btn btn-brand">
                <i class="fa-solid fa-shield-check me-2"></i> Update Admin Account
            </button>
        </form>
    <?php endif; ?>
</div>

<script>
function togglePass() {
    const input = document.getElementById('passInput');
    const icon = document.getElementById('passIcon');
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

</body>
</html>
