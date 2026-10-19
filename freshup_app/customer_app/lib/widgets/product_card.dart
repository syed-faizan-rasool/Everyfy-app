import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';
import '../screens/product/product_detail_screen.dart';
import 'animated_widgets.dart';

/// Ultra-Modern, Eye-Catching Grocery Product Card for Everyfy
/// Features:
/// - 1-Product-Per-Line full-width layout with professional padding & soft shadows
/// - High-contrast product imagery with discount badges
/// - Express delivery & unit badges
/// - Prominent '+ ADD' button & smooth interactive Stepper
/// - Mandatory footer tag: "Market Fluctuations Included"
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

    if (isHorizontal) {
      return _buildHorizontalCard(context, cart, qty);
    }
    return _buildVerticalCard(context, cart, qty);
  }

  /// Full-Width 1-Product-Per-Line Card Layout
  Widget _buildHorizontalCard(BuildContext context, CartProvider cart, int qty) {
    final discountPercent = product.hasDiscount
        ? (100 - (product.finalPrice / product.price * 100)).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upper Section: Image Thumbnail + Details + Add Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Box (100x100) with Discount Badge
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEDF2F7),
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Hero(
                              tag: '${heroPrefix}_product_${product.id}',
                              child: CachedNetworkImage(
                                imageUrl: product.image,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const ShimmerBox(
                                  width: 100,
                                  height: 100,
                                  borderRadius: 16,
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Eye-Catching Offer Badge
                          if (product.hasDiscount)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEA580C)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          // Out of Stock Overlay
                          if (!product.inStock)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Middle Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivery Time & Unit Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: Color(0xFF15803D),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '10-15 MINS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product.unit,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Product Name
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Rs ${product.finalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Color(0xFF0D5C3A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (product.hasDiscount) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Rs ${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right Add Button / Stepper (Aligned with top)
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: !product.inStock
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'Sold Out',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            )
                          : qty == 0
                              ? _AddButton(
                                  onTap: () => cart.addToCart(product),
                                )
                              : _QtyStepper(
                                  qty: qty,
                                  onAdd: () => cart.addToCart(product),
                                  onRemove: () =>
                                      cart.decreaseQuantity(product),
                                ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Lower Section: Mandatory Tag "Market Fluctuations Included"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFE2E8F0), width: 0.9),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Market Fluctuations Included',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                          letterSpacing: 0.2,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Daily Fresh Rate',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact Vertical Card (Fallback)
  Widget _buildVerticalCard(BuildContext context, CartProvider cart, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 10,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: Hero(
                          tag: '${heroPrefix}_product_${product.id}',
                          child: CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ShimmerBox(
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: 0,
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.eco_rounded,
                                  size: 36, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OFFER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            product.unit,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs ${product.finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF0D5C3A),
                            ),
                          ),
                          qty == 0
                              ? _AddButton(onTap: () => cart.addToCart(product))
                              : _QtyStepper(
                                  qty: qty,
                                  onAdd: () => cart.addToCart(product),
                                  onRemove: () =>
                                      cart.decreaseQuantity(product),
                                ),
                        ],
                      ),
                      const Text(
                        'Market Fluctuations Included',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
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

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: Color(0xFF15803D),
            ),
            SizedBox(width: 3),
            Text(
              'ADD',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: onRemove),
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$qty',
                key: ValueKey<int>(qty),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onAdd),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
