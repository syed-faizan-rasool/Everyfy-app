<?php
/**
 * Database Connection using PDO
 * Optimized for Hostinger Shared/Cloud Hosting & LiteSpeed/Apache
 */

require_once __DIR__ . '/config.php';

class Database {
    // -------------------------------------------------------------
    // ENTER YOUR HOSTINGER DATABASE CREDENTIALS HERE:
    // (You can create this in Hostinger hPanel -> Databases -> MySQL Databases)
    // -------------------------------------------------------------
    private static $host = 'localhost';
    private static $db_name = 'everyfy_db';       // e.g. u123456789_everyfy
    private static $username = 'root';             // e.g. u123456789_user
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
            // Check for server environment overrides if available
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
                self::$connectionError = $e->getMessage();
                return null;
            }
        }

        return self::$instance;
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
