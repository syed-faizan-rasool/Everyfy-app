import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/meta_analytics_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_network_image.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final String heroPrefix;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.heroPrefix = 'popular',
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  int _selectedSizeIndex = 0;
  bool _isSizeExpanded = true;
  int _quantity = 1;
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sizes = widget.product.effectiveSizes;
    if (sizes.isNotEmpty) {
      final oneKgIndex = sizes.indexWhere(
        (s) => s.name.toLowerCase().trim() == '1 kg' || s.name.toLowerCase().contains('1 kg'),
      );
      if (oneKgIndex != -1) {
        _selectedSizeIndex = oneKgIndex;
      } else {
        _selectedSizeIndex = 0;
      }
    }

    // Meta Tracking Event: ViewContent
    MetaAnalyticsService.logViewContent(
      id: widget.product.id.toString(),
      title: widget.product.name,
      price: widget.product.effectivePrice,
      currency: 'PKR',
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final sizes = product.effectiveSizes;
    final selectedOption = (sizes.isNotEmpty && _selectedSizeIndex < sizes.length)
        ? sizes[_selectedSizeIndex]
        : ProductSizeOption(name: 'Standard', price: product.finalPrice);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Product Image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              // Cart Button with Badge
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.textPrimary),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cart.itemCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Close / Cross icon
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFF8FAFC),
                alignment: Alignment.center,
                child: Hero(
                  tag: '${widget.heroPrefix}_product_${product.id}',
                  child: Center(
                    child: AppNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      width: 260,
                      height: 260,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Details Body Matching Reference Image Exactly
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Loyalty Points Banner (Reference style with medal icon)
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFEF3C7),
                          border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.stars_rounded, size: 15, color: Color(0xFFB45309)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Earn 4% loyalty points on this product!',
                          style: TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Product Title & Favorite Icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() => _isFavorite = !_isFavorite);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 24,
                            color: _isFavorite ? Colors.red : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 3. Price Subtitle ("from Rs. 420.00" or "Rs: as per market price")
                  Text(
                    product.isPriceDecided && product.finalPrice > 0
                        ? 'from Rs. ${product.finalPrice.toStringAsFixed(2)}'
                        : 'Rs: as per market price',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 4. Product Description (Directly below price, just like reference)
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'Fresh, premium quality produce carefully sourced and delivered to your doorstep in minutes.',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                  const SizedBox(height: 12),

                  // 5. Select Your Size (Required) Section Header
                  InkWell(
                    onTap: () => setState(() => _isSizeExpanded = !_isSizeExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Select Your Size ',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '(Required)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Please select any one option',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _isSizeExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textPrimary,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Clean Unboxed Radio Options List (Matching Reference Image Exactly)
                  if (_isSizeExpanded) ...[
                    const SizedBox(height: 8),
                    ...List.generate(sizes.length, (index) {
                      final opt = sizes[index];
                      final isSelected = _selectedSizeIndex == index;
                      final optPriceText = opt.price > 0
                          ? 'Rs. ${opt.price.toStringAsFixed(2)}'
                          : 'As per Market Rate';

                      return InkWell(
                        onTap: () => setState(() => _selectedSizeIndex = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              // Radio circle
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                                    width: isSelected ? 6.5 : 1.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Option Name
                              Expanded(
                                child: Text(
                                  opt.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              // Price on the right
                              Text(
                                optPriceText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                  const SizedBox(height: 16),

                  // 7. Special instructions Section
                  const Text(
                    'Special instructions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add any special instructions for your order',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter your instructions here',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // 8. Bottom Floating Action Bar Matching Reference
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Circular Quantity Stepper: [-] 1 [+]
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minus Button
                  InkWell(
                    onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _quantity > 1 ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: _quantity > 1 ? AppColors.primary : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Plus Button
                  InkWell(
                    onTap: () => setState(() => _quantity++),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Expanded "Add to Cart" Button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final chosenPrice = (selectedOption.price > 0)
                          ? selectedOption.price
                          : product.finalPrice;

                      for (int i = 0; i < _quantity; i++) {
                        cart.addToCart(
                          product,
                          size: selectedOption.name,
                          price: chosenPrice,
                          instructions: _instructionsController.text.trim(),
                        );
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Added $_quantity × ${product.name} to cart!'),
                              ),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
