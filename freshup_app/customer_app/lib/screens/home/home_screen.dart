import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/dummy_data.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_title.dart';
import '../address/address_screen.dart';
import '../category/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../order/order_history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeTab(),
      const OrderHistoryScreen(embedded: true),
      const CartScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_navIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Shop',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Consumer<CartProvider>(
                builder: (_, cart, __) => Badge(
                  label: Text('${cart.itemCount}'),
                  isLabelVisible: cart.itemCount > 0,
                  backgroundColor: AppColors.accent,
                  textColor: Colors.white,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
              selectedIcon: Consumer<CartProvider>(
                builder: (_, cart, __) => Badge(
                  label: Text('${cart.itemCount}'),
                  isLabelVisible: cart.itemCount > 0,
                  backgroundColor: AppColors.accent,
                  textColor: Colors.white,
                  child: const Icon(Icons.shopping_cart_rounded),
                ),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Simulated pull to refresh
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Catalog refreshed with fresh stock!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategoryFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final address = context.watch<AuthProvider>().selectedAddress;

    // Filter products based on search query and optional selected category
    List<ProductModel> displayedProducts = DummyData.products;
    if (_searchQuery.isNotEmpty) {
      displayedProducts = DummyData.searchProducts(_searchQuery);
    }
    if (_selectedCategoryFilter != null) {
      displayedProducts = displayedProducts
          .where((p) => p.categoryId == _selectedCategoryFilter)
          .toList();
    }

    final isSearching = _searchQuery.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
          // Top Location & Notification Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressScreen()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address != null ? address.label : 'Select Location',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    address != null
                                        ? '${address.area}, ${address.city}'
                                        : 'Tap to choose delivery address',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncingButton(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('No new notifications right now'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Functional Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSearching ? AppColors.primary : AppColors.cardBorder,
                    width: isSearching ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search fresh fruits, vegetables, milk...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Normal View Content (Promos, Categories) when not searching
          if (!isSearching) ...[
            // Promotional Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                height: 144,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      Color(0xFF136E44),
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.eco_rounded,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SPECIAL PROMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Flat 20% OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'On your first order · Use code FRESH20',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shop by Category Header
            SliverToBoxAdapter(
              child: SectionTitle(
                title: 'Shop by Category',
                subtitle: 'Fresh and farm handpicked',
                actionText: 'See All',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductListScreen(category: DummyData.categories.first),
                    ),
                  );
                },
              ),
            ),

            // Category Chips Horizontal Slider
            SliverToBoxAdapter(
              child: SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: DummyData.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final cat = DummyData.categories[i];
                    return CategoryChip(
                      category: cat,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(category: cat),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Section Title for Popular Products
            const SliverToBoxAdapter(
              child: SectionTitle(
                title: 'Popular Products',
                subtitle: 'Highest rated groceries near you',
              ),
            ),
          ] else ...[
            // Search Mode Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search results for "$_searchQuery"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${displayedProducts.length} items',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Product Grid or Empty State
          if (displayedProducts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: 'No products found',
                  description: 'We could not find any items matching "$_searchQuery". Try searching with a different keyword.',
                  buttonText: 'Clear Search',
                  onButtonPressed: _clearSearch,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: displayedProducts[i],
                    heroPrefix: isSearching ? 'search' : 'home',
                  ),
                  childCount: displayedProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
