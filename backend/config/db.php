<?php
/**
 * Database Connection using PDO
 * Optimized for Hostinger Shared/Cloud Hosting & LiteSpeed/Apache
 * Includes auto-recovery from Hostinger backup folders and seamless schema migrations.
 */

require_once __DIR__ . '/config.php';

class Database {
    // -------------------------------------------------------------
    // ENTER YOUR HOSTINGER DATABASE CREDENTIALS HERE:
    // (You can create this in Hostinger hPanel -> Databases -> MySQL Databases)
    // -------------------------------------------------------------
    private static $host = 'localhost';
    private static $db_name = 'everyfy_db';       // e.g. u576554331_everyfy
    private static $username = 'root';             // e.g. u576554331_user
    private static $password = '';                 // e.g. your_db_password
    private static $port = '3306';
    private static $charset = 'utf8mb4';

    private static $instance = null;
    private static $connectionError = null;

    /**
     * Get singleton PDO connection
     * @return PDO|null
     */
    public static function getConnection() {
        if (self::$instance === null) {
            $host = getenv('DB_HOST') ?: self::$host;
            $db   = getenv('DB_NAME') ?: self::$db_name;
            $user = getenv('DB_USER') ?: self::$username;
            $pass = getenv('DB_PASS') !== false ? getenv('DB_PASS') : self::$password;
            $port = getenv('DB_PORT') ?: self::$port;

            $dsn = "mysql:host={$host};port={$port};dbname={$db};charset=" . self::$charset;
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ];

            try {
                self::$instance = new PDO($dsn, $user, $pass, $options);
            } catch (PDOException $e) {
                // Auto-recovery: If default credentials failed, check Hostinger automatic backup config folders
                $recovered = false;
                $backupFolders = glob(dirname(__DIR__) . '/config.*/db.php');
                if (!empty($backupFolders)) {
                    rsort($backupFolders); // Newest backup first
                    foreach ($backupFolders as $backupFile) {
                        $bContent = @file_get_contents($backupFile);
                        if ($bContent &&
                            preg_match("/private static \\\$db_name = '([^']+)';/", $bContent, $mDb) &&
                            preg_match("/private static \\\$username = '([^']+)';/", $bContent, $mUser) &&
                            preg_match("/private static \\\$password = '([^']*)';/", $bContent, $mPass)) {
                            $bDb = trim($mDb[1]);
                            $bUser = trim($mUser[1]);
                            $bPass = trim($mPass[1]);
                            if ($bDb !== 'everyfy_db' && !empty($bDb) && !empty($bUser)) {
                                try {
                                    $testDsn = "mysql:host={$host};port={$port};dbname={$bDb};charset=" . self::$charset;
                                    $recPdo = new PDO($testDsn, $bUser, $bPass, $options);
                                    self::$instance = $recPdo;
                                    
                                    // Persist recovered credentials back to current db.php
                                    $selfContent = @file_get_contents(__FILE__);
                                    if ($selfContent) {
                                        $selfContent = preg_replace("/private static \\\$db_name = '.*?';/", "private static \$db_name = '{$bDb}';", $selfContent);
                                        $selfContent = preg_replace("/private static \\\$username = '.*?';/", "private static \$username = '{$bUser}';", $selfContent);
                                        $selfContent = preg_replace("/private static \\\$password = '.*?';/", "private static \$password = '{$bPass}';", $selfContent);
                                        @file_put_contents(__FILE__, $selfContent);
                                    }
                                    $recovered = true;
                                    break;
                                } catch (Throwable $ignore) {}
                            }
                        }
                    }
                }

                if (!$recovered) {
                    self::$connectionError = $e->getMessage();
                    return null;
                }
            }

            // Once connection is established, ensure full schema and category sorting compatibility
            if (self::$instance !== null) {
                self::ensureSchemaCompatibility(self::$instance);
            }
        }

