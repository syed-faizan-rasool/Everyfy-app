import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Action types for promotional carousel banners
enum PromoActionType {
  browseCategories,
  openWhatsApp,
  viewTopDeals,
  applyPromo,
}

/// Data model for promotional scroller banners
class PromoBannerItem {
  final String tag;
  final String title;
  final String subtitle;
  final String buttonText;
  final List<Color> gradientColors;
  final IconData backgroundIcon;
  final IconData badgeIcon;
  final PromoActionType actionType;
  final String? promoCode;

  const PromoBannerItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.gradientColors,
    required this.backgroundIcon,
    required this.badgeIcon,
    required this.actionType,
    this.promoCode,
  });
}

/// Ultra-Modern, Auto-Scrolling Feature & Promotional Carousel for Everyfy
class PromotionalCarousel extends StatefulWidget {
  final VoidCallback? onBrowseCategories;
  final VoidCallback? onOpenWhatsApp;
  final VoidCallback? onOpenCart;
  final VoidCallback? onViewTopDeals;

  const PromotionalCarousel({
    super.key,
    this.onBrowseCategories,
    this.onOpenWhatsApp,
    this.onOpenCart,
    this.onViewTopDeals,
  });

  @override
  State<PromotionalCarousel> createState() => _PromotionalCarouselState();
}

class _PromotionalCarouselState extends State<PromotionalCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static const List<PromoBannerItem> _banners = [
    // Feature 1: Express 10-15 Mins Delivery
    PromoBannerItem(
      tag: 'LIGHTNING FAST',
      title: '10–15 Mins Delivery',
      subtitle: 'Express doorstep grocery dispatch across your area',
      buttonText: '⚡ Order Express',
      gradientColors: [
        Color(0xFF0D5C3A), // Deep botanical emerald
        Color(0xFF16794F), // Vibrant leaf green
        Color(0xFF083D26), // Rich forest
      ],
      backgroundIcon: Icons.bolt_rounded,
      badgeIcon: Icons.electric_moped_rounded,
      actionType: PromoActionType.browseCategories,
    ),
    // Feature 2: 100% Farm Fresh & Organic
    PromoBannerItem(
      tag: 'DIRECT FROM FARMS',
      title: '100% Farm Fresh',
      subtitle: 'Handpicked organic fruits, crisp veggies & pure dairy',
      buttonText: '🌿 Explore Fresh',
      gradientColors: [
        Color(0xFF065F46), // Deep emerald
        Color(0xFF047857),
        Color(0xFF0D9488), // Teal mint
      ],
      backgroundIcon: Icons.eco_rounded,
      badgeIcon: Icons.verified_rounded,
      actionType: PromoActionType.browseCategories,
    ),
    // Feature 3: WhatsApp Direct Ordering
    PromoBannerItem(
      tag: 'DIRECT ASSISTANCE',
      title: 'Order on WhatsApp',
      subtitle: 'Send grocery list or voice note directly to store admin',
      buttonText: '💬 Chat on WhatsApp',
      gradientColors: [
        Color(0xFF075E54), // WhatsApp deep teal
        Color(0xFF0F766E),
        Color(0xFF16A34A), // Rich WhatsApp green
      ],
      backgroundIcon: Icons.support_agent_rounded,
      badgeIcon: Icons.chat_rounded,
      actionType: PromoActionType.openWhatsApp,
    ),
    // Feature 4: Daily Market Rates & Transparent Pricing
    PromoBannerItem(
      tag: 'BEST SAVINGS',
      title: 'Daily Market Rates',
      subtitle: 'Transparent mandi prices updated daily · No hidden fee',
      buttonText: '🏷️ View Best Deals',
      gradientColors: [
        Color(0xFF9A3412), // Deep burnt orange
        Color(0xFFC2410C),
        Color(0xFFF58220), // Accent orange
      ],
      backgroundIcon: Icons.trending_down_rounded,
      badgeIcon: Icons.price_check_rounded,
      actionType: PromoActionType.viewTopDeals,
    ),
    // Offer 5: Real First Order Promo Code FRESH20
    PromoBannerItem(
      tag: 'ACTIVE PROMO',
      title: 'Flat Rs 50 OFF',
      subtitle: 'Use verified coupon code FRESH20 at checkout',
      buttonText: 'Code: FRESH20',
      gradientColors: [
        Color(0xFF4C1D95), // Royal grape
        Color(0xFF6D28D9),
        Color(0xFF7C3AED), // Indigo violet
      ],
      backgroundIcon: Icons.local_offer_rounded,
      badgeIcon: Icons.discount_rounded,
      actionType: PromoActionType.applyPromo,
      promoCode: 'FRESH20',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onBannerTapped(PromoBannerItem banner) {
    switch (banner.actionType) {
      case PromoActionType.openWhatsApp:
        widget.onOpenWhatsApp?.call();
        break;
      case PromoActionType.viewTopDeals:
        widget.onViewTopDeals?.call();
        break;
      case PromoActionType.applyPromo:
        if (banner.promoCode != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Coupon "${banner.promoCode}" active! Flat Rs 50 OFF at checkout.',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: widget.onOpenCart != null
                  ? SnackBarAction(
                      label: 'CART',
                      textColor: Colors.white,
                      onPressed: () => widget.onOpenCart?.call(),
                    )
                  : null,
            ),
          );
        }
        break;
      case PromoActionType.browseCategories:
        widget.onBrowseCategories?.call();
        break;
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horizontal PageView Scroller
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: child,
                  );
                },
                child: InkWell(
                  onTap: () => _onBannerTapped(banner),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: banner.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: banner.gradientColors.first.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Decorative Watermark Background Icon
                        Positioned(
                          right: -15,
                          bottom: -20,
                          child: Icon(
                            banner.backgroundIcon,
                            size: 140,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),

                        // Secondary Translucent Orb Graphic
                        Positioned(
                          top: -30,
                          right: 80,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),

                        // Foreground Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Tag & Badge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          banner.badgeIcon,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          banner.tag,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Middle Title & Subtitle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    banner.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),

                              // Bottom Action Button Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      banner.buttonText,
                                      style: TextStyle(
                                        color: banner.gradientColors.first,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: banner.gradientColors.first,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Modern Expanding Dot Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
