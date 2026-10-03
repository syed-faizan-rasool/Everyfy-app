import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Big Hero Product Image
          SliverAppBar(
            expandedHeight: 340,
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
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: _isFavorite ? AppColors.error : AppColors.textPrimary,
                    ),
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: '${widget.heroPrefix}_product_${product.id}',
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported_outlined, size: 50, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sale badge if present
                  if (product.hasDiscount) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Save Rs ${(product.price - product.finalPrice).toStringAsFixed(0)} · Special Offer',
                        style: const TextStyle(
                          color: AppColors.accentDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Product Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Unit
                  Text(
                    'Net weight: ${product.unit}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Row & Stock Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Rs ${product.finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Rs ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: product.inStock ? AppColors.successLight : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: product.inStock ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.inStock ? 'In Stock (${product.stockQty})' : 'Out of Stock',
                              style: TextStyle(
                                color: product.inStock ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Highlights / Perks
                  Row(
                    children: [
                      _highlightItem(Icons.bolt_rounded, '30 Mins', 'Fast Delivery'),
                      const SizedBox(width: 12),
                      _highlightItem(Icons.eco_rounded, '100% Fresh', 'Quality Promise'),
                      const SizedBox(width: 12),
                      _highlightItem(Icons.verified_user_outlined, 'Hygenic', 'Safety Assured'),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Product Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 120), // Spacing for floating bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar with Action buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          child: qty == 0
              ? BouncingButton(
                  onTap: product.inStock ? () => cart.addToCart(product) : null,
                  child: ElevatedButton.icon(
                    onPressed: product.inStock ? () => cart.addToCart(product) : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: Text(
                      product.inStock
                          ? 'Add to Cart · Rs ${product.finalPrice.toStringAsFixed(0)}'
                          : 'Currently Unavailable',
                    ),
                  ),
                )
              : Row(
                  children: [
                    // Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => cart.decreaseQuantity(product),
                            icon: const Icon(Icons.remove_rounded, color: AppColors.primary),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => cart.addToCart(product),
                            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Go to Cart
                    Expanded(
                      child: BouncingButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                          label: const Text('View Cart'),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _highlightItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
