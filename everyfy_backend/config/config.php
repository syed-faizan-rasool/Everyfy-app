<?php
/**
 * Everyfy System Configuration
 * Domain: everyfy.net
 */

// Error Reporting (Turn off display_errors in production if desired)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Timezone
date_default_timezone_set('Asia/Karachi');

// Base URLs & Paths
define('SITE_URL', 'https://everyfy.net');
define('API_BASE_URL', SITE_URL . '/api');
define('UPLOAD_URL', SITE_URL . '/uploads');

define('ROOT_PATH', dirname(__DIR__));
define('UPLOAD_PATH', ROOT_PATH . '/uploads');

// Security & JWT Secret (Change this to any custom random string if needed)
define('JWT_SECRET_KEY', 'everyfy_super_secret_jwt_key_2026_xyz987');
define('JWT_EXPIRY_SECONDS', 60 * 60 * 24 * 30); // 30 Days token validity

// App Default Settings
define('DEFAULT_CURRENCY', 'Rs');
define('DEFAULT_DELIVERY_FEE', 100.00);
define('FREE_DELIVERY_THRESHOLD', 1000.00);
define('OTP_DEMO_CODE', '1234'); // Universal dev/testing fallback OTP
