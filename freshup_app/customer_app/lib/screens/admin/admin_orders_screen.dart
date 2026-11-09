import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_model.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/animated_widgets.dart';
import '../../services/order_receipt_service.dart';
import '../../widgets/order_slip_preview_sheet.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterTabs = [
    'All',
    'Placed',
    'Preparing',
    'Ready',
    'On The Way',
    'Delivered',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allOrders = admin.orders;

    final filteredOrders = allOrders.where((order) {
      // Tab filter
      bool matchesTab = true;
      if (_selectedFilter == 'Placed') {
        matchesTab = order.status == OrderStatus.placed;
      } else if (_selectedFilter == 'Preparing') {
        matchesTab = order.status == OrderStatus.preparing;
      } else if (_selectedFilter == 'Ready') {
        matchesTab = order.status == OrderStatus.ready;
      } else if (_selectedFilter == 'On The Way') {
        matchesTab = order.status == OrderStatus.onTheWay || order.status == OrderStatus.pickedUp;
      } else if (_selectedFilter == 'Delivered') {
        matchesTab = order.status == OrderStatus.delivered;
      } else if (_selectedFilter == 'Cancelled') {
        matchesTab = order.status == OrderStatus.cancelled;
      }

      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        matchesSearch = order.orderNumber.toLowerCase().contains(q) ||
            order.customerName.toLowerCase().contains(q) ||
            order.customerPhone.contains(q);
      }

      return matchesTab && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Live Orders Pipeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search order #, customer, phone...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterTabs.map((tab) {
                      final isSelected = _selectedFilter == tab;
                      final count = _getOrderCountForTab(allOrders, tab);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            count > 0 ? '$tab ($count)' : tab,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: const Color(0xFF0D5C3A),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0D5C3A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedFilter = tab);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final order = filteredOrders[idx];
                      return _buildOrderCard(context, admin, order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _getOrderCountForTab(List<AdminOrderModel> orders, String tab) {
    if (tab == 'All') return orders.length;
    if (tab == 'Placed') return orders.where((o) => o.status == OrderStatus.placed).length;
    if (tab == 'Preparing') return orders.where((o) => o.status == OrderStatus.preparing).length;
    if (tab == 'Ready') return orders.where((o) => o.status == OrderStatus.ready).length;
    if (tab == 'On The Way') {
      return orders.where((o) => o.status == OrderStatus.onTheWay || o.status == OrderStatus.pickedUp).length;
    }
    if (tab == 'Delivered') return orders.where((o) => o.status == OrderStatus.delivered).length;
    if (tab == 'Cancelled') return orders.where((o) => o.status == OrderStatus.cancelled).length;
    return 0;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found for "$_selectedFilter"',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Incoming orders will appear here in real-time',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    return BouncingButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: order.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: order.status == OrderStatus.placed ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
            width: order.status == OrderStatus.placed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order #, Time & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.paymentMethod.contains('Cash') ? 'COD' : 'Paid Card',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 19, color: Color(0xFF0D5C3A)),
                      tooltip: 'Print Rider Slip',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => OrderSlipPreviewSheet.show(context, order, admin.settings),
                    ),
                    const SizedBox(width: 4),
                    _buildStatusBadge(order.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer info
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  order.customerName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const Spacer(),
                Text(
                  order.customerPhone,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Assigned Rider info if any
            if (order.assignedRiderName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.electric_moped_rounded, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      'Rider: ${order.assignedRiderName}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            // Footer: Items count, Total price, and Action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} items',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      order.total > 0
                          ? 'Rs ${order.total.toStringAsFixed(0)}'
                          : 'As per Market Rate',
                      style: TextStyle(
                        fontSize: order.total > 0 ? 16 : 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D5C3A),
                      ),
                    ),
                  ],
                ),
                _buildQuickActionBtn(context, admin, order),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    if (order.status == OrderStatus.placed) {
      return ElevatedButton(
        onPressed: () {
          admin.updateOrderStatus(order.id, OrderStatus.preparing);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order ${order.orderNumber} sent to Kitchen Preparing')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D5C3A),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Accept & Prepare', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
    } else if (order.status == OrderStatus.preparing) {
      return ElevatedButton(
        onPressed: () {
          admin.updateOrderStatus(order.id, OrderStatus.ready);
          _showReadyAndPrintPrompt(context, admin, order);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Mark Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
    } else if (order.status == OrderStatus.ready) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () => OrderSlipPreviewSheet.show(context, order, admin.settings),
            icon: const Icon(Icons.print_rounded, size: 14),
            label: const Text('Slip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D5C3A),
              side: const BorderSide(color: Color(0xFF0D5C3A)),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openAssignRiderSheet(context, admin, order.id),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
            label: const Text('Assign Rider', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.onTheWay) {
      return OutlinedButton(
        onPressed: () {
          admin.updateOrderStatus(order.id, OrderStatus.delivered);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order ${order.orderNumber} marked Delivered')),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF059669),
          side: const BorderSide(color: Color(0xFF10B981)),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Mark Delivered', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
    }

    return const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8));
  }

  void _showReadyAndPrintPrompt(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Order ${order.orderNumber} is Ready!',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Print the dispatch slip to attach to the grocery bag for the delivery rider.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        OrderSlipPreviewSheet.show(context, order, admin.settings);
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Preview Slip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        OrderReceiptService.printOrderSlip(context, order, admin.settings);
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Rider Slip', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openAssignRiderSheet(context, admin, order.id);
                  },
                  icon: const Icon(Icons.electric_moped_rounded, size: 18, color: Color(0xFF2563EB)),
                  label: const Text('Assign Delivery Rider', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAssignRiderSheet(BuildContext context, AdminProvider admin, String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final fleet = admin.fleet;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Rider',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Assign an active rider to dispatch this order',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...fleet.map((rider) {
                final isAvailable = rider.status == FleetDutyStatus.available;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.electric_moped_rounded,
                          color: isAvailable ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            Text(
                              '${rider.vehicle} · ⭐ ${rider.rating}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          admin.assignRiderToOrder(orderId, rider.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Assigned ${rider.name} to order')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C3A),
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.placed:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case OrderStatus.confirmed:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case OrderStatus.preparing:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        break;
      case OrderStatus.ready:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        break;
      case OrderStatus.delivered:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        break;
      case OrderStatus.cancelled:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
