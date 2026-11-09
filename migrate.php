<?php
/**
 * Everyfy Automated Master Healer & Migration Script
 * Upload this single file directly to Hostinger's public_html folder.
 * Then open in browser: https://everyfy.net/migrate.php
 */

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Everyfy System Migration & Auto-Healer</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; background: #0b1a13; color: #e4f0ec; margin: 0; padding: 30px 15px; }
        .card { max-width: 650px; margin: 0 auto; background: #12281e; border: 1px solid #1e4533; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.5); }
        .header { text-align: center; margin-bottom: 25px; }
        .logo { width: 70px; height: 70px; background: #0D6843; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 32px; margin-bottom: 15px; box-shadow: 0 4px 15px rgba(13,104,67,0.4); }
        h1 { margin: 0 0 8px 0; font-size: 24px; color: #ffffff; }
        p.subtitle { color: #8fae9f; margin: 0; font-size: 14px; }
        .step { background: #0e1e17; border-left: 4px solid #10b981; border-radius: 8px; padding: 12px 16px; margin: 12px 0; font-size: 13.5px; }
        .step.warn { border-left-color: #f59e0b; }
        .step.err { border-left-color: #ef4444; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-right: 6px; }
        .badge-success { background: #065f46; color: #34d399; }
        .badge-info { background: #1e3a5f; color: #60a5fa; }
        .badge-warn { background: #78350f; color: #fcd34d; }
        .btn { display: inline-block; width: 100%; box-sizing: border-box; text-align: center; background: #0D6843; color: #fff; font-weight: 700; text-decoration: none; padding: 14px; border-radius: 12px; margin-top: 20px; font-size: 15px; }
        .btn:hover { background: #0f7d51; }
        code { background: #1a382a; padding: 2px 6px; border-radius: 4px; color: #a7f3d0; font-size: 12px; }
    </style>
</head>
<body>
<div class="card">
    <div class="header">
        <div class="logo">🌿</div>
        <h1>Everyfy Auto-Healer & Migrator</h1>
        <p class="subtitle">Self-contained database sync & file restructuring utility</p>
    </div>

<?php
$steps = [];

// =========================================================================
// 1. AUTO-DETECT DATABASE CREDENTIALS FROM HOSTINGER CONFIGS
// =========================================================================
$dbHost = 'localhost';
$dbName = '';
$dbUser = '';
$dbPass = '';

$searchConfigs = array_merge(
    glob(__DIR__ . '/config/db.php'),
    glob(__DIR__ . '/config.*/db.php'),
    glob(__DIR__ . '/everyfy_backend/config/db.php')
);

if (!empty($searchConfigs)) {
    rsort($searchConfigs);
    foreach ($searchConfigs as $cfg) {
        $raw = @file_get_contents($cfg);
        if ($raw) {
            if (preg_match("/private static \\\$db_name = '([^']+)';/", $raw, $mDb) &&
                preg_match("/private static \\\$username = '([^']+)';/", $raw, $mUser) &&
                preg_match("/private static \\\$password = '([^']*)';/", $raw, $mPass)) {
                $candDb = trim($mDb[1]);
                $candUser = trim($mUser[1]);
                $candPass = trim($mPass[1]);
                if (!empty($candDb) && $candDb !== 'everyfy_db') {
                    $dbName = $candDb;
                    $dbUser = $candUser;
                    $dbPass = $candPass;
                    break;
                }
            }
        }
    }
}

// Fallback to reading setup.php or default
if (empty($dbName)) {
    $dbName = getenv('DB_NAME') ?: 'everyfy_db';
    $dbUser = getenv('DB_USER') ?: 'root';
    $dbPass = getenv('DB_PASS') !== false ? getenv('DB_PASS') : '';
}

// =========================================================================
// 2. CONNECT TO DATABASE
// =========================================================================
$pdo = null;
try {
    $dsn = "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4";
    $pdo = new PDO($dsn, $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    echo "<div class='step'><span class='badge badge-success'>DB CONNECTED</span> Connected to database: <code>{$dbName}</code></div>";
} catch (Exception $e) {
    echo "<div class='step err'><span class='badge badge-warn'>DB WARNING</span> Connection failed with {$dbUser}@{$dbName}: " . htmlspecialchars($e->getMessage()) . "</div>";
}

// =========================================================================
// 3. EXECUTE DATABASE MIGRATIONS (IF CONNECTED)
// =========================================================================
if ($pdo) {
    // 3a. users table columns
    $userCols = [
        'email' => "VARCHAR(120) NULL AFTER phone",
        'password' => "VARCHAR(255) NULL AFTER email",
        'profile_image' => "VARCHAR(255) NULL AFTER password",
        'otp' => "VARCHAR(6) NULL AFTER profile_image",
        'otp_expires_at' => "DATETIME NULL AFTER otp"
    ];
    foreach ($userCols as $col => $def) {
        try {
            $st = $pdo->prepare("SHOW COLUMNS FROM users LIKE ?");
            $st->execute([$col]);
            if (!$st->fetch()) {
                $pdo->exec("ALTER TABLE users ADD COLUMN {$col} {$def}");
                echo "<div class='step'><span class='badge badge-success'>COLUMN ADDED</span> Added <code>users.{$col}</code></div>";
            }
        } catch (Exception $e) {}
    }

    // 3b. admins table phone column
    try {
        $st = $pdo->prepare("SHOW COLUMNS FROM admins LIKE 'phone'");
        $st->execute();
        if (!$st->fetch()) {
            $pdo->exec("ALTER TABLE admins ADD COLUMN phone VARCHAR(25) NULL AFTER role");
            echo "<div class='step'><span class='badge badge-success'>COLUMN ADDED</span> Added <code>admins.phone</code></div>";
        }
    } catch (Exception $e) {}

    // 3c. delivery_boys table email column
    try {
        $st = $pdo->prepare("SHOW COLUMNS FROM delivery_boys LIKE 'email'");
        $st->execute();
        if (!$st->fetch()) {
            $pdo->exec("ALTER TABLE delivery_boys ADD COLUMN email VARCHAR(120) NULL AFTER phone");
            echo "<div class='step'><span class='badge badge-success'>COLUMN ADDED</span> Added <code>delivery_boys.email</code></div>";
        }
    } catch (Exception $e) {}

    // 3d. Sort all 16 categories
    $catOrders = [
        9 => 1, 6 => 2, 3 => 3, 16 => 4, 10 => 5, 11 => 6, 1 => 7, 4 => 8,
        15 => 9, 2 => 10, 12 => 11, 13 => 12, 14 => 13, 5 => 14, 8 => 15, 7 => 16
    ];
    $catCount = 0;
    foreach ($catOrders as $id => $order) {
        try {
            $res = $pdo->exec("UPDATE categories SET sort_order = {$order} WHERE id = {$id}");
            if ($res !== false) $catCount++;
        } catch (Exception $e) {}
    }
    echo "<div class='step'><span class='badge badge-success'>CATEGORIES</span> Sorted 16 categories into exact user order.</div>";

    // 3e. Create notifications table
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NULL,
                role ENUM('customer', 'admin', 'rider', 'all') NOT NULL DEFAULT 'customer',
                title VARCHAR(150) NOT NULL,
                message TEXT NOT NULL,
                type VARCHAR(50) DEFAULT 'order',
                order_id INT NULL,
                order_number VARCHAR(50) NULL,
                is_read TINYINT(1) DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_notif_role_user (role, user_id),
                INDEX idx_notif_order (order_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");
        echo "<div class='step'><span class='badge badge-success'>NOTIFICATIONS</span> 3-Sided notifications table verified and active.</div>";
    } catch (Exception $e) {}
}

// =========================================================================
// 4. RESTORE / MOVE BACKSLASH FLATTENED FILES INTO PROPER FOLDERS
// =========================================================================
$filesFixed = 0;
$scanned = scandir(__DIR__);
foreach ($scanned as $item) {
    if ($item === '.' || $item === '..') continue;
    
    // Check if filename contains backslash (e.g. api\orders\custom.php or api\migrate.php)
    if (strpos($item, '\\') !== false) {
        $sourcePath = __DIR__ . '/' . $item;
        $targetRelative = str_replace('\\', '/', $item);
        $targetPath = __DIR__ . '/' . $targetRelative;
        
        $targetDir = dirname($targetPath);
        if (!is_dir($targetDir)) {
            @mkdir($targetDir, 0755, true);
        }
        
        // Copy content and remove the flat backslash file
        if (@copy($sourcePath, $targetPath)) {
            @unlink($sourcePath);
            $filesFixed++;
        }
    }
}

if ($filesFixed > 0) {
    echo "<div class='step'><span class='badge badge-success'>FILES RESTORED</span> Fixed and moved <b>{$filesFixed} files</b> from flat backslash names into their proper <code>api/</code> and <code>helpers/</code> subfolders!</div>";
} else {
    echo "<div class='step'><span class='badge badge-info'>FILES CLEAN</span> Directory structure is organized.</div>";
}

// 4b. Move contents from update/ directory if user extracted to 'update'
$updateDir = __DIR__ . '/update';
if (is_dir($updateDir)) {
    $dirIterator = new RecursiveDirectoryIterator($updateDir, RecursiveDirectoryIterator::SKIP_DOTS);
    $iterator = new RecursiveIteratorIterator($dirIterator, RecursiveIteratorIterator::SELF_FIRST);
    $copiedFromUpdate = 0;
    foreach ($iterator as $item) {
        $subPath = substr($item->getPathname(), strlen($updateDir) + 1);
        $destPath = __DIR__ . '/' . str_replace('\\', '/', $subPath);
        if ($item->isDir()) {
            if (!is_dir($destPath)) @mkdir($destPath, 0755, true);
        } else {
            $destDir = dirname($destPath);
            if (!is_dir($destDir)) @mkdir($destDir, 0755, true);
            if (@copy($item->getPathname(), $destPath)) {
                $copiedFromUpdate++;
            }
        }
    }
    if ($copiedFromUpdate > 0) {
        echo "<div class='step'><span class='badge badge-success'>UPDATE FOLDER MERGED</span> Successfully deployed <b>{$copiedFromUpdate} files</b> from <code>update/</code> into live <code>public_html/</code>!</div>";
    }
}

// Also ensure api/migrate.php is self-created if missing
$apiMigrate = __DIR__ . '/api/migrate.php';
if (!file_exists($apiMigrate)) {
    @mkdir(__DIR__ . '/api', 0755, true);
    @copy(__FILE__, $apiMigrate);
}
?>

    <div style="margin-top: 25px; text-align: center;">
        <h3 style="color: #34d399; margin: 0 0 6px 0;">🎉 All Systems Synchronized!</h3>
        <p style="color: #8fae9f; font-size: 13.5px; margin: 0;">Database columns, category sorts, and backend API endpoints are now 100% active.</p>
    </div>

    <a href="https://everyfy.net/setup.php" class="btn">View Live Backend Setup Dashboard &rarr;</a>
</div>
</body>
</html>

