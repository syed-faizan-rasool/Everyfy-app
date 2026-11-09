import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/device_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollingTimer;
  final Set<int> _shownNotificationIds = {};

  String _currentRole = 'customer';
  int? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  NotificationProvider() {
    // Start periodic polling every 12 seconds to capture live events across 3 sides
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      fetchNotifications(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void setRoleAndUser({required String role, int? userId}) {
    if (_currentRole != role || _currentUserId != userId) {
      _currentRole = role;
      _currentUserId = userId;
      fetchNotifications();
    }
  }

  /// Fire immediate real-time system notification on device top bar
  Future<void> triggerInstantSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    await DeviceNotificationService.showSystemNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await ApiService.getNotifications(
        role: _currentRole,
        userId: _currentUserId,
      );

      if (res['success'] == true) {
        final incoming = (res['notifications'] as List<NotificationModel>?) ?? [];
        _unreadCount = (res['unread_count'] as int?) ?? 0;

        // Fire real Android system notifications for newly arrived items
        if (_notifications.isNotEmpty) {
          for (var notif in incoming) {
            if (!notif.isRead && !_shownNotificationIds.contains(notif.id)) {
              DeviceNotificationService.showSystemNotification(
                id: notif.id,
                title: notif.title,
                body: notif.message,
                payload: notif.orderNumber,
              );
              _shownNotificationIds.add(notif.id);
            }
          }
        } else {
          // On initial load, record IDs so user isn't spammed with old history
          for (var notif in incoming) {
            _shownNotificationIds.add(notif.id);
          }
        }
        _notifications = incoming;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    await ApiService.markNotificationAsRead(
      notificationId: notificationId,
      role: _currentRole,
      userId: _currentUserId,
    );
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    await ApiService.markNotificationAsRead(
      markAll: true,
      role: _currentRole,
      userId: _currentUserId,
    );
  }
}

