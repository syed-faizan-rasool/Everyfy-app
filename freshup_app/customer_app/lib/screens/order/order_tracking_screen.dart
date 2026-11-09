import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_network_image.dart';
import '../cart/cart_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const List<_StepInfo> _trackingSteps = [
    _StepInfo(
      title: 'Order placed',
      subtitle: "We've received your order.",
      icon: Icons.receipt_long_rounded,
    ),
    _StepInfo(
      title: 'Confirmed by store',
      subtitle: 'Store has verified and accepted items.',
      icon: Icons.storefront_rounded,
    ),
    _StepInfo(
      title: 'Rider assigned',
      subtitle: 'A delivery partner has been assigned.',
      icon: Icons.person_pin_circle_rounded,
    ),
    _StepInfo(
      title: 'Picked up',
      subtitle: 'Rider has collected your order.',
      icon: Icons.shopping_bag_outlined,
    ),
    _StepInfo(
      title: 'On the way',
      subtitle: 'Order is on its way to your address.',
      icon: Icons.two_wheeler_rounded,
    ),
    _StepInfo(
      title: 'Delivered',
      subtitle: 'Order has been delivered safely.',
      icon: Icons.done_all_rounded,
    ),
  ];

  late OrderStatus _currentStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollLatestStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollLatestStatus() async {
    try {
      final orders = await ApiService.getOrderHistory();
      final match = orders.where((o) => o.orderNumber == widget.order.orderNumber).firstOrNull;
      if (match != null && match.status != _currentStatus && mounted) {
        setState(() {
          _currentStatus = match.status;
        });
      }
    } catch (_) {}
  }

  int _getStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
      case OrderStatus.onTheWay:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  void _showReceiptSheet(BuildContext context) {
    final order = widget.order;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Receipt',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order ID: #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                  const SizedBox(height: 12),

                  const Text(
                    'Ordered Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) {
                    final itemTotal = item.unitPrice * item.quantity;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: AppNetworkImage(
                                imageUrl: item.product.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity} × ${item.selectedSize ?? 'Standard'}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            itemTotal > 0
                                ? 'PKR ${itemTotal.toStringAsFixed(0)}'
                                : 'Market Rate',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                  const SizedBox(height: 12),

                  // Summary in Receipt
                  _receiptRow('Subtotal', order.subtotal > 0 ? 'PKR ${order.subtotal.toStringAsFixed(0)}' : 'As per Market Rate'),
                  const SizedBox(height: 8),
                  _receiptRow('Delivery Fee', order.deliveryFee == 0 ? 'FREE' : 'PKR ${order.deliveryFee.toStringAsFixed(0)}'),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 8),
                    _receiptRow('Discount', '- PKR ${order.discount.toStringAsFixed(0)}', isGreen: true),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  const SizedBox(height: 12),
                  _receiptRow(
                    'Total Paid',
                    order.total > 0 ? 'PKR ${order.total.toStringAsFixed(0)}' : 'As per Market Rate',
                    isBold: true,
                    fontSize: 17,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, bool isGreen = false, double fontSize = 14, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? (isGreen ? AppColors.success : (isBold ? AppColors.textPrimary : const Color(0xFF1E293B))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final activeIndex = _getStepIndex(_currentStatus);
    final isDelivered = _currentStatus == OrderStatus.delivered;

    final displayPrice = order.total > 0
        ? 'PKR ${order.total.toStringAsFixed(0)}'
        : 'As per Market Rate';

    final paymentText = order.paymentMethod.toLowerCase().contains('online')
        ? 'Online'
        : 'COD';

    final addressText = order.addressText.trim().isNotEmpty
        ? order.addressText.trim()
        : 'new model town, gojra';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 1. Order Header Summary Row Matching Reference Image
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Clock Icon in Soft Amber Circle
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFEF3C7), // soft amber
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF0284C7), // cyan / sky blue as in ref
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Order ID & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentStatus.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDelivered ? AppColors.primary : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Price on Right
              Text(
                displayPrice,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary, // Brand Green
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Estimated Delivery Box Matching Reference Image
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDelivered ? 'Order Delivered Successfully' : 'Arriving in 15–25 min',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Clean Order Tracking Timeline (6 Steps Matching Reference Image)
          ...List.generate(_trackingSteps.length, (index) {
            final step = _trackingSteps[index];
            final isDone = index < activeIndex;
            final isCurrent = index == activeIndex;
            final isLast = index == _trackingSteps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Node & Connecting Line
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        // Node circle
                        if (isDone)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          )
                        else if (isCurrent)
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2.2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                step.icon,
                                size: 17,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),

                        // Vertical connecting line
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isDone ? AppColors.primary : const Color(0xFFE2E8F0),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Step Text Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 2,
                        bottom: isLast ? 8 : 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : (isDone ? FontWeight.w700 : FontWeight.w500),
                              color: (isDone || isCurrent)
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          if (isCurrent || isDone) ...[
                            const SizedBox(height: 3),
                            Text(
                              step.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
          const SizedBox(height: 16),

          // 4. Section: "Order details" Matching Reference Image
          const Text(
            'Order details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Payment Method Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                paymentText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Delivery Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  addressText,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
          const SizedBox(height: 12),

          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                order.subtotal > 0 ? 'PKR ${order.subtotal.toStringAsFixed(0)}' : 'As per Market Rate',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Delivery Fee Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Fee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                order.deliveryFee == 0 ? 'FREE' : 'PKR ${order.deliveryFee.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: order.deliveryFee == 0 ? AppColors.primary : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Est. Delivery Time Row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Est. Delivery Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '15–25 min',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 14),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                displayPrice,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary, // Brand green matching reference total prominence
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 5. "View Receipt" Outlined Button Matching Reference Image
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _showReceiptSheet(context),
              icon: const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.primary),
              label: const Text(
                'View Receipt',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
