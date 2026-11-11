import 'package:flutter/services.dart';
import '../../widgets/everyfy_drawer.dart';
import '../../services/meta_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../../widgets/promotional_carousel.dart';
import '../../widgets/section_title.dart';
import '../address/address_screen.dart';
import '../cart/cart_screen.dart';
import '../order/custom_order_screen.dart';
import '../order/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notifications_screen.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0; // Default to Shop (Tab 0)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<NotificationProvider>().setRoleAndUser(
        role: 'customer',
        userId: auth.userId > 0 ? auth.userId : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeTab(
        onSwitchTab: (i) => setState(() => _navIndex = i),
      ),
      const OrderHistoryScreen(embedded: true),
      CartScreen(
        embedded: true,
        onStartShopping: () => setState(() => _navIndex = 0),
      ),
      const CustomOrderScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: EveryfyDrawer(onSwitchTab: (i) => setState(() => _navIndex = i)),
        body: SafeArea(top: false, child: screens[_navIndex]),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Live Cart Strip (shown on Shop tab when cart has items)
            if (_navIndex == 0)
              Consumer<CartProvider>(
                builder: (ctx, cart, _) {
                  if (cart.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _navIndex = 2),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D6843), Color(0xFF15803D)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${cart.itemCount} ${cart.itemCount == 1 ? 'ITEM' : 'ITEMS'}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'Rs ${cart.subtotal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Cart',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            _buildCustomBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar() {
    const activeColor = AppColors.primary; // Everyfy Emerald Green
    const inactiveColor = Color(0xFF64748B);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Tab 0: Shop
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: 'Shop',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
              // Tab 1: Orders
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
              // Tab 2: Cart (Live cart screen & real-time badge)
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (_, cart, __) => _buildNavItem(
                    index: 2,
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart_rounded,
                    label: 'Cart',
                    badgeCount: cart.itemCount,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),
                ),
              ),
              // Tab 3: Custom (Elevated Circular Button with +)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _navIndex = 3),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _navIndex == 3 ? AppColors.primary : const Color(0xFF0D6843),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: _navIndex == 3 ? FontWeight.w800 : FontWeight.w600,
                              color: _navIndex == 3 ? activeColor : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Tab 4: Profile
              Expanded(
                child: _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    int badgeCount = 0,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = _navIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _navIndex = index),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: isSelected
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 3)
                    : EdgeInsets.zero,
                decoration: isSelected
                    ? BoxDecoration(
                        color: activeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: badgeCount > 0
                    ? Badge(
                        backgroundColor: AppColors.accent,
                        label: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Icon(
                          isSelected ? (activeIcon ?? icon) : icon,
                          color: color,
                          size: 23,
                        ),
                      )
                    : Icon(
                        isSelected ? (activeIcon ?? icon) : icon,
                        color: color,
                        size: 23,
                      ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const _HomeTab({this.onSwitchTab});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tabScrollController = ScrollController();

  final GlobalKey _scrollContainerKey = GlobalKey();
  final Map<int, GlobalKey> _categoryHeaderKeys = {};

  String _searchQuery = '';
  int _activeCategoryIndex = 0;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });

    _scrollController.addListener(_onMainScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  /// Synchronize scrolling with category tab selection
  void _onMainScroll() {
    if (_isAutoScrolling) return;
    if (_searchQuery.isNotEmpty) return;

    final catalog = context.read<CatalogProvider>();
    final categories = catalog.categories;
    if (categories.isEmpty) return;

    final renderBox = _scrollContainerKey.currentContext?.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;

    int newIndex = 0;
    const double stickyHeaderHeight = 96.0;

    for (int i = 0; i < categories.length; i++) {
      final key = _categoryHeaderKeys[categories[i].id];
      final catObj = key?.currentContext?.findRenderObject();
      if (catObj is RenderBox && catObj.hasSize && catObj.attached) {
        final pos = catObj.localToGlobal(Offset.zero, ancestor: renderBox);
        // When category header is scrolled up to or past the bottom of the sticky bar (+ 20px threshold)
        if (pos.dy <= stickyHeaderHeight + 20) {
          newIndex = i;
        }
      }
    }

    if (newIndex != _activeCategoryIndex) {
      setState(() {
        _activeCategoryIndex = newIndex;
      });
      _scrollToTab(newIndex);
    }
  }

  /// Scroll horizontal category tab bar so active chip stays in view
  void _scrollToTab(int index) {
    if (!_tabScrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    // CategoryChip has width 76 + separator 12 = 88, horizontal padding 16
    final targetOffset = 16.0 + (index * 88.0) + 38.0 - (screenWidth / 2);
    _tabScrollController.animateTo(
      targetOffset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Smoothly scroll main view to tapped category section
  void _onCategoryTabTapped(int index, int categoryId) {
    setState(() {
      _activeCategoryIndex = index;
      _isAutoScrolling = true;
    });
    _scrollToTab(index);

    final key = _categoryHeaderKeys[categoryId];
    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      final renderBox =
          _scrollContainerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null &&
          box.attached &&
          renderBox != null &&
          renderBox.hasSize) {
        final pos = box.localToGlobal(Offset.zero, ancestor: renderBox);
        final currentOffset = _scrollController.offset;
        const double stickyHeaderHeight = 96.0;
        final targetOffset =
            (currentOffset + pos.dy - stickyHeaderHeight - 8.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController
            .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
        )
            .then((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _isAutoScrolling = false;
          });
        });
        return;
      }
    }
    _isAutoScrolling = false;
  }

  Future<void> _handleRefresh() async {
    await context.read<CatalogProvider>().fetchCatalog();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Catalog synced live from Everyfy Cloud!'),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final address = context.watch<AuthProvider>().selectedAddress;
    final catalog = context.watch<CatalogProvider>();

    final categories = catalog.categories;
    final allProducts = catalog.products;

    // Initialize keys for each category
    for (var cat in categories) {
      _categoryHeaderKeys.putIfAbsent(cat.id, () => GlobalKey());
    }

    final isSearching = _searchQuery.isNotEmpty;

    // Filtered search list
    List<ProductModel> searchResults = [];
    if (isSearching) {
      final q = _searchQuery.toLowerCase().trim();
      searchResults = allProducts
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.unit.toLowerCase().contains(q))
          .toList();
    }

    // Popular Products: top featured or discounted items
    final popularProducts = allProducts
        .where((p) =>
            p.isFeatured ||
            (p.discountPrice != null && p.discountPrice! < p.price))
        .take(6)
        .toList();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: Container(
        key: _scrollContainerKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Unified Top Header matching user reference (Image 5)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: 3-Lines Menu Icon | Deliver To & Address | Notification Bell
                    Row(
                      children: [
                        // Hamburger Menu Icon (Opens Everyfy Drawer)
                        Builder(
                          builder: (innerContext) => IconButton(
                            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Scaffold.of(innerContext).openDrawer();
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Deliver To & Location Name (Clickable to change address)
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddressScreen()),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.bolt_rounded, size: 11, color: Colors.white),
                                          SizedBox(width: 1.5),
                                          Text(
                                            '10-15 MINS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      address?.label.isNotEmpty == true ? address!.label : 'Home',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address != null
                                      ? (address.area.isNotEmpty
                                          ? '${address.area}, ${address.city}'
                                          : address.city)
                                      : 'Gojra, Punjab',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Notification Bell Button with live unread badge
                        BouncingButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Consumer<NotificationProvider>(
                              builder: (_, notifProv, __) {
                                return notifProv.unreadCount > 0
                                    ? Badge(
                                        backgroundColor: Colors.redAccent,
                                        label: Text(
                                          '${notifProv.unreadCount}',
                                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 22,
                                      );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Clean White Pill-shaped Search Bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            MetaAnalyticsService.logSearch(query: val.trim());
                          }
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                          suffixIcon: isSearching
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                                  onPressed: _clearSearch,
                                )
                              : const Icon(Icons.mic_none_rounded, size: 20, color: Color(0xFF94A3B8)),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // SEARCH RESULTS VIEW
            if (isSearching) ...[
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
                        '${searchResults.length} items',
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
              if (searchResults.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No products found',
                      description:
                          'We could not find any items matching "$_searchQuery". Try searching with a different keyword.',
                      buttonText: 'Clear Search',
                      onButtonPressed: _clearSearch,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(
                        product: searchResults[i],
                        heroPrefix: 'search_$i',
                        isHorizontal: true,
                      ),
                      childCount: searchResults.length,
                    ),
                  ),
                ),
            ] else if (catalog.isLoading && categories.isEmpty) ...[
              // Premium Live Loading State
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Loading fresh catalog...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Connecting live to Everyfy server',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (categories.isEmpty) ...[
              // Connection Failed or Empty State
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No Products Available',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          catalog.error != null
                              ? 'Could not connect to live Everyfy backend. Please check your internet connection.'
                              : 'Products catalog is currently being updated. Please check back shortly.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: () => catalog.fetchCatalog(),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Refresh Catalog',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // STANDARD DASHBOARD BROWSING VIEW

              // 1. Promotional Carousel (Multi-Banner Auto Scroller)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: PromotionalCarousel(
                    onBrowseCategories: () =>
                        _onCategoryTabTapped(0, categories.first.id),
                    onOpenWhatsApp: () => widget.onSwitchTab?.call(3),
                    onOpenCart: () => widget.onSwitchTab?.call(2),
                    onViewTopDeals: () => _scrollToTab(0),
                  ),
                ),
              ),

              // Category Horizontal Text Tabs (Matching Image 4 Reference)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyCategoryHeaderDelegate(
                  height: 96.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      controller: _tabScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final isSelected = _activeCategoryIndex == i;
                        return CategoryChip(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () => _onCategoryTabTapped(i, cat.id),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 4. Popular Products Section (Vertical Scroll, 1-Product-Per-Line)
              SliverToBoxAdapter(
                child: SectionTitle(
                  title: 'Popular Products 🔥',
                  subtitle: 'Highest rated groceries near you',
                  actionText: 'Top Deals',
                  onAction: () => _scrollToTab(0),
                ),
              ),

              // Popular Products Vertical List (1 product per line)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ProductCard(
                      product: popularProducts[i],
                      heroPrefix: 'popular_$i',
                      isHorizontal: true,
                    ),
                    childCount: popularProducts.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 12),
              ),

              // 5. Category-by-Category Sequential Products Sections
              for (int catIdx = 0; catIdx < categories.length; catIdx++) ...[
                if (allProducts.any((p) => p.categoryId == categories[catIdx].id)) ...[
                  // Category Header (Clean title matching Image 4)
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _categoryHeaderKeys[categories[catIdx].id],
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        categories[catIdx].name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),

                  // Category Products List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _buildCategoryList(
                      allProducts
                          .where((p) => p.categoryId == categories[catIdx].id)
                          .toList(),
                      'cat_',
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                ],
              ],

              // Professional Brand Quality Guarantee Footer
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '100% Farm Fresh Guarantee · Everyfy Grocery',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<ProductModel> items, String prefix) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: Text(
            'New fresh stock arriving soon!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => ProductCard(
          product: items[i],
          heroPrefix: '${prefix}_$i',
          isHorizontal: true,
        ),
        childCount: items.length,
      ),
    );
  }
}

/// Pinned/Sticky Category Navigation Header Delegate
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyCategoryHeaderDelegate({
    required this.child,
    this.height = 96.0,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isPinned = shrinkOffset > 0 || overlapsContent;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: isPinned
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        border: isPinned
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              )
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
