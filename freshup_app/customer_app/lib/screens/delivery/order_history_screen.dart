import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_order_model.dart';
import '../../models/order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';

class RiderOrderHistoryScreen extends StatefulWidget {
  final bool embedded;
  const RiderOrderHistoryScreen({super.key, this.embedded = false});

  @override
  State<RiderOrderHistoryScreen> createState() => _RiderOrderHistoryScreenState();
}

class _RiderOrderHistoryScreenState extends State<RiderOrderHistoryScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Completed, 2 = Cancelled

  void _showOrderSummaryModal(BuildContext context, DeliveryOrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status == OrderStatus.delivered ? AppColors.successLight : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: order.status == OrderStatus.delivered ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Drop-off', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Expanded(
                  child: Text(
                    order.address,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Distance Covered', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text('${order.distanceKm} km', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Mode', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Net Earnings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(
                  '+ Rs ${order.earning.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedOrders = context.watch<DeliveryOrderProvider>().completedOrders;

    List<DeliveryOrderModel> filteredList = completedOrders;
    if (_selectedFilter == 1) {
      filteredList = completedOrders.where((o) => o.status == OrderStatus.delivered).toList();
    } else if (_selectedFilter == 2) {
      filteredList = completedOrders.where((o) => o.status == OrderStatus.cancelled).toList();
    }

    final body = Column(
      children: [
        // Filter selection chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _buildFilterChip(0, 'All (${completedOrders.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(
                1,
                'Delivered (${completedOrders.where((o) => o.status == OrderStatus.delivered).length})',
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                2,
                'Cancelled (${completedOrders.where((o) => o.status == OrderStatus.cancelled).length})',
              ),
            ],
          ),
        ),

        // Orders list or empty state
        Expanded(
          child: filteredList.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: 'No delivery records',
                  description: 'Completed or cancelled delivery assignments will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final order = filteredList[i];
                    final isDelivered = order.status == OrderStatus.delivered;

                    return BouncingButton(
                      onTap: () => _showOrderSummaryModal(context, order),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDelivered ? AppColors.primaryLight : AppColors.errorLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        size: 16,
                                        color: isDelivered ? AppColors.primary : AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${order.orderNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDelivered ? AppColors.successLight : AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.status.label,
                                    style: TextStyle(
                                      color: isDelivered ? AppColors.success : AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Customer & Address
                            Text(
                              '${order.customerName} · ${order.address}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),

                            // Items preview
                            Text(
                              order.items.map((it) => '${it.product.name} (x${it.quantity})').join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.divider),
                            const SizedBox(height: 10),

                            // Footer: Date & Earnings
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM d · h:mm a').format(order.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${order.distanceKm} km · ',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      isDelivered ? '+ Rs ${order.earning.toStringAsFixed(0)}' : 'Rs 0',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: isDelivered ? AppColors.primary : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Delivery History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
