import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/app_colors.dart';
import '../address/address_screen.dart';
import '../order/order_success_screen.dart';
import '../../services/meta_analytics_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String? initialCoupon;
  final double initialDiscount;
  final String? initialNote;

  const CheckoutScreen({
    super.key,
    this.initialCoupon,
    this.initialDiscount = 0.0,
    this.initialNote,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _discount = 0.0;
  String? _appliedCouponCode;
  String _selectedDeliverySlot = 'ASAP (30 - 45 Mins)';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _discount = widget.initialDiscount;
    _appliedCouponCode = widget.initialCoupon;
    if (widget.initialNote != null && widget.initialNote!.isNotEmpty) {
      _notesController.text = widget.initialNote!;
    }

    // Real-time prefill customer data
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      if (auth.name.isNotEmpty && auth.name != 'Customer') {
        _nameController.text = auth.name;
      }
      _emailController.text = auth.email;

      String cleanPhone = auth.phone;
      if (cleanPhone.startsWith('+92')) {
        cleanPhone = cleanPhone.substring(3).trim();
      } else if (cleanPhone.startsWith('92')) {
        cleanPhone = cleanPhone.substring(2).trim();
      } else if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1).trim();
      }
      _phoneController.text = cleanPhone;
    }

    // Meta Tracking Event: InitiateCheckout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cart = context.read<CartProvider>();
        MetaAnalyticsService.logInitiateCheckout(
          totalPrice: cart.subtotal,
          numItems: cart.itemCount,
          currency: 'PKR',
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _chooseDeliverySlot() {
    final slots = [
      'ASAP (30 - 45 Mins)',
      'Within 2 Hours',
      'Today Evening (6:00 PM - 9:00 PM)',
      'Tomorrow Morning (9:00 AM - 12:00 PM)',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Delivery Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...slots.map((s) {
                final isSelected = s == _selectedDeliverySlot;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(
                    s,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedDeliverySlot = s);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _submitOrder(CartProvider cart, AuthProvider auth, double deliveryFee) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    if (auth.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a delivery address')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final address = auth.selectedAddress!;
    final addressText = '${address.addressLine}, ${address.area}, ${address.city}';
    final formattedPhone = phone.startsWith('+92') ? phone : '+92$phone';

    String combinedNotes = 'Delivery Slot: $_selectedDeliverySlot';
    if (_notesController.text.trim().isNotEmpty) {
      combinedNotes += ' | Instructions: ${_notesController.text.trim()}';
    }

    final order = context.read<OrderProvider>().placeOrder(
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryFee: deliveryFee,
      discount: _discount,
      paymentMethod: 'cod',
      addressText: addressText,
      orderType: 'delivery',
      notes: combinedNotes,
      couponCode: _appliedCouponCode,
      customerName: name,
      customerPhone: formattedPhone,
    );

    cart.clearCart();
    context.read<NotificationProvider>().fetchNotifications(silent: true);

    // Meta Tracking Event: Purchase (Order Value in PKR)
    MetaAnalyticsService.logPurchase(
      amount: order.total,
      orderNumber: order.orderNumber,
      numItems: order.items.length,
      currency: 'PKR',
    );

    setState(() => _isSubmitting = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    // Real-time Delivery Fee & Calculation
    final deliveryFee = cart.subtotal >= 1000 ? 0.0 : 150.0;
    final grandTotal = (cart.subtotal + deliveryFee - _discount).clamp(0.0, double.infinity);

    final addressText = auth.selectedAddress != null
        ? '${auth.selectedAddress!.addressLine}, ${auth.selectedAddress!.area}'
        : 'Tap to add address';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Customer Name Field (Matching Reference Image)
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Phone Field with Pakistan Flag Prefix (Matching Reference Image)
          Row(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: const Row(
                  children: [
                    Text('🇵🇰', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Text('+92', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '3001234567',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Email Field (Matching Reference Image)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Delivery Address Card (Matching Reference Image)
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressScreen()),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          addressText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Order Instructions (Matching Reference Image)
          const Text(
            '+ Add any instructions for your order',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Leave parcel at front door, ring bell twice...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Payment Method Section (COD Active, Others Faded & Disabled as requested)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wallet_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Cash on Delivery (COD) - ACTIVE
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.radio_button_checked_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COD (Cash on Delivery)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pay with cash upon receipt',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Credit / Debit Card - FADED & UNCLICKABLE
                Opacity(
                  opacity: 0.40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.radio_button_off_rounded, color: Color(0xFF94A3B8), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit / Debit Card',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Temporarily Unavailable',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Unavailable',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // JazzCash / EasyPaisa - FADED & UNCLICKABLE
                Opacity(
                  opacity: 0.40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.radio_button_off_rounded, color: Color(0xFF94A3B8), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'JazzCash / EasyPaisa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Coming Soon',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Coming Soon',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7. Estimated Delivery Time Section (Matching Reference Image)
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Estimated Delivery Time',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDeliverySlot,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton(
                onPressed: _chooseDeliverySlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Choose', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 12),

          // 8. Cost Breakdown Section (Matching Reference Image)
          _priceRow('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _priceRow(
            'Delivery Fee',
            deliveryFee == 0 ? 'FREE' : 'Rs. ${deliveryFee.toStringAsFixed(2)}',
            isGreen: deliveryFee == 0,
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 6),
            _priceRow(
              'Discount (${_appliedCouponCode ?? "Promo"})',
              '- Rs. ${_discount.toStringAsFixed(2)}',
              isGreen: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
          ),
          _priceRow(
            'Grand Total',
            'Rs. ${grandTotal.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 18,
          ),

          const SizedBox(height: 120), // Spacing for bottom button
        ],
      ),

      // 9. Bottom Sticky Confirm Order Button (Matching Reference Image)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              onPressed: _isSubmitting ? null : () => _submitOrder(cart, auth, deliveryFee),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Confirm Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false, bool isGreen = false, double fontSize = 14}) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      color: isGreen ? AppColors.success : (isBold ? AppColors.textPrimary : AppColors.textSecondary),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: isBold ? AppColors.textPrimary : AppColors.textSecondary)),
        Text(value, style: style),
      ],
    );
  }
}
