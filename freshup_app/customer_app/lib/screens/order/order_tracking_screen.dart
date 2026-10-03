import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  // NOTE: In production, poll GET /orders/{id} every few seconds (or use
  // Firebase/websocket push) to update `order.status` live, and show the
  // delivery boy's live location on a map once status = onTheWay.
  static const _steps = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.preparing,
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(order.status);
    final activeIndex = currentIndex == -1 ? 0 : currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Estimated Delivery Status Header Card
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
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Delivery',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '25 - 35 Minutes',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Order Progress Timeline Card
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
                const Text(
                  'Order Timeline',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < _steps.length; i++)
                  _TimelineTile(
                    label: _steps[i].label,
                    icon: _getStepIcon(_steps[i]),
                    isDone: i <= activeIndex,
                    isCurrent: i == activeIndex,
                    isLast: i == _steps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Delivery Rider Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed Khan (Delivery Partner)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('4.9 · Honda CD70 (LEB-4921)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                BouncingButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling delivery partner...')),
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Delivery Address & Order Receipt Card
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
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Delivering To',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    order.addressText,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.divider),
                ),
                const Text(
                  'Items in this Order',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.product.name} × ${item.quantity}',
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          'Rs ${item.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: AppColors.divider),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('Rs ${order.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('Rs ${order.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                if (order.discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount', style: TextStyle(color: AppColors.success, fontSize: 13)),
                      Text('- Rs ${order.discount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      'Rs ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineTile({
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
              padding: const EdgeInsets.only(top: 4, bottom: 22),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : (isDone ? FontWeight.w600 : FontWeight.w500),
                  fontSize: 14,
                  color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
