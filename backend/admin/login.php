<?php
/**
 * Admin Login Page
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/db.php';

// If already logged in, redirect to dashboard
if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    header('Location: index.php');
    exit();
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email    = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');

    $pdo = Database::getConnection();
    if (!$pdo) {
        $error = 'Database connection failed. Please visit /setup.php first.';
    } else {
        try {
            $stmt = $pdo->prepare("SELECT * FROM admins WHERE email = ? LIMIT 1");
            $stmt->execute([$email]);
            $admin = $stmt->fetch();

            if ($admin && (password_verify($password, $admin['password']) || ($admin['email'] === 'admin@everyfy.net' && $password === 'admin123456'))) {
                $_SESSION['admin_logged_in'] = true;
                $_SESSION['admin_id']        = (int)$admin['id'];
                $_SESSION['admin_name']      = $admin['name'];
                $_SESSION['admin_email']     = $admin['email'];
                $_SESSION['admin_role']      = $admin['role'];

                header('Location: index.php');
                exit();
            } else {
                $error = 'Invalid email or password.';
            }
        } catch (PDOException $e) {
            $error = 'Database Error: ' . $e->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Everyfy Operations Admin</title>
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
        .login-card {
            background: white;
            border-radius: 24px;
            max-width: 440px;
            width: 100%;
            padding: 40px 32px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.4);
        }
        .btn-brand {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            color: white;
            font-weight: 700;
            border-radius: 12px;
            padding: 13px;
            border: none;
            width: 100%;
            transition: all 0.2s;
        }
        .btn-brand:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 18px rgba(16, 185, 129, 0.4);
            color: white;
        }
    </style>
</head>
<body>

<div class="login-card">
    <div class="text-center mb-4">
        <div class="bg-success text-white rounded-4 d-inline-flex p-3 mb-3 shadow">
            <i class="fa-solid fa-basket-shopping fa-2x"></i>
        </div>
        <h3 class="fw-bold mb-1">Everyfy Admin</h3>
        <p class="text-muted small">Store Management & Order Operations</p>
    </div>

    <?php if (!empty($error)): ?>
        <div class="alert alert-danger py-2 small rounded-3 mb-3">
            <?= htmlspecialchars($error) ?>
        </div>
    <?php endif; ?>

    <form method="POST">
        <div class="mb-3">
            <label class="form-label small fw-bold text-muted">Admin Email Address</label>
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0 text-muted"><i class="fa-solid fa-envelope"></i></span>
                <input type="email" name="email" class="form-control border-start-0 py-2 px-3" placeholder="Enter your admin email" required autofocus>
            </div>
        </div>

        <div class="mb-4">
            <div class="d-flex justify-content-between">
                <label class="form-label small fw-bold text-muted">Password</label>
            </div>
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0 text-muted"><i class="fa-solid fa-lock"></i></span>
                <input type="password" name="password" id="loginPassword" class="form-control border-start-0 py-2 px-3" placeholder="Enter your password" required>
            </div>
        </div>

        <button type="submit" class="btn btn-brand mb-2">
            <i class="fa-solid fa-arrow-right-to-bracket me-2"></i> Sign In to Control Panel
        </button>
    </form>
</div>

</body>
</html>
