import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/app_network_image.dart';
import '../address/address_screen.dart';
import '../checkout/checkout_screen.dart';
import '../home/home_screen.dart';

class CartScreen extends StatefulWidget {
  final bool embedded; // true when shown inside bottom-nav tab
  final VoidCallback? onStartShopping;
  const CartScreen({super.key, this.embedded = false, this.onStartShopping});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _appliedPromoCode;
  double _promoDiscount = 0.0;
  final TextEditingController _promoInputController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedPaymentMethod = 'cod'; // 'cod' or 'online'

  @override
  void dispose() {
    _promoInputController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openPromoSheet(CartProvider cart) async {
    _promoInputController.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Apply Promo Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promoInputController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter promo code (e.g. FRESH20)',
                  prefixIcon: const Icon(Icons.discount_outlined, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final code = _promoInputController.text.trim().toUpperCase();
                    if (code.isEmpty) return;
                    Navigator.pop(ctx);
                    await _applyPromo(code, cart.subtotal);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyPromo('FRESH20', cart.subtotal);
                  },
                  icon: const Icon(Icons.local_offer_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Use FRESH20 (Rs 50 OFF)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _applyPromo(String code, double subtotal) async {
    final res = await ApiService.applyCoupon(code, subtotal);
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final d = double.tryParse((res['data']['discount'] ?? 0).toString()) ?? 50.0;
      setState(() {
        _appliedPromoCode = code;
        _promoDiscount = d;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Promo $code applied! Rs ${d.toStringAsFixed(0)} saved.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (code == 'FRESH20') {
      setState(() {
        _appliedPromoCode = 'FRESH20';
        _promoDiscount = 50.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Promo FRESH20 applied! Rs 50 saved.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Invalid promo code. Try FRESH20'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromoCode = null;
      _promoDiscount = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promo removed'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _confirmClearCart(CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cart.clearCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    // Delivery Fee calculation
    final deliveryFee = cart.subtotal >= 1000 ? 0.0 : 120.0;
    final grandTotal = (cart.subtotal + deliveryFee - _promoDiscount).clamp(0.0, double.infinity);

    final totalItemsCount = cart.items.fold<int>(0, (sum, i) => sum + i.quantity);

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: !widget.embedded && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(
            'Your Cart',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        body: EmptyStateWidget(
          icon: Icons.shopping_basket_outlined,
          title: 'Your cart is empty',
          description: 'Looks like you haven\'t added any groceries yet. Discover fresh items and get them delivered fast!',
          buttonText: 'Start Shopping',
          onButtonPressed: () {
            if (widget.onStartShopping != null) {
              widget.onStartShopping!();
            } else if (!widget.embedded && Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: !widget.embedded && Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 24),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Your Cart',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (auth.selectedAddress != null)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressScreen()),
              ),
              icon: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
              label: Text(
                auth.selectedAddress!.area.isNotEmpty ? auth.selectedAddress!.area : 'Gojra',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Item Count Subtitle (Matching Reference Image)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$totalItemsCount ${totalItemsCount == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          // 2. Cart Items List Matching Reference
          ...cart.items.map((item) {
            final itemTotal = item.unitPrice * item.quantity;
            final isMarketPrice = item.unitPrice <= 0;
            final priceDisplay = isMarketPrice
                ? 'Market Rate'
                : 'PKR ${itemTotal.toStringAsFixed(0)}';

            final unitDisplay = isMarketPrice
                ? '${item.quantity} × As per market price'
                : '${item.quantity} × PKR ${item.unitPrice.toStringAsFixed(0)}';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Thumbnail (AppNetworkImage so never broken)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFF8FAFC),
                      child: AppNetworkImage(
                        imageUrl: item.product.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Item Title & Unit price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unitDisplay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (item.selectedSize != null && item.selectedSize!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.selectedSize!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right Side: Price & Compact Stepper Pill (Matching Reference)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stepper Pill: [-  1  +]
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => cart.decreaseCartItem(item),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Icon(Icons.remove, size: 15, color: AppColors.primary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => cart.addToCart(
                                item.product,
                                size: item.selectedSize,
                                price: item.customPrice,
                                instructions: item.instructions,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Icon(Icons.add, size: 15, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
          const SizedBox(height: 16),

          // 3. Pristine, Elegant Rate List / Pricing Summary (Clean, spacious, unmessy)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRateRow(
                  'Subtotal',
                  'PKR ${cart.subtotal.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF1E293B),
                ),
                const SizedBox(height: 8),
                _buildRateRow(
                  'Delivery fee',
                  deliveryFee == 0 ? 'FREE' : 'PKR ${deliveryFee.toStringAsFixed(0)}',
                  valueColor: deliveryFee == 0 ? AppColors.primary : const Color(0xFF1E293B),
                ),
                const SizedBox(height: 8),
                _buildRateRow(
                  'Est. delivery time',
                  '10–15 min',
                  valueColor: const Color(0xFF1E293B),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Market fluctuations included in final receipt.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_promoDiscount > 0) ...[
                  const SizedBox(height: 8),
                  _buildRateRow(
                    'Promo Discount ($_appliedPromoCode)',
                    '- PKR ${_promoDiscount.toStringAsFixed(0)}',
                    valueColor: AppColors.primary,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                const SizedBox(height: 12),
                _buildRateRow(
                  'Estimated total',
                  'PKR ${grandTotal.toStringAsFixed(0)}',
                  isBold: true,
                  fontSize: 18,
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ),

          // Promo pill tap
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openPromoSheet(cart),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _appliedPromoCode == null ? 'Have a promo code? Tap to apply' : 'Promo applied: $_appliedPromoCode',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  if (_appliedPromoCode != null) ...[
                    const Spacer(),
                    InkWell(
                      onTap: _removePromo,
                      child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
          const SizedBox(height: 16),

          // 4. "Add a note" Section Matching Reference Image
          const Text(
            'Add a note',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Any special instructions? e.g. ice-cream flavor, spice level, no onions...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. "Payment method" Section Matching Reference Image
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Cash on delivery pill
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'cod'
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPaymentMethod == 'cod'
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'Cash on delivery',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedPaymentMethod == 'cod'
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Online pill
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedPaymentMethod = 'online'),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'online'
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPaymentMethod == 'online'
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedPaymentMethod == 'online'
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 6. Action Buttons: "Place COD order" and "Clear cart" Stacked
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      initialCoupon: _appliedPromoCode,
                      initialDiscount: _promoDiscount,
                      initialNote: _noteController.text.trim(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _selectedPaymentMethod == 'cod' ? 'Place COD order' : 'Proceed to Checkout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary "Clear cart" button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _confirmClearCart(cart),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Clear cart',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRateRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 15,
    Color? valueColor,
  }) {
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
            color: valueColor ?? (isBold ? AppColors.textPrimary : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
