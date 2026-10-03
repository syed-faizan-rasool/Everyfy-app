import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order_model.dart';
import '../../models/order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final DeliveryOrderModel? order;
  const ActiveDeliveryScreen({super.key, this.order});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final Set<int> _checkedItems = {};

  // Status timeline stages matching the customer order status stages
  static const _timelineSteps = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];

  IconData _getStepIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.shopping_bag_outlined;
      case OrderStatus.confirmed:
        return Icons.thumb_up_alt_outlined;
      case OrderStatus.preparing:
        return Icons.inventory_2_outlined;
      case OrderStatus.ready:
        return Icons.check_box_outlined;
      case OrderStatus.pickedUp:
        return Icons.shopping_basket_outlined;
      case OrderStatus.onTheWay:
        return Icons.electric_moped_rounded;
      case OrderStatus.delivered:
        return Icons.done_all_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  void _showCancelDialog(BuildContext context, DeliveryOrderProvider provider) {
    String selectedReason = 'Customer unreachable';
    final reasons = [
      'Customer unreachable',
      'Vehicle breakdown / puncture',
      'Wrong delivery address',
      'Store closed or out of stock',
      'Emergency personal reason',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cancel Active Delivery', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select a valid reason for cancelling this delivery assignment:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              for (final r in reasons)
                InkWell(
                  onTap: () => setDialogState(() => selectedReason = r),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == r ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: selectedReason == r ? AppColors.error : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Delivery', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.cancelActiveOrder(selectedReason);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delivery cancelled: $selectedReason'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(100, 42),
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAdvanceStatus(BuildContext context, DeliveryOrderProvider provider, DeliveryOrderModel activeOrder) {
    final currentStatus = activeOrder.status;

    if (currentStatus == OrderStatus.onTheWay) {
      // Final delivery completion
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Complete Delivery', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeOrder.paymentMethod.contains('Cash')
                    ? 'Please collect Rs ${activeOrder.total.toStringAsFixed(0)} in cash from the customer before handing over the package.'
                    : 'This order is already paid online (${activeOrder.paymentMethod}). Please hand over the parcel to ${activeOrder.customerName}.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You earned Rs ${activeOrder.earning.toStringAsFixed(0)} on this delivery!',
                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.advanceActiveOrderStatus();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order #${activeOrder.orderNumber} successfully delivered! Earned Rs ${activeOrder.earning.toStringAsFixed(0)}'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(130, 44),
              ),
              child: const Text('Confirm Delivered'),
            ),
          ],
        ),
      );
    } else {
      provider.advanceActiveOrderStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to: ${provider.activeOrder?.status.label ?? "Updated"}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryOrderProvider>();
    final activeOrder = provider.activeOrder ?? widget.order;

    if (activeOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Delivery')),
        body: const Center(
          child: EmptyStateWidget(
            icon: Icons.electric_moped_rounded,
            title: 'No Active Delivery',
            description: 'You do not have any active delivery at the moment. Accept an order from the available list to start.',
          ),
        ),
      );
    }

    final currentIndex = _timelineSteps.indexOf(activeOrder.status);
    final activeIndex = currentIndex == -1 ? 3 : currentIndex; // default to ready if not found

    String actionButtonLabel;
    IconData actionButtonIcon;
    Color actionButtonColor = AppColors.primary;

    if (activeOrder.status == OrderStatus.ready ||
        activeOrder.status == OrderStatus.placed ||
        activeOrder.status == OrderStatus.confirmed ||
        activeOrder.status == OrderStatus.preparing) {
      actionButtonLabel = 'Confirm Pickup from Hub';
      actionButtonIcon = Icons.shopping_basket_rounded;
      actionButtonColor = AppColors.primary;
    } else if (activeOrder.status == OrderStatus.pickedUp) {
      actionButtonLabel = 'Start Delivery (On the way)';
      actionButtonIcon = Icons.electric_moped_rounded;
      actionButtonColor = AppColors.accent;
    } else {
      actionButtonLabel = activeOrder.paymentMethod.contains('Cash')
          ? 'Collect Rs ${activeOrder.total.toStringAsFixed(0)} & Deliver'
          : 'Mark Order Delivered';
      actionButtonIcon = Icons.check_circle_rounded;
      actionButtonColor = AppColors.success;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Active: #${activeOrder.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            tooltip: 'Cancel Delivery',
            onPressed: () => _showCancelDialog(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Delivery Status Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getStepIcon(activeOrder.status),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Stage',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeOrder.status.label,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Earn Rs ${activeOrder.earning.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Order Progress Timeline (Exact match with customer stages)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Stage Timeline',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Shared with Customer',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < _timelineSteps.length; i++)
                  _RiderTimelineTile(
                    label: _timelineSteps[i].label,
                    icon: _getStepIcon(_timelineSteps[i]),
                    isDone: i <= activeIndex,
                    isCurrent: i == activeIndex,
                    isLast: i == _timelineSteps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Customer Direct Contact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    activeOrder.customerName.isNotEmpty ? activeOrder.customerName[0] : 'C',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeOrder.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeOrder.customerPhone,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                BouncingButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling customer ${activeOrder.customerPhone}...')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.call_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                BouncingButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening SMS to ${activeOrder.customerPhone}...')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Destination & Route Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.navigation_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Destination Route',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      '${activeOrder.distanceKm} km away',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  activeOrder.address,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
                ),
                if (activeOrder.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Instructions: "${activeOrder.notes}"',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Google Maps navigation...')),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Open in Google Maps'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Item Checklist
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Item Checklist',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${_checkedItems.length}/${activeOrder.items.length} verified',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < activeOrder.items.length; i++)
                  CheckboxListTile(
                    value: _checkedItems.contains(i),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: Text(
                      '${activeOrder.items[i].product.name} × ${activeOrder.items[i].quantity}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: _checkedItems.contains(i) ? TextDecoration.lineThrough : null,
                        color: _checkedItems.contains(i) ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Unit: ${activeOrder.items[i].product.unit}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _checkedItems.add(i);
                        } else {
                          _checkedItems.remove(i);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Advance Status Action Button
          BouncingButton(
            onTap: () => _handleAdvanceStatus(context, provider, activeOrder),
            child: ElevatedButton.icon(
              onPressed: () => _handleAdvanceStatus(context, provider, activeOrder),
              icon: Icon(actionButtonIcon, size: 20),
              label: Text(actionButtonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionButtonColor,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RiderTimelineTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _RiderTimelineTile({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone ? (isCurrent ? AppColors.primary : AppColors.primaryLight) : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? AppColors.primary : AppColors.cardBorder,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isDone ? (isCurrent ? icon : Icons.check_rounded) : icon,
                  size: 16,
                  color: isDone ? (isCurrent ? Colors.white : AppColors.primary) : AppColors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? AppColors.primary : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w800 : (isDone ? FontWeight.w600 : FontWeight.w500),
                      fontSize: 14,
                      color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
