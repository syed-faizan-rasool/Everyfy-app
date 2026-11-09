<?php
/**
 * Everyfy Notification Helper
 * Creates in-app notifications for Customers, Admins, and Delivery Riders
 */

class NotificationHelper {
    /**
     * Create a notification in the database
     *
     * @param PDO $pdo
     * @param string $role 'customer', 'admin', 'rider', or 'all'
     * @param string $title
     * @param string $message
     * @param int|null $userId Specific user ID (optional)
     * @param int|null $orderId Linked order ID (optional)
     * @param string|null $orderNumber Linked order number (optional)
     * @param string $type 'order', 'promo', 'system', 'status'
     * @return bool
     */
    public static function create($pdo, $role, $title, $message, $userId = null, $orderId = null, $orderNumber = null, $type = 'order') {
        try {
            $stmt = $pdo->prepare("
                INSERT INTO notifications (user_id, role, title, message, type, order_id, order_number, is_read, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 0, NOW())
            ");
            return $stmt->execute([
                $userId,
                $role,
                $title,
                $message,
                $type,
                $orderId,
                $orderNumber
            ]);
        } catch (Exception $e) {
            error_log('NotificationHelper::create error: ' . $e->getMessage());
            return false;
        }
    }
}

