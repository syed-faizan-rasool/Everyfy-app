import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/device_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isFetching = false;
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
    // Fast 3-second rapid polling for real-time live events across Customer, Admin, and Rider
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
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
    if (_isFetching) return;
    _isFetching = true;

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
          // Process unread notifications in chronological order (oldest to newest)
          final newUnread = incoming.reversed
              .where((n) => !n.isRead && !_shownNotificationIds.contains(n.id))
              .toList();

          for (var notif in newUnread) {
            _shownNotificationIds.add(notif.id);
            await DeviceNotificationService.showSystemNotification(
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
            if (newUnread.length > 1) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }
        } else {
          // On cold start: show unread notifications created in the last 3 minutes
          final now = DateTime.now();
          final freshUnread = incoming.reversed.where((n) =>
              !n.isRead &&
              now.difference(n.createdAt).inMinutes < 3 &&
              !_shownNotificationIds.contains(n.id)).toList();

          for (var notif in incoming) {
            _shownNotificationIds.add(notif.id);
          }

          for (var notif in freshUnread) {
            await DeviceNotificationService.showSystemNotification(
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
            if (freshUnread.length > 1) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }

          _hasCompletedInitialFetch = true;
        }

        _notifications = incoming;
      }
    } catch (_) {} finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
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


