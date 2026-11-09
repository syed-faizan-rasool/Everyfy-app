-- ==============================================================
-- Everyfy / FreshCart - Complete MySQL Database Schema & Seed Data
-- Designed for Hostinger MySQL (phpMyAdmin) & PHP 8.x REST API
-- Domain: everyfy.net
-- ==============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- --------------------------------------------------------------
-- 1. Table: users (Customers)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(25) NOT NULL UNIQUE,
  `email` VARCHAR(120) NULL,
  `password` VARCHAR(255) NULL,
  `otp` VARCHAR(6) NULL,
  `otp_expires_at` DATETIME NULL,
  `auth_token` VARCHAR(255) NULL,
  `profile_image` VARCHAR(255) NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 2. Table: addresses (Customer Delivery Addresses)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `addresses` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `label` VARCHAR(50) DEFAULT 'Home',
  `address_line` VARCHAR(255) NOT NULL,
  `area` VARCHAR(100) NOT NULL,
  `city` VARCHAR(100) DEFAULT 'Lahore',
  `latitude` DECIMAL(10, 7) NULL,
  `longitude` DECIMAL(10, 7) NULL,
  `is_default` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 3. Table: admins (Dashboard Administrators)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `admins` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(120) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` VARCHAR(50) DEFAULT 'super_admin',
  `phone` VARCHAR(25) NULL,
  `auth_token` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 4. Table: delivery_boys (Riders Fleet)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `delivery_boys` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(25) NOT NULL UNIQUE,
  `email` VARCHAR(120) NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `cnic` VARCHAR(30) NULL,
  `vehicle_type` VARCHAR(50) DEFAULT 'Motorcycle',
  `vehicle_number` VARCHAR(50) DEFAULT 'LEB-4921',
  `profile_image` VARCHAR(255) NULL,
  `rating` DECIMAL(3, 2) DEFAULT 5.00,
  `is_online` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `current_lat` DECIMAL(10, 7) DEFAULT 31.5204,
  `current_lng` DECIMAL(10, 7) DEFAULT 74.3587,
  `total_deliveries` INT DEFAULT 0,
  `auth_token` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_riders_phone` (`phone`),
  INDEX `idx_riders_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 5. Table: categories (Product Categories)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `categories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `image` VARCHAR(255) NOT NULL,
  `sort_order` INT DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 6. Table: products (Grocery Products Catalog)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `products` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `category_id` INT NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `image` VARCHAR(255) NOT NULL,
  `price` DECIMAL(10, 2) NOT NULL,
  `discount_price` DECIMAL(10, 2) NULL,
  `unit` VARCHAR(50) NOT NULL DEFAULT '1 kg',
  `stock_qty` INT NOT NULL DEFAULT 50,
  `is_featured` TINYINT(1) DEFAULT 0,
  `is_available` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 7. Table: banners (Home Promotional Banners)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `banners` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(150) NULL,
  `subtitle` VARCHAR(255) NULL,
  `image` VARCHAR(255) NOT NULL,
  `link_product_id` INT NULL,
  `sort_order` INT DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 8. Table: coupons (Discount Promo Codes)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `coupons` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(30) NOT NULL UNIQUE,
  `discount_type` ENUM('flat', 'percent') NOT NULL DEFAULT 'flat',
  `value` DECIMAL(10, 2) NOT NULL,
  `min_order_amount` DECIMAL(10, 2) DEFAULT 0.00,
  `expiry_date` DATE NULL,
  `usage_limit` INT DEFAULT 1000,
  `times_used` INT DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 9. Table: orders (Customer Orders)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `orders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_number` VARCHAR(30) NOT NULL UNIQUE,
  `user_id` INT NULL,
  `customer_name` VARCHAR(100) NULL,
  `customer_phone` VARCHAR(25) NULL,
  `address_id` INT NULL,
  `delivery_boy_id` INT NULL,
  `order_type` ENUM('delivery', 'pickup') DEFAULT 'delivery',
  `subtotal` DECIMAL(10, 2) NOT NULL,
  `delivery_fee` DECIMAL(10, 2) DEFAULT 0.00,
  `discount` DECIMAL(10, 2) DEFAULT 0.00,
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `payment_method` ENUM('cod', 'card', 'wallet') DEFAULT 'cod',
  `payment_status` ENUM('pending', 'paid', 'failed') DEFAULT 'pending',
  `order_status` ENUM('placed', 'confirmed', 'preparing', 'ready', 'picked_up', 'on_the_way', 'delivered', 'cancelled') DEFAULT 'placed',
  `coupon_code` VARCHAR(30) NULL,
  `notes` TEXT NULL,
  `address_text` TEXT NOT NULL,
  `distance_km` DECIMAL(5, 2) DEFAULT 3.2,
  `rider_earning` DECIMAL(10, 2) DEFAULT 120.00,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`delivery_boy_id`) REFERENCES `delivery_boys`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 10. Table: order_items (Items in Order)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `order_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `product_name` VARCHAR(150) NOT NULL,
  `product_price` DECIMAL(10, 2) NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `subtotal` DECIMAL(10, 2) NOT NULL,
  FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 11. Table: order_status_history (Timeline Tracking)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `order_status_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `status` VARCHAR(50) NOT NULL,
  `notes` VARCHAR(255) NULL,
  `changed_by` VARCHAR(50) DEFAULT 'system',
  `changed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------------
-- 12. Table: settings (Store Configuration)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `setting_key` VARCHAR(50) NOT NULL UNIQUE,
  `setting_value` TEXT NOT NULL,
  `description` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================
-- SEED DATA - Initial Demo Data Ready for Testing
-- ==============================================================

-- 1. Default Super Admin (Can be customized via /setup.php or /change_admin.php)
INSERT INTO `admins` (`id`, `name`, `email`, `password`, `role`, `phone`) VALUES
(1, 'Store Admin', 'admin@everyfy.net', '$2y$10$wN9a3x3M5cK4F6nN5nKxfe9pLgB7V2k3p0GzQ6XzY8q8wN9a3x3M5', 'super_admin', '03001234567')
ON DUPLICATE KEY UPDATE `email`=VALUES(`email`);

-- NOTE: All dummy riders, dummy customers, and dummy sample orders have been permanently removed!
-- Real riders and customers register directly through the mobile app or web admin panel.

-- 12. Settings
INSERT INTO `settings` (`setting_key`, `setting_value`, `description`) VALUES
('store_name', 'Everyfy FreshCart', 'Name of the store displayed in app and receipts'),
('store_phone', '+92 300 1234567', 'Official store contact telephone'),
('store_address', 'Everyfy Hub, Main Boulevard, Gulberg III, Lahore', 'Physical store pickup address'),
('delivery_fee_base', '100', 'Standard flat delivery fee in PKR'),
('free_delivery_min_amount', '1000', 'Minimum order amount for free delivery'),
('app_currency', 'Rs', 'Currency symbol'),
('otp_demo_mode', '1', 'If 1, OTP 1234 will always succeed in development')
ON DUPLICATE KEY UPDATE `setting_value`=VALUES(`setting_value`);
