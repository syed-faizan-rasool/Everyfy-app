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
  `password` VARCHAR(255) NOT NULL,
  `cnic` VARCHAR(30) NULL,
  `vehicle_type` VARCHAR(50) DEFAULT 'Motorcycle',
  `vehicle_number` VARCHAR(50) DEFAULT 'LEB-4921',
  `profile_image` VARCHAR(255) NULL,
  `rating` DECIMAL(3, 2) DEFAULT 4.90,
  `is_online` TINYINT(1) DEFAULT 1,
  `is_active` TINYINT(1) DEFAULT 1,
  `current_lat` DECIMAL(10, 7) DEFAULT 31.5204,
  `current_lng` DECIMAL(10, 7) DEFAULT 74.3587,
  `total_deliveries` INT DEFAULT 0,
  `auth_token` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

-- 1. Default Super Admin (Email: admin@everyfy.net / Pass: admin123456)
INSERT INTO `admins` (`id`, `name`, `email`, `password`, `role`, `phone`) VALUES
(1, 'Muhammad Daniyal', 'admin@everyfy.net', '$2y$10$wN9a3x3M5cK4F6nN5nKxfe9pLgB7V2k3p0GzQ6XzY8q8wN9a3x3M5', 'super_admin', '03001234567')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 2. Default Riders (Password: 1234)
INSERT INTO `delivery_boys` (`id`, `name`, `phone`, `password`, `cnic`, `vehicle_type`, `vehicle_number`, `rating`, `is_online`, `is_active`, `total_deliveries`) VALUES
(1, 'Ahmed Khan', '03019876543', '$2y$10$zS3lX1/x9yqgD8CcfkMhSe1Uv24F4RzF.vM1nOm1bQjP4/1rIqX7W', '35201-1234567-1', 'Honda CD70', 'LEB-4921', 4.90, 1, 1, 142),
(2, 'Bilal Hassan', '03214567890', '$2y$10$zS3lX1/x9yqgD8CcfkMhSe1Uv24F4RzF.vM1nOm1bQjP4/1rIqX7W', '35201-9876543-3', 'Yamaha YBR', 'LEK-8812', 4.80, 1, 1, 98),
(3, 'Hamza Ali', '03337766554', '$2y$10$zS3lX1/x9yqgD8CcfkMhSe1Uv24F4RzF.vM1nOm1bQjP4/1rIqX7W', '35201-5544332-5', 'Road Prince 70', 'LEM-3104', 4.70, 1, 1, 115),
(4, 'Zain Malik', '03451122334', '$2y$10$zS3lX1/x9yqgD8CcfkMhSe1Uv24F4RzF.vM1nOm1bQjP4/1rIqX7W', '35201-6677889-7', 'United 70', 'LEJ-5590', 4.60, 0, 1, 64)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 3. Demo Customer User (Password: 1234)
INSERT INTO `users` (`id`, `name`, `phone`, `email`, `password`, `is_active`) VALUES
(1, 'Demo Customer', '03001234567', 'customer@everyfy.net', '$2y$10$zS3lX1/x9yqgD8CcfkMhSe1Uv24F4RzF.vM1nOm1bQjP4/1rIqX7W', 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 4. Customer Saved Addresses
INSERT INTO `addresses` (`id`, `user_id`, `label`, `address_line`, `area`, `city`, `is_default`) VALUES
(1, 1, 'Home', 'House 42, Street 6', 'Sector Y, Phase 3, DHA', 'Lahore', 1),
(2, 1, 'Work', 'Office 304, Arfa Software Technology Park', 'Ferozepur Road', 'Lahore', 0)
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`);

-- 5. Categories
INSERT INTO `categories` (`id`, `name`, `image`, `sort_order`, `is_active`) VALUES
(1, 'Fruits', 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400', 1, 1),
(2, 'Vegetables', 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400', 2, 1),
(3, 'Dairy & Eggs', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400', 3, 1),
(4, 'Bakery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400', 4, 1),
(5, 'Beverages', 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400', 5, 1),
(6, 'Snacks', 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400', 6, 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 6. Products Catalog
INSERT INTO `products` (`id`, `category_id`, `name`, `description`, `image`, `price`, `discount_price`, `unit`, `stock_qty`, `is_featured`, `is_available`) VALUES
(1, 1, 'Fresh Red Apples', 'Crisp, sweet, and handpicked Royal Gala apples directly sourced from premium orchards. Rich in dietary fiber and vitamins.', 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500', 350.00, 299.00, '1 kg', 40, 1, 1),
(2, 1, 'Cavendish Bananas', 'Naturally ripened, potassium-packed fresh yellow bananas. Perfect for morning smoothies, snacking, and quick energy.', 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500', 160.00, 140.00, '1 dozen', 60, 1, 1),
(3, 2, 'Organic Vine Tomatoes', 'Juicy, farm-fresh vine-ripened red tomatoes. Ideal for gourmet salads, traditional gravies, and fresh sauces.', 'https://images.unsplash.com/photo-1546470427-e5380b43d2d0?w=500', 120.00, NULL, '1 kg', 25, 1, 1),
(4, 2, 'Premium Russet Potatoes', 'Freshly harvested, washed, high-grade baking and frying potatoes with smooth skin and consistent texture.', 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500', 90.00, NULL, '1 kg', 100, 0, 1),
(5, 3, 'Farm Fresh Full Cream Milk', 'Pure, pasteurized whole milk with rich natural goodness, vitamins, and calcium. Bottled under sterile conditions.', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500', 240.00, 210.00, '1 litre', 30, 1, 1),
(6, 3, 'Aged Cheddar Cheese', 'Rich and creamy sharp cheddar cheese block. Made from grass-fed cows milk and cured to perfection.', 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=500', 650.00, 599.00, '250 g', 15, 0, 1),
(7, 4, 'Artisan Sourdough Loaf', 'Naturally fermented rustic sourdough with crisp golden crust and light airy crumb. Baked fresh daily.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500', 280.00, NULL, '1 loaf', 20, 1, 1),
(8, 4, 'French Butter Croissants', 'Flaky, golden-brown laminated puff pastry crafted with 100% pure butter. Box of 4 freshly prepared croissants.', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500', 420.00, 380.00, '4 pcs', 12, 1, 1),
(9, 5, 'Pure Valencia Orange Juice', '100% cold-pressed raw orange juice with natural pulp. No added sugars, preservatives, or artificial flavours.', 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500', 320.00, 280.00, '1 litre', 25, 1, 1),
(10, 5, 'Organic Japanese Green Tea', 'Steamed whole leaf sencha green tea leaves with soothing herbal aromas and rich antioxidant profile.', 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500', 550.00, NULL, '100 g', 18, 0, 1),
(11, 6, 'Roasted Salted California Almonds', 'Crunchy, slow oven-roasted whole almonds lightly seasoned with Himalayan pink crystal salt.', 'https://images.unsplash.com/photo-1508061252445-5350f3ab0a55?w=500', 780.00, 720.00, '250 g', 35, 1, 1),
(12, 6, 'Belgian 70% Dark Chocolate', 'Single origin rich bittersweet chocolate with deep cocoa undertones and smooth velvety finish.', 'https://images.unsplash.com/photo-1511381939415-e44015466834?w=500', 450.00, 399.00, '100 g', 40, 1, 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 7. Promo Banners
INSERT INTO `banners` (`id`, `title`, `subtitle`, `image`, `link_product_id`, `sort_order`, `is_active`) VALUES
(1, 'Up to 25% OFF', 'Fresh Seasonal Fruits & Veggies', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800', 1, 1, 1),
(2, 'Morning Dairy Fresh', 'Pure Milk, Eggs & Cheese Delivered', 'https://images.unsplash.com/photo-1528750997573-59b89d56f4f7?w=800', 5, 2, 1)
ON DUPLICATE KEY UPDATE `title`=VALUES(`title`);

-- 8. Coupons
INSERT INTO `coupons` (`id`, `code`, `discount_type`, `value`, `min_order_amount`, `expiry_date`, `usage_limit`, `is_active`) VALUES
(1, 'FRESH20', 'flat', 50.00, 500.00, '2027-12-31', 5000, 1),
(2, 'EVERYFY10', 'percent', 10.00, 1000.00, '2027-12-31', 5000, 1)
ON DUPLICATE KEY UPDATE `code`=VALUES(`code`);

-- 9. Sample Initial Orders
INSERT INTO `orders` (`id`, `order_number`, `user_id`, `customer_name`, `customer_phone`, `address_id`, `delivery_boy_id`, `order_type`, `subtotal`, `delivery_fee`, `discount`, `total_amount`, `payment_method`, `payment_status`, `order_status`, `coupon_code`, `notes`, `address_text`, `distance_km`, `rider_earning`) VALUES
(1, 'ORD-9821', 1, 'Fatima Zahra', '03004455667', 1, 1, 'delivery', 1408.00, 150.00, 0.00, 1558.00, 'cod', 'pending', 'on_the_way', NULL, 'Leave package at gate', 'House 42, Street 6, Sector Y, Phase 3, DHA, Lahore', 3.4, 150.00),
(2, 'ORD-9822', 1, 'Ali Raza', '03215566778', 2, 2, 'delivery', 820.00, 100.00, 50.00, 870.00, 'cod', 'pending', 'preparing', 'FRESH20', 'Call before arrival', 'Office 304, Arfa Software Technology Park, Ferozepur Road, Lahore', 5.1, 160.00),
(3, 'ORD-9823', 1, 'Zainab Bibi', '03334455112', NULL, NULL, 'delivery', 2150.00, 0.00, 0.00, 2150.00, 'cod', 'pending', 'ready', NULL, 'Ring the bell twice', 'House 18, Block B, Model Town, Lahore', 4.0, 140.00)
ON DUPLICATE KEY UPDATE `order_number`=VALUES(`order_number`);

-- 10. Sample Order Items
INSERT INTO `order_items` (`order_id`, `product_id`, `product_name`, `product_price`, `quantity`, `subtotal`) VALUES
(1, 1, 'Fresh Red Apples', 299.00, 2, 598.00),
(1, 5, 'Farm Fresh Full Cream Milk', 210.00, 3, 630.00),
(1, 7, 'Artisan Sourdough Loaf', 280.00, 1, 280.00),
(2, 2, 'Cavendish Bananas', 140.00, 3, 420.00),
(2, 8, 'French Butter Croissants', 380.00, 1, 380.00)
ON DUPLICATE KEY UPDATE `product_name`=VALUES(`product_name`);

-- 11. Initial Order Status History
INSERT INTO `order_status_history` (`order_id`, `status`, `notes`, `changed_by`) VALUES
(1, 'placed', 'Order placed by customer', 'customer'),
(1, 'confirmed', 'Order confirmed by store', 'admin'),
(1, 'preparing', 'Order is being packed', 'admin'),
(1, 'on_the_way', 'Assigned to rider Ahmed Khan', 'rider');

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
