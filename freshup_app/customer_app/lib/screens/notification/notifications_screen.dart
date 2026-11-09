import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Unread

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }

  IconData _getNotificationIcon(String title, String type) {
    final t = title.toLowerCase();
    if (t.contains('rider') || t.contains('out for delivery') || t.contains('picked up')) {
      return Icons.delivery_dining_rounded;
    }
    if (t.contains('delivered') || t.contains('completed') || t.contains('success')) {
      return Icons.check_circle_rounded;
    }
    if (t.contains('placed') || t.contains('order received') || t.contains('shopping')) {
      return Icons.shopping_bag_rounded;
    }
    if (t.contains('custom')) {
      return Icons.edit_note_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('delivered') || t.contains('completed')) return const Color(0xFF10B981);
    if (t.contains('picked up') || t.contains('out for delivery')) return const Color(0xFFF59E0B);
    if (t.contains('cancelled')) return const Color(0xFFEF4444);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final allNotifs = notifProv.notifications;

    final filteredNotifs = _selectedFilterIndex == 1
        ? allNotifs.where((n) => !n.isRead).toList()
        : allNotifs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          if (notifProv.hasUnread)
            TextButton.icon(
              onPressed: () => notifProv.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Mark All Read',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (All / Unread)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All (${allNotifs.length})',
                  index: 0,
                  isSelected: _selectedFilterIndex == 0,
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  label: 'Unread (${notifProv.unreadCount})',
                  index: 1,
                  isSelected: _selectedFilterIndex == 1,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifProv.fetchNotifications(),
              color: AppColors.primary,
              child: filteredNotifs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        EmptyStateWidget(
                          icon: Icons.notifications_none_rounded,
                          title: 'No notifications',
                          description: 'You are all caught up! New order updates, rider assignments, and delivery statuses will appear here.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotifs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final notif = filteredNotifs[idx];
                        final iconColor = _getIconColor(notif.title);
                        final icon = _getNotificationIcon(notif.title, notif.type);

                        return InkWell(
                          onTap: () {
                            if (!notif.isRead) {
                              notifProv.markAsRead(notif.id);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: notif.isRead
                                    ? const Color(0xFFE2E8F0)
                                    : AppColors.primary.withValues(alpha: 0.3),
                                width: notif.isRead ? 1 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Leading Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(icon, color: iconColor, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(notif.createdAt),
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF475569),
                                          height: 1.35,
                                          fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w500,
                                        ),
                                      ),
                                      if (notif.orderNumber != null && notif.orderNumber!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Order #${notif.orderNumber}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Unread Indicator Dot
                                if (!notif.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required int index, required bool isSelected}) {
    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
