import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../address/address_screen.dart';
import '../order/order_success_screen.dart';

enum DeliveryType { delivery, pickup }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryType _deliveryType = DeliveryType.delivery;
  String _paymentMethod = 'cod';
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  double _discount = 0;
  String? _appliedCouponCode;

  @override
  void dispose() {
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon([String? codeToApply]) async {
    final code = (codeToApply ?? _couponController.text).trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final res = await ApiService.applyCoupon(code, cart.subtotal);
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final d = double.tryParse((res['data']['discount'] ?? 0).toString()) ?? 50.0;
      setState(() {
        _discount = d;
        _appliedCouponCode = code;
        _couponController.text = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Coupon $code applied! Rs ${d.toStringAsFixed(0)} discount added.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (code == 'FRESH20') {
      // Local fallback
      setState(() {
        _discount = 50;
        _appliedCouponCode = 'FRESH20';
        _couponController.text = 'FRESH20';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Coupon FRESH20 applied! Rs 50 discount added.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Invalid coupon code. Try FRESH20'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _discount = 0;
      _appliedCouponCode = null;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    final baseDeliveryFee = cart.subtotal >= 1000 ? 0.0 : 100.0;
    final deliveryFee = _deliveryType == DeliveryType.delivery ? baseDeliveryFee : 0.0;
    final total = (cart.subtotal + deliveryFee - _discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Delivery vs Pickup Switcher
          const Text(
            'Fulfillment Method',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: 'Home Delivery',
                  subtitle: '30-45 mins doorstep',
                  icon: Icons.electric_moped_rounded,
                  selected: _deliveryType == DeliveryType.delivery,
                  onTap: () => setState(() => _deliveryType = DeliveryType.delivery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceCard(
                  label: 'Store Pickup',
                  subtitle: 'Ready in 15 mins',
                  icon: Icons.storefront_rounded,
                  selected: _deliveryType == DeliveryType.pickup,
                  onTap: () => setState(() => _deliveryType = DeliveryType.pickup),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delivery Address Card
          if (_deliveryType == DeliveryType.delivery) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressScreen()),
                  ),
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressScreen()),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.selectedAddress != null ? auth.selectedAddress!.label : 'Select an address',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.selectedAddress != null
                                ? '${auth.selectedAddress!.addressLine}, ${auth.selectedAddress!.area}, ${auth.selectedAddress!.city}'
                                : 'Tap here to choose your delivery address',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Payment Methods
          const Text(
            'Payment Method',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          _CustomPaymentTile(
            title: 'Cash on Delivery (COD)',
            subtitle: 'Pay with cash or QR at your doorstep',
            icon: Icons.payments_outlined,
            value: 'cod',
            groupValue: _paymentMethod,
            onSelect: (v) => setState(() => _paymentMethod = v),
          ),
          _CustomPaymentTile(
            title: 'Credit / Debit Card',
            subtitle: 'Visa, Mastercard, PayPak',
            icon: Icons.credit_card_rounded,
            value: 'card',
            groupValue: _paymentMethod,
            onSelect: (v) => setState(() => _paymentMethod = v),
          ),
          _CustomPaymentTile(
            title: 'Mobile Wallet / Digital',
            subtitle: 'JazzCash, Easypaisa, Raast',
            icon: Icons.account_balance_wallet_outlined,
            value: 'wallet',
            groupValue: _paymentMethod,
            onSelect: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: 24),

          // Coupon Code Section
          const Text(
            'Promo / Voucher Code',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          if (_appliedCouponCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code $_appliedCouponCode Applied!',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'You saved Rs 50 on this order',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _removeCoupon,
                    child: const Text('Remove', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter coupon code',
                      prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BouncingButton(
                  onTap: () => _applyCoupon(),
                  child: ElevatedButton(
                    onPressed: () => _applyCoupon(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick-tap coupon chip
            Row(
              children: [
                const Text('Available:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _applyCoupon('FRESH20'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.discount_outlined, size: 12, color: AppColors.accentDark),
                        SizedBox(width: 4),
                        Text(
                          'FRESH20 (Rs 50 OFF)',
                          style: TextStyle(
                            color: AppColors.accentDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Delivery Instructions / Notes
          const Text(
            'Delivery Instructions (Optional)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Leave parcel at front door, ring bell twice...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.note_alt_outlined, color: AppColors.primary, size: 20),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Cost Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                _row('Items Total (${cart.itemCount} items)', cart.subtotal),
                _row(
                  'Delivery Fee',
                  deliveryFee,
                  customValue: deliveryFee == 0 ? 'FREE' : null,
                  isGreen: deliveryFee == 0,
                ),
                if (_discount > 0)
                  _row(
                    'Coupon Discount (FRESH20)',
                    -_discount,
                    isGreen: true,
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),
                _row('Grand Total', total, bold: true),
              ],
            ),
          ),
        ],
      ),

      // Bottom Sticky Place Order Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _submitOrder(cart, auth, deliveryFee),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Place Order · Rs ${total.toStringAsFixed(0)}'),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitOrder(CartProvider cart, AuthProvider auth, double deliveryFee) {
    if (_deliveryType == DeliveryType.delivery && auth.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address first')),
      );
      return;
    }

    final addressText = _deliveryType == DeliveryType.pickup
        ? 'Pickup from Everyfy Hub, Main Boulevard, Lahore'
        : (auth.selectedAddress != null
            ? '${auth.selectedAddress!.addressLine}, ${auth.selectedAddress!.area}, ${auth.selectedAddress!.city}'
            : 'Address');

    final order = context.read<OrderProvider>().placeOrder(
          items: cart.items,
          subtotal: cart.subtotal,
          deliveryFee: deliveryFee,
          discount: _discount,
          paymentMethod: _paymentMethod,
          addressText: addressText,
          orderType: _deliveryType == DeliveryType.pickup ? 'pickup' : 'delivery',
          notes: _notesController.text.trim(),
          couponCode: _appliedCouponCode,
        );

    cart.clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  Widget _row(String label, double amount, {bool bold = false, String? customValue, bool isGreen = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 17 : 14,
      color: isGreen ? AppColors.success : (bold ? AppColors.textPrimary : AppColors.textSecondary),
    );
    final valueText = customValue ?? (amount < 0 ? '- Rs ${(-amount).toStringAsFixed(0)}' : 'Rs ${amount.toStringAsFixed(0)}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? style : const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(valueText, style: style),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomPaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelect;

  const _CustomPaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BouncingButton(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.textPrimary.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
