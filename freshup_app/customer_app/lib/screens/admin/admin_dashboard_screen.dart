import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/animated_widgets.dart';
import 'admin_add_edit_product_screen.dart';
import 'admin_order_detail_screen.dart';
import '../notification/notifications_screen.dart';
import '../../providers/notification_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AdminDashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    final pendingOrders = admin.orders.where((o) => o.status == OrderStatus.placed).toList();
    final lowStockItems = admin.products.where((p) => p.stockQty <= 10).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0D5C3A),
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Store Identity & Open/Close Switch
                _buildHeader(context, admin),
                const SizedBox(height: 18),

                // Urgent Alert Bar if any pending order exists
                if (pendingOrders.isNotEmpty) ...[
                  _buildUrgentOrderAlert(context, pendingOrders.length),
                  const SizedBox(height: 16),
                ],

                // Operational KPIs Grid
                _buildKpiGrid(admin, currencyFormat),
                const SizedBox(height: 22),

                // Quick Action Shortcuts Grid
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Live Active Orders Section
                _buildActiveOrdersSection(context, admin),
                const SizedBox(height: 24),

                // Low Stock Critical Alerts Section
                if (lowStockItems.isNotEmpty) ...[
                  _buildLowStockSection(context, admin, lowStockItems),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminProvider admin) {
    final isOpen = admin.settings.isOpen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Store Hub Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),

          // Store Name & Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.settings.storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'STORE OPEN (Accepting Orders)' : 'STORE PAUSED (Closed)',
                      style: TextStyle(
                        color: isOpen ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Switch button
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: isOpen,
              activeTrackColor: const Color(0xFF10B981),
              activeThumbColor: Colors.white,
              onChanged: (val) {
                admin.toggleStoreOpen();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(val ? 'Store is now OPEN for customer orders' : 'Store is now PAUSED'),
                    backgroundColor: val ? const Color(0xFF0D5C3A) : const Color(0xFFB91C1C),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Admin Notification Bell with live unread badge
          InkWell(
            onTap: () {
              context.read<NotificationProvider>().setRoleAndUser(role: 'admin');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<NotificationProvider>(
                builder: (_, notifProv, __) {
                  return notifProv.unreadCount > 0
                      ? Badge(
                          backgroundColor: const Color(0xFFEF4444),
                          label: Text(
                            '${notifProv.unreadCount}',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 20),
                        )
                      : const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 20);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentOrderAlert(BuildContext context, int count) {
    return BouncingButton(
      onTap: () => onNavigateToTab?.call(1), // Switch to Orders tab
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count New Order${count > 1 ? 's' : ''} Awaiting Confirmation!',
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap to review and send to kitchen preparation',
                    style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFDC2626)),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(AdminProvider admin, NumberFormat currencyFormat) {
    return Column(
      children: [
        Row(
          children: [
            // Revenue Card
            Expanded(
              child: _buildKpiCard(
                title: "Today's Gross Sales",
                value: 'Rs ${currencyFormat.format(admin.todayRevenue)}',
                subtitle: '+14.2% vs yesterday',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFD1FAE5),
                trendUp: true,
              ),
            ),
            const SizedBox(width: 12),
            // Orders Card
            Expanded(
              child: _buildKpiCard(
                title: "Today's Orders",
                value: '${admin.todayOrdersCount}',
                subtitle: '${admin.pendingOrdersCount} need action',
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFDBEAFE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Active Deliveries Card
            Expanded(
              child: _buildKpiCard(
                title: 'On Delivery / Ready',
                value: '${admin.activeDeliveriesCount}',
                subtitle: 'Active riders on road',
                icon: Icons.electric_moped_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
              ),
            ),
            const SizedBox(width: 12),
            // Low Stock Card
            Expanded(
              child: _buildKpiCard(
                title: 'Low Stock Alerts',
                value: '${admin.lowStockProductsCount}',
                subtitle: 'Items below 10 qty',
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    bool trendUp = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trendUp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFF059669)),
                      SizedBox(width: 2),
                      Text(
                        'Up',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: trendUp ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Operations',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                label: 'Add Product',
                icon: Icons.add_circle_outline_rounded,
                color: const Color(0xFF0D5C3A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAddEditProductScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                label: 'Orders Queue',
                icon: Icons.assignment_outlined,
                color: const Color(0xFF2563EB),
                onTap: () => onNavigateToTab?.call(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                label: 'Inventory',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF7C3AED),
                onTap: () => onNavigateToTab?.call(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                label: 'Rider Fleet',
                icon: Icons.delivery_dining_outlined,
                color: const Color(0xFFD97706),
                onTap: () => onNavigateToTab?.call(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSection(BuildContext context, AdminProvider admin) {
    final activeOrders = admin.orders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => onNavigateToTab?.call(1),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF0D5C3A),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF0D5C3A)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final order = activeOrders[idx];
            return BouncingButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: order.id)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getStatusBg(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              Text(
                                order.total > 0
                                    ? 'Rs ${order.total.toStringAsFixed(0)}'
                                    : 'As per Market Rate',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D5C3A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.customerName} · ${order.items.length} items',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getStatusColor(order.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLowStockSection(BuildContext context, AdminProvider admin, List lowStockItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_rounded, color: Color(0xFFB45309), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Low Stock Critical Alert',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => onNavigateToTab?.call(2), // Switch to Inventory
                child: const Text('Manage', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lowStockItems.take(2).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.image,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 38,
                          height: 38,
                          color: Colors.amber.shade100,
                          child: const Icon(Icons.fastfood, size: 18, color: Colors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Text('Only ${p.stockQty} ${p.unit} remaining', style: const TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF0D5C3A), size: 24),
                      onPressed: () {
                        admin.adjustStock(p.id, 10);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added 10 units to ${p.name} stock')),
                        );
                      },
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return const Color(0xFFDC2626);
      case OrderStatus.confirmed:
        return const Color(0xFF2563EB);
      case OrderStatus.preparing:
        return const Color(0xFF7C3AED);
      case OrderStatus.ready:
        return const Color(0xFFD97706);
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return const Color(0xFF0284C7);
      case OrderStatus.delivered:
        return const Color(0xFF059669);
      case OrderStatus.cancelled:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBg(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return const Color(0xFFFEE2E2);
      case OrderStatus.confirmed:
        return const Color(0xFFDBEAFE);
      case OrderStatus.preparing:
        return const Color(0xFFEDE9FE);
      case OrderStatus.ready:
        return const Color(0xFFFEF3C7);
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return const Color(0xFFE0F2FE);
      case OrderStatus.delivered:
        return const Color(0xFFD1FAE5);
      case OrderStatus.cancelled:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.fiber_new_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:
        return Icons.kitchen_rounded;
      case OrderStatus.ready:
        return Icons.takeout_dining_rounded;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return Icons.electric_moped_rounded;
      case OrderStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