        return self::$instance;
    }

    /**
     * Automatic seamless schema compatibility checks for hostinger deployments
     */
    public static function ensureSchemaCompatibility(PDO $pdo) {
        static $checked = false;
        if ($checked) return;
        $checked = true;

        try {
            // 1. Ensure delivery_boys table has email
            if (!self::hasColumn($pdo, 'delivery_boys', 'email')) {
                $pdo->exec("ALTER TABLE delivery_boys ADD COLUMN email VARCHAR(120) NULL AFTER phone");
            }
        } catch (Throwable $e) {}

        try {
            // 2. Ensure users table has email
            if (!self::hasColumn($pdo, 'users', 'email')) {
                $pdo->exec("ALTER TABLE users ADD COLUMN email VARCHAR(120) NULL AFTER phone");
            }
        } catch (Throwable $e) {}

        try {
            // 3. Ensure users table has password
            if (!self::hasColumn($pdo, 'users', 'password')) {
                $pdo->exec("ALTER TABLE users ADD COLUMN password VARCHAR(255) NULL AFTER email");
            }
        } catch (Throwable $e) {}

        try {
            // 4. Ensure users table has otp and otp_expires_at for forgot password
            if (!self::hasColumn($pdo, 'users', 'otp')) {
                $pdo->exec("ALTER TABLE users ADD COLUMN otp VARCHAR(6) NULL AFTER password");
            }
            if (!self::hasColumn($pdo, 'users', 'otp_expires_at')) {
                $pdo->exec("ALTER TABLE users ADD COLUMN otp_expires_at DATETIME NULL AFTER otp");
            }
        } catch (Throwable $e) {}

        try {
            // 5. Ensure admins table has phone
            if (!self::hasColumn($pdo, 'admins', 'phone')) {
                $pdo->exec("ALTER TABLE admins ADD COLUMN phone VARCHAR(25) NULL AFTER role");
            }
        } catch (Throwable $e) {}

        try {
            // 6. Ensure categories sort order matches user preference:
            // 1. Gojra special (9)
            // 2. Entertainment (6)
            // 3. Breakfast - dairy (3)
            // 4. Vegetables (16)
            // 5. Grossery (10)
            // 6. Health & beauty (11)
            // 7. Baby care (1)
            // 8. Dry fruits (4)
            // 9. Sweets (15)
            // 10. Beverages (2)
            // 11. House hold (12)
            // 12. Personal care (13)
            // 13. Stationary (14)
            // 14. Electronics (5)
            // 15. Fruits (8)
            // 16. Fast Food (7)
            $sortOrders = [
                9  => 1,
                6  => 2,
                3  => 3,
                16 => 4,
                10 => 5,
                11 => 6,
                1  => 7,
                4  => 8,
                15 => 9,
                2  => 10,
                12 => 11,
                13 => 12,
                14 => 13,
                5  => 14,
                8  => 15,
                7  => 16,
            ];
            foreach ($sortOrders as $catId => $sort) {
                $pdo->exec("UPDATE categories SET sort_order = {$sort} WHERE id = {$catId}");
            }
        } catch (Throwable $e) {}

        try {
            // 7. Ensure live catalog is fully populated with all 16 categories & 189 products
            $countStmt = $pdo->query("SELECT COUNT(*) FROM products");
            $prodCount = (int)$countStmt->fetchColumn();
            if ($prodCount < 100) {
                $seedFile = __DIR__ . '/../database/everyfy_catalog_seed.sql';
                if (file_exists($seedFile)) {
                    $seedSql = file_get_contents($seedFile);
                    $pdo->exec($seedSql);
                }
            }
        } catch (Throwable $e) {}
    }

    /**
     * Helper to safely check if a column exists in a given table
     */
    public static function hasColumn(PDO $pdo, string $table, string $column): bool {
        try {
            $stmt = $pdo->prepare("SHOW COLUMNS FROM `{$table}` LIKE ?");
            $stmt->execute([$column]);
            return (bool)$stmt->fetch();
        } catch (Throwable $e) {
            return false;
        }
    }

    /**
     * Get last connection error message if any
     */
    public static function getLastError() {
        return self::$connectionError;
    }

    /**
     * Test connection without throwing fatal exception
     */
    public static function testConnection() {
        return self::getConnection() !== null;
    }
}
