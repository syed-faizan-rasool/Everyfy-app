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

-- ==============================================================
-- 13. LIVE SCANNED CATALOG SEED (16 CATEGORIES & 189 PRODUCTS)
-- ==============================================================

-- Everyfy Scanned Catalog Seed
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM `order_items`;
DELETE FROM `products`;
DELETE FROM `categories`;
ALTER TABLE `products` AUTO_INCREMENT = 1;
ALTER TABLE `categories` AUTO_INCREMENT = 1;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Categories Seed
INSERT INTO `categories` (`id`, `name`, `image`, `sort_order`, `is_active`) VALUES
(9, 'Gojra special', 'uploads/categories/cat_9_gojra_special.jpg', 1, 1),
(6, 'Entertainment', 'uploads/categories/cat_6_entertainment.jpg', 2, 1),
(3, 'Breakfast - dairy', 'uploads/categories/cat_3_breakfast_dairy.jpg', 3, 1),
(16, 'Vegetables', 'uploads/categories/cat_16_vegetables.jpg', 4, 1),
(10, 'Grossery', 'uploads/categories/cat_10_grossery.jpg', 5, 1),
(11, 'Health & beauty', 'uploads/categories/cat_11_health_beauty.jpg', 6, 1),
(1, 'Baby care', 'uploads/categories/cat_1_baby_care.jpg', 7, 1),
(4, 'Dry fruits', 'uploads/categories/cat_4_dry_fruits.jpg', 8, 1),
(15, 'Sweets', 'uploads/categories/cat_15_sweets.jpg', 9, 1),
(2, 'Beverages', 'uploads/categories/cat_2_beverages.jpg', 10, 1),
(12, 'House hold', 'uploads/categories/cat_12_house_hold.jpg', 11, 1),
(13, 'Personal care', 'uploads/categories/cat_13_personal_care.jpg', 12, 1),
(14, 'Stationary', 'uploads/categories/cat_14_stationary.jpg', 13, 1),
(5, 'Electronics', 'uploads/categories/cat_5_electronics.jpg', 14, 1),
(8, 'Fruits', 'uploads/categories/cat_8_fruits.jpg', 15, 1),
(7, 'Fast Food', 'uploads/categories/cat_7_fast_food.jpg', 16, 1);

