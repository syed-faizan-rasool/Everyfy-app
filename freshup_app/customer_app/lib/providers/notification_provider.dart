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
  bool _hasCompletedInitialFetch = false;

  String _currentRole = 'customer';
  int? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;
  String get currentRole => _currentRole;
  int? get currentUserId => _currentUserId;

  NotificationProvider() {
    startPolling();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    // Fast 4-second polling for real-time live events across Customer, Admin, and Rider
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
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
      _hasCompletedInitialFetch = false; // Reset so initial load for this role is recorded cleanly
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
      fetchNotifications(silent: true);
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
    DeviceNotificationService.showInAppAlert(
      title: title,
      body: body,
      orderNumber: payload,
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

        if (_hasCompletedInitialFetch) {
          // Real-time incoming notifications: trigger both system pop-up and in-app alert banner
          for (var notif in incoming) {
            if (!notif.isRead && !_shownNotificationIds.contains(notif.id)) {
              DeviceNotificationService.showSystemNotification(
                id: notif.id,
                title: notif.title,
                body: notif.message,
                payload: notif.orderNumber,
              );
              DeviceNotificationService.showInAppAlert(
                title: notif.title,
                body: notif.message,
                orderNumber: notif.orderNumber,
              );
              _shownNotificationIds.add(notif.id);
            }
          }
        } else {
          // On first fetch for this role, register existing notification IDs so user isn't spammed
          for (var notif in incoming) {
            _shownNotificationIds.add(notif.id);
          }
          _hasCompletedInitialFetch = true;
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


