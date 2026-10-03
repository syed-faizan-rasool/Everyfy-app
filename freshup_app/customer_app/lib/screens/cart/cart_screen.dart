import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final bool embedded; // true when shown inside bottom-nav tab
  const CartScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final body = cart.isEmpty
        ? EmptyStateWidget(
            icon: Icons.shopping_basket_outlined,
            title: 'Your cart is empty',
            description: 'Looks like you haven\'t added any groceries yet. Discover fresh items and get them delivered fast!',
            buttonText: 'Start Shopping',
            onButtonPressed: () {
              if (embedded) {
                // If embedded, you can notify or user can tap Home tab
              } else {
                Navigator.pop(context);
              }
            },
          )
        : Column(
            children: [
              // Free Delivery Progress Banner
              _FreeDeliveryBanner(subtotal: cart.subtotal),

              // Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.product.image,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ShimmerBox(width: 72, height: 72),
                              errorWidget: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: AppColors.background,
                                child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                  item.product.unit,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rs ${item.product.finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                BouncingButton(
                                  onTap: () => cart.decreaseQuantity(item.product),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.remove_rounded, size: 16, color: AppColors.primary),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                BouncingButton(
                                  onTap: () => cart.addToCart(item.product),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Summary & Checkout CTA
              _CartSummary(cart: cart),
            ],
          );

    if (embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Cart',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (!cart.isEmpty)
                  TextButton(
                    onPressed: () => cart.clearCart(),
                    child: const Text('Clear All', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => cart.clearCart(),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _FreeDeliveryBanner extends StatelessWidget {
  final double subtotal;
  const _FreeDeliveryBanner({required this.subtotal});

  static const double freeDeliveryThreshold = 1000.0;

  @override
  Widget build(BuildContext context) {
    final remaining = freeDeliveryThreshold - subtotal;
    final isFree = remaining <= 0;
    final progress = (subtotal / freeDeliveryThreshold).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFree ? AppColors.successLight : AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFree
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.check_circle_rounded : Icons.local_shipping_outlined,
                size: 18,
                color: isFree ? AppColors.success : AppColors.accentDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? '🎉 Congratulations! You unlocked FREE Delivery'
                      : 'Add Rs ${remaining.toStringAsFixed(0)} more for FREE delivery!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isFree ? AppColors.success : AppColors.accentDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFree ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final deliveryFee = cart.subtotal >= 1000 ? 0.0 : 100.0;
    final total = cart.subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Item Total', 'Rs ${cart.subtotal.toStringAsFixed(0)}'),
            _row(
              'Delivery Fee',
              deliveryFee == 0 ? 'FREE' : 'Rs ${deliveryFee.toStringAsFixed(0)}',
              isGreen: deliveryFee == 0,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.divider),
            ),
            _row('Grand Total', 'Rs ${total.toStringAsFixed(0)}', bold: true),
            const SizedBox(height: 16),
            BouncingButton(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Proceed to Checkout · Rs ${total.toStringAsFixed(0)}'),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool isGreen = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 17 : 14,
      color: isGreen ? AppColors.success : AppColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? style : const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
