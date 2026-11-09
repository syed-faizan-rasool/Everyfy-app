import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for Real-time System Notifications (Heads-Up Banners on Android Status Bar)
class DeviceNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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
}

