import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class _InAppAlertItem {
  final String title;
  final String body;
  final String? orderNumber;
  final VoidCallback? onTap;

  _InAppAlertItem({
    required this.title,
    required this.body,
    this.orderNumber,
    this.onTap,
  });
}

/// Service for Real-time System Notifications (Heads-Up Banners on Android Status Bar)
class DeviceNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final List<_InAppAlertItem> _alertQueue = [];
  static bool _isProcessingQueue = false;

  static const String channelId = 'everyfy_orders_channel';
  static const String channelName = 'Everyfy Order & Delivery Alerts';
  static const String channelDesc = 'High-priority alerts for new orders, rider assignments, and live status changes.';

  /// Initialize system notification channels & permissions
  static Future<void> init() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[System Notification] Tapped payload: ${response.payload}');
        },
      );

      // Request notification permissions for Android 13+
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _initialized = true;
      debugPrint('[DeviceNotificationService] Initialized successfully with high-priority channel.');
    } catch (e) {
      debugPrint('[DeviceNotificationService] Init error: $e');
    }
  }

  /// Show Top-of-screen Heads-Up System Notification (Sound + Banner + Vibration)
  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await init();

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      debugPrint('[System Notification] Fired notification ID $id: "$title"');
    } catch (e) {
      debugPrint('[DeviceNotificationService] Error showing notification: $e');
    }
  }

  /// Show In-App Floating Popup Toast Banner when the app is actively on screen.
  /// Automatically queues multiple notifications so every single one is displayed sequentially!
  static void showInAppAlert({
    required String title,
    required String body,
    String? orderNumber,
    VoidCallback? onTap,
  }) {
    // Avoid exact duplicate queued items or duplicate alerts for the same order event
    if (_alertQueue.any((item) =>
        (item.title == title && item.body == body) ||
        (orderNumber != null &&
            orderNumber.isNotEmpty &&
            item.orderNumber == orderNumber &&
            item.title == title))) {
      return;
    }

    _alertQueue.add(_InAppAlertItem(
      title: title,
      body: body,
      orderNumber: orderNumber,
      onTap: onTap,
    ));

    _processAlertQueue();
  }

  static Future<void> _processAlertQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_alertQueue.isNotEmpty) {
        final item = _alertQueue.removeAt(0);
        final messenger = rootScaffoldMessengerKey.currentState;
        if (messenger != null) {
          try {
            HapticFeedback.mediumImpact();
          } catch (_) {}

          final remainingCount = _alertQueue.length;
          final controller = messenger.showSnackBar(
            SnackBar(
              content: InkWell(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  if (item.onTap != null) {
                    item.onTap!();
                  }
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.body,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (remainingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+$remainingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0D6843), // Everyfy Emerald Green
              duration: const Duration(milliseconds: 3200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              elevation: 8,
            ),
          );

          await controller.closed;
          if (_alertQueue.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 250));
          }
        } else {
          // Re-insert item and wait briefly for messenger to mount
          _alertQueue.insert(0, item);
          await Future.delayed(const Duration(milliseconds: 400));
          if (rootScaffoldMessengerKey.currentState == null) {
            _alertQueue.removeAt(0);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[DeviceNotificationService] In-App alert queue error: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }
}

