import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';
import '../screens/product/product_detail_screen.dart';
import 'app_network_image.dart';

/// Ultra-Modern, Clean Grocery Product Card for Everyfy
/// Arranged exactly like the reference app:
/// - LEFT: Product Name, Price (in theme brand color), Unit / Size, and Market Badge
/// - RIGHT: Rounded Product Image with Circular '+' Button at bottom-right
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String heroPrefix;
  final bool isHorizontal;

  const ProductCard({
    super.key,
    required this.product,
    this.heroPrefix = 'popular',
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(product.id);

    return _buildReferenceRow(context, cart, qty);
  }

  /// Exact arrangement according to reference Image 4
  Widget _buildReferenceRow(BuildContext context, CartProvider cart, int qty) {
    final discountPercent = product.hasDiscount
        ? (100 - (product.finalPrice / product.price * 100)).round()
        : 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. LEFT SIDE: Title, Price, Unit & Badge (Matching Reference)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Title
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Price (Brand Green Color, prominent as in reference)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (product.isPriceDecided) ...[
                            Text(
                              'Rs ${product.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                                color: AppColors.primary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Rs ${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ] else ...[
                            const Text(
                              'Rs: as per market price',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.primary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Unit / Size (e.g. XL, 1 Pack, 250 g, etc.)
                      Text(
                        product.unit,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Highlighted Market Fluctuations Included Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFF86EFAC),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 11,
                              color: Color(0xFF15803D),
                            ),
                            SizedBox(width: 3.5),
                            Text(
                              'Market Fluctuations Included',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // 2. RIGHT SIDE: Product Image + Circular Add Button (Matching Reference)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Product Image (Rounded modern card)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Hero(
                        tag: '${heroPrefix}_product_${product.id}',
                        child: AppNetworkImage(
                          imageUrl: product.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          borderRadius: 16,
                        ),
                      ),
                    ),

                    // Out of stock overlay
                    if (!product.inStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Sold Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Circular '+' Button or Interactive Stepper (Positioned bottom right)
                    if (product.inStock)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: qty == 0
                            ? _buildCircularAddButton(context, cart)
                            : _buildCompactStepper(context, cart, qty),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circular '+' Button matching the reference image layout
  Widget _buildCircularAddButton(BuildContext context, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        cart.addToCart(product);
        Feedback.forTap(context);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 18,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Compact Stepper Capsule when item is already added to cart
  Widget _buildCompactStepper(BuildContext context, CartProvider cart, int qty) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              cart.decreaseQuantity(product);
              Feedback.forTap(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.remove_rounded, color: Colors.white, size: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              cart.addToCart(product);
              Feedback.forTap(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