-- 2. Products Seed (189 Live Scanned Products)
INSERT INTO `products` (`id`, `category_id`, `name`, `description`, `image`, `price`, `discount_price`, `unit`, `stock_qty`, `is_featured`, `is_available`) VALUES
(1, 2, 'Nescafe Classic Hot Coffee', 'Rich aromatic hot coffee brewed with Nescafe Classic roast.', 'uploads/products/prod_2_187.jpg', 0.00, NULL, '1 Cup', 50, 1, 1),
(2, 2, 'Karak Doodh Patti Chai & Biscuits', 'Traditional strong Pakistani milk tea served fresh with crispy Parle-G biscuits.', 'uploads/products/prod_2_188.jpg', 0.00, NULL, '1 Cup', 50, 1, 1),
(3, 3, 'Fresh Roghani Naan / Sesame Kulcha', 'Tandoor-baked soft and buttery naan topped with sesame seeds and fresh coriander.', 'uploads/products/prod_3_143.jpg', 0.00, NULL, '2 Pcs', 50, 1, 1),
(4, 3, 'Breakfast Essential #145', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_145.jpg', 0.00, NULL, '1 Pack', 50, 1, 1),
(5, 3, 'Breakfast Essential #157', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_157.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(6, 3, 'Breakfast Essential #158', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_158.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(7, 3, 'Breakfast Essential #160', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_160.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(8, 3, 'Breakfast Essential #161', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_161.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(9, 3, 'Breakfast Essential #164', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_164.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(10, 3, 'Breakfast Essential #165', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_165.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(11, 3, 'Breakfast Essential #182', 'Morning breakfast and dairy essential delivered fresh.', 'uploads/products/prod_3_182.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(12, 4, 'Premium Dry Fruit #9', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_9.jpg', 0.00, NULL, '250 g', 50, 1, 1),
(13, 4, 'Kashmiri Mountain Walnuts (Akhrot)', 'Premium thin-shelled whole walnuts with rich buttery halves.', 'uploads/products/prod_4_141.jpg', 0.00, NULL, '500 g', 50, 1, 1),
(14, 4, 'Premium Dry Fruit #142', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_142.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(15, 4, 'Premium Dry Fruit #144', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_144.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(16, 4, 'Premium Dry Fruit #146', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_146.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(17, 4, 'Premium Dry Fruit #147', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_147.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(18, 4, 'Premium Dry Fruit #148', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_148.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(19, 4, 'Premium Dry Fruit #149', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_149.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(20, 4, 'Premium Dry Fruit #150', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_150.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(21, 4, 'Premium Dry Fruit #151', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_151.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(22, 4, 'Premium Dry Fruit #152', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_152.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(23, 4, 'Premium Dry Fruit #153', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_153.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(24, 4, 'Premium Dry Fruit #154', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_154.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(25, 4, 'Premium Dry Fruit #155', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_155.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(26, 4, 'Premium Dry Fruit #156', 'High-grade dry fruit rich in natural nutrition and vitamins.', 'uploads/products/prod_4_156.jpg', 0.00, NULL, '250 g', 50, 0, 1),
(27, 7, 'Chicken Shawarma Pita Wrap', 'Slow-roasted tender chicken with garlic mayo, crisp lettuce in soft pita wrap.', 'uploads/products/prod_7_166.jpg', 0.00, NULL, '1 Roll', 50, 1, 1),
(28, 7, 'Hot Fast Food #168', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_168.jpg', 0.00, NULL, '1 Serving', 50, 1, 1),
(29, 7, 'Hot Fast Food #170', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_170.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(30, 7, 'Hot Fast Food #172', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_172.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(31, 7, 'Hot Fast Food #173', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_173.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(32, 7, 'Hot Fast Food #174', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_174.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(33, 7, 'Hot Fast Food #175', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_175.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(34, 7, 'Hot Fast Food #176', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_176.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(35, 7, 'Hot Fast Food #184', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_184.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(36, 7, 'Hot Fast Food #186', 'Freshly prepared sizzling hot snack made with premium ingredients.', 'uploads/products/prod_7_186.jpg', 0.00, NULL, '1 Serving', 50, 0, 1),
(37, 8, 'Fresh Royal Jamun (Black Plum)', 'Juicy, sweet and slightly tangy handpicked black plums.', 'uploads/products/prod_8_123.jpg', 0.00, NULL, '1 kg', 50, 1, 1),
(38, 8, 'Fresh Farm Strawberries', 'Vibrant red, fragrant, sweet strawberries freshly harvested.', 'uploads/products/prod_8_124.jpg', 0.00, NULL, '500 g', 50, 1, 1),
(39, 8, 'Kandhari Red Pomegranate (Anar)', 'Deep ruby red, crisp sweet pomegranate seeds rich in antioxidants.', 'uploads/products/prod_8_125.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(40, 8, 'Swat Valley Fresh Peaches (Aaroo)', 'Soft, succulent and aromatic sweet peaches hand-sorted.', 'uploads/products/prod_8_126.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(41, 8, 'Seedless Green Grapes (Angoor)', 'Crisp, sweet, and seedless premium table grapes.', 'uploads/products/prod_8_127.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(42, 8, 'Fresh Farm Guava (Amrood)', 'Crunchy and fragrant white-fleshed local sweet guavas.', 'uploads/products/prod_8_128.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(43, 8, 'Green Pear (Nashpati)', 'Juicy, sweet and crisp farm-grown fresh pears.', 'uploads/products/prod_8_129.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(44, 8, 'Fresh Red Cherries', 'Plump, sweet, and glossy deep-red premium cherries.', 'uploads/products/prod_8_130.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(45, 8, 'Sugar Baby Watermelon (Tarbooz)', 'Crisp, intensely sweet and refreshing red watermelon.', 'uploads/products/prod_8_131.jpg', 0.00, NULL, '1 Whole', 50, 0, 1),
(46, 8, 'Juicy Citrus Oranges / Kino', 'Sun-ripened, citrusy, vitamin-C rich fresh Pakistani kinnow.', 'uploads/products/prod_8_132.jpg', 0.00, NULL, '1 Dozen', 50, 0, 1),
(47, 8, 'Premium Seasonal Fruit #133', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_133.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(48, 8, 'Premium Seasonal Fruit #134', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_134.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(49, 8, 'Premium Seasonal Fruit #135', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_135.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(50, 8, 'Premium Seasonal Fruit #136', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_136.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(51, 8, 'Premium Seasonal Fruit #137', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_137.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(52, 8, 'Premium Seasonal Fruit #138', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_138.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(53, 8, 'Premium Seasonal Fruit #139', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_139.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(54, 8, 'Premium Seasonal Fruit #140', 'Naturally ripened sweet and succulent orchard fruit.', 'uploads/products/prod_8_140.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(55, 9, 'Gojra Special Gol Gappay Platter', 'Crispy puris filled with spiced chickpeas, potatoes, and zesty khatta meetha pani.', 'uploads/products/prod_9_167.jpg', 0.00, NULL, '1 Plate (10 Pcs)', 50, 1, 1),
(56, 9, 'Gojra Special Treat #179', 'Traditional authentic Gojra specialty prepared using generational recipes.', 'uploads/products/prod_9_179.jpg', 0.00, NULL, '1 Plate', 50, 1, 1),
(57, 9, 'Gojra Special Treat #180', 'Traditional authentic Gojra specialty prepared using generational recipes.', 'uploads/products/prod_9_180.jpg', 0.00, NULL, '1 Plate', 50, 0, 1),
(58, 9, 'Gojra Special Treat #181', 'Traditional authentic Gojra specialty prepared using generational recipes.', 'uploads/products/prod_9_181.jpg', 0.00, NULL, '1 Plate', 50, 0, 1),
(59, 9, 'Gojra Special Treat #183', 'Traditional authentic Gojra specialty prepared using generational recipes.', 'uploads/products/prod_9_183.jpg', 0.00, NULL, '1 Plate', 50, 0, 1),
(60, 9, 'Gojra Special Treat #185', 'Traditional authentic Gojra specialty prepared using generational recipes.', 'uploads/products/prod_9_185.jpg', 0.00, NULL, '1 Plate', 50, 0, 1),
(61, 10, 'Organic Tej Patta (Bay Leaves)', 'Aromatic dried bay leaves for traditional biryani, pulao and gravies.', 'uploads/products/prod_10_1.jpg', 0.00, NULL, '100 g', 50, 1, 1),
(62, 10, 'Kitchen Grocery #2', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_2.jpg', 0.00, NULL, '500 g', 50, 1, 1),
(63, 10, 'Kitchen Grocery #3', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_3.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(64, 10, 'Kitchen Grocery #4', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_4.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(65, 10, 'Kitchen Grocery #5', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_5.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(66, 10, 'Kitchen Grocery #6', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_6.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(67, 10, 'Kitchen Grocery #7', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_7.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(68, 10, 'Kitchen Grocery #8', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_8.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(69, 10, 'Kitchen Grocery #10', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_10.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(70, 10, 'Kitchen Grocery #11', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_11.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(71, 10, 'Kitchen Grocery #12', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_12.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(72, 10, 'Kitchen Grocery #13', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_13.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(73, 10, 'Kitchen Grocery #14', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_14.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(74, 10, 'Kitchen Grocery #15', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_15.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(75, 10, 'Kitchen Grocery #16', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_16.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(76, 10, 'Kitchen Grocery #17', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_17.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(77, 10, 'Kitchen Grocery #18', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_18.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(78, 10, 'Kitchen Grocery #19', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_19.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(79, 10, 'Kitchen Grocery #20', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_20.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(80, 10, 'Kitchen Grocery #21', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_21.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(81, 10, 'Kitchen Grocery #22', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_22.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(82, 10, 'Kitchen Grocery #23', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_23.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(83, 10, 'Kitchen Grocery #24', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_24.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(84, 10, 'Kitchen Grocery #25', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_25.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(85, 10, 'Kitchen Grocery #26', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_26.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(86, 10, 'Kitchen Grocery #27', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_27.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(87, 10, 'Kitchen Grocery #28', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_28.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(88, 10, 'Kitchen Grocery #29', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_29.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(89, 10, 'Kitchen Grocery #30', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_30.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(90, 10, 'Kitchen Grocery #31', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_31.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(91, 10, 'Kitchen Grocery #32', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_32.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(92, 10, 'Kitchen Grocery #33', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_33.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(93, 10, 'Kitchen Grocery #34', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_34.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(94, 10, 'Kitchen Grocery #35', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_35.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(95, 10, 'Kitchen Grocery #36', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_36.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(96, 10, 'Kitchen Grocery #37', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_37.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(97, 10, 'Kitchen Grocery #38', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_38.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(98, 10, 'Kitchen Grocery #39', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_39.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(99, 10, 'Kitchen Grocery #40', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_40.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(100, 10, 'Kitchen Grocery #41', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_41.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(101, 10, 'Kitchen Grocery #42', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_42.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(102, 10, 'Kitchen Grocery #43', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_43.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(103, 10, 'Kitchen Grocery #44', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_44.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(104, 10, 'Kitchen Grocery #45', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_45.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(105, 10, 'Kitchen Grocery #46', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_46.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(106, 10, 'Kitchen Grocery #47', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_47.png', 0.00, NULL, '1 kg', 50, 0, 1),
(107, 10, 'Kitchen Grocery #48', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_48.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(108, 10, 'Kitchen Grocery #49', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_49.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(109, 10, 'Kitchen Grocery #50', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_50.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(110, 10, 'Kitchen Grocery #51', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_51.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(111, 10, 'Kitchen Grocery #52', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_52.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(112, 10, 'Kitchen Grocery #53', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_53.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(113, 10, 'Kitchen Grocery #54', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_54.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(114, 10, 'Kitchen Grocery #55', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_55.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(115, 10, 'Kitchen Grocery #56', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_56.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(116, 10, 'Kitchen Grocery #64', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_64.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(117, 10, 'Kitchen Grocery #68', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_68.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(118, 10, 'Kitchen Grocery #69', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_69.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(119, 10, 'Kitchen Grocery #70', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_70.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(120, 10, 'Kitchen Grocery #71', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_71.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(121, 10, 'Kitchen Grocery #86', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_86.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(122, 10, 'Kitchen Grocery #87', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_87.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(123, 10, 'Kitchen Grocery #88', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_88.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(124, 10, 'Kitchen Grocery #89', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_89.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(125, 10, 'Kitchen Grocery #90', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_90.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(126, 10, 'Kitchen Grocery #91', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_91.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(127, 10, 'Kitchen Grocery #92', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_92.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(128, 10, 'Kitchen Grocery #93', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_93.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(129, 10, 'Kitchen Grocery #94', 'Essential kitchen staple for daily cooking and household groceries.', 'uploads/products/prod_10_94.jpg', 0.00, NULL, '1 Pack', 50, 0, 1),
(130, 11, '100% Pure Natural Honeycomb Jar', 'Unprocessed pure raw honey with natural honeycomb section.', 'uploads/products/prod_11_159.jpg', 0.00, NULL, '500 g', 50, 1, 1),
(131, 11, 'Health & beauty Item #162', 'Premium quality health & beauty item hand-selected for Everyfy customers.', 'uploads/products/prod_11_162.jpg', 0.00, NULL, '1 Pack', 50, 1, 1),
(132, 14, 'Heavy Duty Multi-Color Duct Tape', 'Strong adhesive waterproof colored duct tape for repairs, packaging and crafts.', 'uploads/products/prod_14_57.jpg', 0.00, NULL, '1 Roll', 50, 1, 1),
(133, 14, 'Stationery Essential #58', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_58.jpg', 0.00, NULL, '1 pcs', 50, 1, 1),
(134, 14, 'Stationery Essential #59', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_59.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(135, 14, 'Stationery Essential #60', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_60.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(136, 14, 'Stationery Essential #61', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_61.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(137, 14, 'Stationery Essential #62', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_62.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(138, 14, 'Stationery Essential #63', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_63.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(139, 14, 'Stationery Essential #65', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_65.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(140, 14, 'Stationery Essential #66', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_66.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(141, 14, 'Stationery Essential #67', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_67.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(142, 14, 'Stationery Essential #72', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_72.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(143, 14, 'Stationery Essential #73', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_73.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(144, 14, 'Stationery Essential #74', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_74.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(145, 14, 'Stationery Essential #75', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_75.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(146, 14, 'Stationery Essential #76', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_76.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(147, 14, 'Stationery Essential #77', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_77.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(148, 14, 'Stationery Essential #78', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_78.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(149, 14, 'Stationery Essential #79', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_79.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(150, 14, 'Stationery Essential #80', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_80.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(151, 14, 'Stationery Essential #81', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_81.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(152, 14, 'Stationery Essential #82', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_82.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(153, 14, 'Stationery Essential #83', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_83.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(154, 14, 'Stationery Essential #84', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_84.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(155, 14, 'Stationery Essential #85', 'Reliable stationery item for school, home, and office use.', 'uploads/products/prod_14_85.jpg', 0.00, NULL, '1 pcs', 50, 0, 1),
(156, 15, 'Fresh Baked Golden Bread Loaf', 'Oven-fresh sliced white bread loaf with soft crust and pillowy texture.', 'uploads/products/prod_15_169.jpg', 0.00, NULL, '1 Loaf', 50, 1, 1),
(157, 15, 'Artisanal Sweet #171', 'Freshly prepared traditional sweet confectionery.', 'uploads/products/prod_15_171.jpg', 0.00, NULL, '500 g', 50, 1, 1),
(158, 15, 'Artisanal Sweet #177', 'Freshly prepared traditional sweet confectionery.', 'uploads/products/prod_15_177.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(159, 15, 'Artisanal Sweet #178', 'Freshly prepared traditional sweet confectionery.', 'uploads/products/prod_15_178.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(160, 15, 'Artisanal Sweet #189', 'Freshly prepared traditional sweet confectionery.', 'uploads/products/prod_15_189.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(161, 15, 'Artisanal Sweet #190', 'Freshly prepared traditional sweet confectionery.', 'uploads/products/prod_15_190.jpg', 0.00, NULL, '500 g', 50, 0, 1),
(162, 16, 'Fresh Green Chilies (Hari Mirch)', 'Crisp, spicy, farm-fresh vibrant green chilies.', 'uploads/products/prod_16_95.jpg', 0.00, NULL, '500 g', 50, 1, 1),
(163, 16, 'Fresh Farm Vegetable #96', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_96.jpg', 0.00, NULL, '1 kg', 50, 1, 1),
(164, 16, 'Fresh Farm Vegetable #97', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_97.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(165, 16, 'Fresh Farm Vegetable #98', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_98.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(166, 16, 'Fresh Farm Vegetable #99', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_99.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(167, 16, 'Fresh Farm Vegetable #100', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_100.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(168, 16, 'Fresh Farm Vegetable #101', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_101.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(169, 16, 'Fresh Farm Vegetable #102', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_102.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(170, 16, 'Fresh Farm Vegetable #103', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_103.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(171, 16, 'Fresh Farm Vegetable #104', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_104.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(172, 16, 'Fresh Farm Vegetable #105', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_105.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(173, 16, 'Fresh Farm Vegetable #106', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_106.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(174, 16, 'Fresh Farm Vegetable #107', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_107.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(175, 16, 'Fresh Farm Vegetable #108', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_108.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(176, 16, 'Fresh Farm Vegetable #109', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_109.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(177, 16, 'Fresh Farm Vegetable #110', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_110.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(178, 16, 'Fresh Farm Vegetable #111', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_111.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(179, 16, 'Fresh Farm Vegetable #112', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_112.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(180, 16, 'Fresh Farm Vegetable #113', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_113.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(181, 16, 'Fresh Farm Vegetable #114', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_114.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(182, 16, 'Fresh Farm Vegetable #115', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_115.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(183, 16, 'Fresh Farm Vegetable #116', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_116.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(184, 16, 'Fresh Farm Vegetable #117', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_117.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(185, 16, 'Fresh Farm Vegetable #118', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_118.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(186, 16, 'Fresh Farm Vegetable #119', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_119.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(187, 16, 'Fresh Farm Vegetable #120', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_120.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(188, 16, 'Fresh Farm Vegetable #121', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_121.jpg', 0.00, NULL, '1 kg', 50, 0, 1),
(189, 16, 'Fresh Farm Vegetable #122', 'Farm-fresh hand-sorted vegetable harvested daily for optimal freshness.', 'uploads/products/prod_16_122.jpg', 0.00, NULL, '1 kg', 50, 0, 1);


-- --------------------------------------------------------------
-- 12. Table: notifications (3-Sided In-App Notification System)
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NULL,
  `role` ENUM('customer', 'admin', 'rider', 'all') NOT NULL DEFAULT 'customer',
  `title` VARCHAR(150) NOT NULL,
  `message` TEXT NOT NULL,
  `type` VARCHAR(50) DEFAULT 'order',
  `order_id` INT NULL,
  `order_number` VARCHAR(50) NULL,
  `is_read` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_notif_role_user` (`role`, `user_id`),
  INDEX `idx_notif_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
