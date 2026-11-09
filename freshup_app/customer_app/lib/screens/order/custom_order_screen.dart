import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/everyfy_drawer.dart';
import '../address/address_screen.dart';
import '../cart/cart_screen.dart';
import 'order_success_screen.dart';
import '../../services/meta_analytics_service.dart';

class CustomOrderScreen extends StatefulWidget {
  final bool embedded;
  final ValueChanged<int>? onSwitchTab;
  const CustomOrderScreen({super.key, this.embedded = false, this.onSwitchTab});

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    const text = 'Assalam-o-Alaikum Everyfy! Main Custom Grocery Order krna chahta hu.';
    final uri = Uri.parse('https://wa.me/923089375296?text=${Uri.encodeComponent(text)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _handlePlaceCustomOrder(AuthProvider auth) async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what items you need us to bring.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final addressText = auth.selectedAddress != null
        ? '${auth.selectedAddress!.addressLine}, ${auth.selectedAddress!.area}'
        : 'new model town, gojra';

    final res = await ApiService.placeCustomOrder(
      notes: notes,
      addressText: addressText,
      customerName: auth.name.isNotEmpty ? auth.name : null,
      customerPhone: auth.phone.isNotEmpty ? auth.phone : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      final newOrder = OrderModel.fromJson(Map<String, dynamic>.from(data));

      _notesController.clear();

      // Meta Tracking Event: Purchase (Custom Order)
      MetaAnalyticsService.logPurchase(
        amount: newOrder.total > 0 ? newOrder.total : 120.0,
        orderNumber: newOrder.orderNumber,
        currency: 'PKR',
        additionalParams: {'order_type': 'custom_order'},
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: newOrder),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Failed to place custom order.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final addressText = auth.selectedAddress != null
        ? '${auth.selectedAddress!.addressLine}, ${auth.selectedAddress!.area}'
        : 'new model town st3';

    final contactPhone = auth.phone.trim().isNotEmpty
        ? auth.phone.trim()
        : '03335221600';

    final hasNotes = _notesController.text.trim().isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      drawer: EveryfyDrawer(onSwitchTab: widget.onSwitchTab),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 26),
          onPressed: () {
            if (_scaffoldKey.currentState != null) {
              _scaffoldKey.currentState!.openDrawer();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: const Text(
          'Custom Order',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 24),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Top Card: "Can't find it in the app?" Matching Reference Image 2
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF), // Soft lavender tint as in reference
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shopping bags illustration / icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF8B5CF6), // Purple accent bag icon
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Can't find it in the app?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Describe what you need and we'll pick it up for you.",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. WhatsApp Direct Ordering Quick Card (Requested feature added beautifully)
          InkWell(
            onTap: _openWhatsApp,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prefer WhatsApp Ordering?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Send a handwritten list or voice note directly',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF16A34A)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Section: "What should we bring?" Matching Reference Image 2
          const Text(
            'What should we bring?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Rounded multi-line text input
          TextField(
            controller: _notesController,
            minLines: 5,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1E293B),
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 2 kg mangoes from Sabzi Mandi, a chocolate birthday cake, and a bunch of roses — budget around 3000...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.45,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle instruction
          const Text(
            'Be as specific as you can — brand, size, flavour, quantity, and a budget or shop if you have one in mind.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 24),

          // 4. Order Details Summary Rows Matching Reference Image 2
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressScreen()),
            ),
            child: _buildSummaryRow('Deliver to', addressText, isAddress: true),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Contact', contactPhone),
          const SizedBox(height: 8),
          _buildSummaryRow('Items', 'Confirmed at the shop'),
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery fee', 'PKR 120'),
          const SizedBox(height: 8),
          _buildSummaryRow('Payment', 'Cash on delivery'),

          const SizedBox(height: 16),

          // Notice paragraph matching reference
          const Text(
            'Going somewhere else this time? Update the address in your profile first.\n'
            "We'll check the price and message you before buying. You pay the rider on delivery. Out-of-city orders may cost more.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 28),

          // 5. Primary "Place custom order" Button Matching Reference Image 2
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: hasNotes && !_isSubmitting
                  ? () => _handlePlaceCustomOrder(auth)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Brand green
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Text(
                      'Place custom order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isAddress = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

