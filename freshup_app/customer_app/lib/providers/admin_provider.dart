import 'package:flutter/foundation.dart';
import '../data/dummy_data.dart';
import '../models/admin_model.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoggedIn = true; // Pre-authenticated for quick demo access
  final AdminUserModel _adminUser = const AdminUserModel(
    id: 'ADM-01',
    name: 'Muhammad Daniyal',
    email: 'daniyal.manager@freshcart.pk',
    role: 'Head of Store Operations',
    phone: '03001234567',
  );

  StoreSettingsModel _settings = StoreSettingsModel();

  late List<ProductModel> _products;
  late List<CategoryModel> _categories;
  late List<AdminOrderModel> _orders;
  late List<RiderFleetMemberModel> _fleet;
  late List<CouponModel> _coupons;

  AdminProvider() {
    _initData();
  }

  void _initData() {
    // Load mutable clone of products from DummyData
    _products = List<ProductModel>.from(DummyData.products);
    _categories = List<CategoryModel>.from(DummyData.categories);

    // Initial Riders Fleet
    _fleet = [
      RiderFleetMemberModel(
        id: 'RID-101',
        name: 'Ahmed Khan',
        phone: '03019876543',
        vehicle: 'Honda CD70 · LEB-4921',
        rating: 4.9,
        completedToday: 6,
        earningsToday: 980,
        status: FleetDutyStatus.onDelivery,
        currentOrderId: 'ORD-9821',
      ),
      RiderFleetMemberModel(
        id: 'RID-102',
        name: 'Bilal Hassan',
        phone: '03214567890',
        vehicle: 'Yamaha YBR · LEK-8812',
        rating: 4.8,
        completedToday: 4,
        earningsToday: 620,
        status: FleetDutyStatus.available,
      ),
      RiderFleetMemberModel(
        id: 'RID-103',
        name: 'Hamza Ali',
        phone: '03337766554',
        vehicle: 'Road Prince 70 · LEM-3104',
        rating: 4.7,
        completedToday: 5,
        earningsToday: 790,
        status: FleetDutyStatus.available,
      ),
      RiderFleetMemberModel(
        id: 'RID-104',
        name: 'Zain Malik',
        phone: '03451122334',
        vehicle: 'United 70 · LEJ-5590',
        rating: 4.6,
        completedToday: 2,
        earningsToday: 320,
        status: FleetDutyStatus.offline,
      ),
    ];

    // Initial Admin Orders Pipeline
    _orders = [
      AdminOrderModel(
        id: 'ORD-9821',
        orderNumber: 'ORD-9821',
        customerName: 'Fatima Zahra',
        customerPhone: '03004455667',
        address: 'House 42, Street 6, Sector Y, Phase 3, DHA, Lahore',
        items: [
          CartItemModel(product: _products[0], quantity: 2), // Apples
          CartItemModel(product: _products[4], quantity: 3), // Milk
          CartItemModel(product: _products[6], quantity: 1), // Bread
        ],
        subtotal: 1408,
        deliveryFee: 150,
        discount: 0,
        total: 1558,
        paymentMethod: 'Cash on Delivery',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        status: OrderStatus.onTheWay,
        assignedRiderId: 'RID-101',
        assignedRiderName: 'Ahmed Khan',
        assignedRiderPhone: '03019876543',
        customerNotes: 'Ring bell twice upon arrival',
      ),
      AdminOrderModel(
        id: 'ORD-9822',
        orderNumber: 'ORD-9822',
        customerName: 'Ali Raza',
        customerPhone: '03217891234',
        address: 'Apartment 4B, Gulberg Heights, Block G, Gulberg II, Lahore',
        items: [
          CartItemModel(product: _products[1], quantity: 2), // Bananas
          CartItemModel(product: _products[2], quantity: 1), // Tomatoes
          CartItemModel(product: _products[7], quantity: 2), // Orange Juice
        ],
        subtotal: 960,
        deliveryFee: 120,
        discount: 100,
        total: 980,
        paymentMethod: 'Paid Online (Debit Card)',
        createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
        status: OrderStatus.ready,
        customerNotes: 'Leave at reception with Mr. Aslam',
      ),
      AdminOrderModel(
        id: 'ORD-9823',
        orderNumber: 'ORD-9823',
        customerName: 'Sarah Sheikh',
        customerPhone: '03123456789',
        address: 'House 112, Street 4, Sector F, DHA Phase 5, Lahore',
        items: [
          CartItemModel(product: _products[4], quantity: 4), // Olpers Milk
          CartItemModel(product: _products[5], quantity: 2), // Farm Eggs
        ],
        subtotal: 1680,
        deliveryFee: 150,
        discount: 0,
        total: 1830,
        paymentMethod: 'Cash on Delivery',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        status: OrderStatus.preparing,
        customerNotes: 'Please check eggs are completely intact',
      ),
      AdminOrderModel(
        id: 'ORD-9824',
        orderNumber: 'ORD-9824',
        customerName: 'Kamran Akmal',
        customerPhone: '03028899001',
        address: 'Plot 77, Commercial Area, Cavalry Ground, Lahore',
        items: [
          CartItemModel(product: _products[0], quantity: 1),
          CartItemModel(product: _products[3], quantity: 2),
        ],
        subtotal: 599,
        deliveryFee: 100,
        discount: 50,
        total: 649,
        paymentMethod: 'Cash on Delivery',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        status: OrderStatus.placed, // Newly placed!
        customerNotes: 'Call before coming',
      ),
      AdminOrderModel(
        id: 'ORD-9820',
        orderNumber: 'ORD-9820',
        customerName: 'Ayesha Siddiqui',
        customerPhone: '03345566778',
        address: 'House 19, Main Road, Garden Town, Lahore',
        items: [
          CartItemModel(product: _products[2], quantity: 2),
          CartItemModel(product: _products[6], quantity: 1),
        ],
        subtotal: 440,
        deliveryFee: 120,
        discount: 0,
        total: 560,
        paymentMethod: 'Cash on Delivery',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: OrderStatus.delivered,
        assignedRiderId: 'RID-102',
        assignedRiderName: 'Bilal Hassan',
      ),
    ];

    // Coupons
    _coupons = [
      CouponModel(
        id: 'CPN-1',
        code: 'FRESH50',
        discountPercent: 15,
        maxDiscount: 200,
        minOrderValue: 1000,
        expiryDate: DateTime.now().add(const Duration(days: 14)),
      ),
      CouponModel(
        id: 'CPN-2',
        code: 'WELCOME100',
        discountPercent: 20,
        maxDiscount: 300,
        minOrderValue: 1200,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      ),
    ];
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  AdminUserModel get adminUser => _adminUser;
  StoreSettingsModel get settings => _settings;
  List<ProductModel> get products => List.unmodifiable(_products);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<AdminOrderModel> get orders => List.unmodifiable(_orders);
  List<RiderFleetMemberModel> get fleet => List.unmodifiable(_fleet);
  List<CouponModel> get coupons => List.unmodifiable(_coupons);

  // Authentication
  bool login(String email, String password) {
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // Financial & Operational KPIs
  double get todayRevenue {
    return _orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.total);
  }

  int get todayOrdersCount => _orders.length;

  int get activeDeliveriesCount {
    return _orders
        .where((o) => o.status == OrderStatus.onTheWay || o.status == OrderStatus.ready)
        .length;
  }

  int get pendingOrdersCount {
    return _orders.where((o) => o.status == OrderStatus.placed).length;
  }

  int get lowStockProductsCount {
    return _products.where((p) => p.stockQty <= 10).length;
  }

  // Store Settings Actions
  void toggleStoreOpen() {
    _settings = _settings.copyWith(isOpen: !_settings.isOpen);
    notifyListeners();
  }

  void updateSettings(StoreSettingsModel updated) {
    _settings = updated;
    notifyListeners();
  }

  // Product & Inventory Actions
  void addProduct(ProductModel product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void updateProduct(ProductModel updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(int id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void adjustStock(int id, int delta) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = _products[index];
      final newQty = (p.stockQty + delta).clamp(0, 9999);
      _products[index] = ProductModel(
        id: p.id,
        categoryId: p.categoryId,
        name: p.name,
        description: p.description,
        image: p.image,
        price: p.price,
        discountPrice: p.discountPrice,
        unit: p.unit,
        stockQty: newQty,
      );
      notifyListeners();
    }
  }

  void toggleProductAvailability(int id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = _products[index];
      final newQty = p.stockQty > 0 ? 0 : 25; // toggles between 0 and 25
      _products[index] = ProductModel(
        id: p.id,
        categoryId: p.categoryId,
        name: p.name,
        description: p.description,
        image: p.image,
        price: p.price,
        discountPrice: p.discountPrice,
        unit: p.unit,
        stockQty: newQty,
      );
      notifyListeners();
    }
  }

  // Category Actions
  void addCategory(CategoryModel category) {
    _categories.add(category);
    notifyListeners();
  }

  void updateCategory(CategoryModel updated) {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _categories[index] = updated;
      notifyListeners();
    }
  }

  // Order Actions
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void assignRiderToOrder(String orderId, String riderId) {
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    final riderIndex = _fleet.indexWhere((r) => r.id == riderId);

    if (orderIndex != -1 && riderIndex != -1) {
      final rider = _fleet[riderIndex];
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        assignedRiderId: rider.id,
        assignedRiderName: rider.name,
        assignedRiderPhone: rider.phone,
        status: OrderStatus.onTheWay,
      );

      _fleet[riderIndex] = rider.copyWith(
        status: FleetDutyStatus.onDelivery,
        currentOrderId: orderId,
      );

      notifyListeners();
    }
  }

  void cancelOrder(String orderId, String reason) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.cancelled,
        customerNotes: 'Cancelled by Store: $reason',
      );
      notifyListeners();
    }
  }

  // Fleet Actions
  void toggleRiderDuty(String riderId) {
    final index = _fleet.indexWhere((r) => r.id == riderId);
    if (index != -1) {
      final r = _fleet[index];
      final newStatus = r.status == FleetDutyStatus.offline
          ? FleetDutyStatus.available
          : FleetDutyStatus.offline;
      _fleet[index] = r.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // Coupon Actions
  void addCoupon(CouponModel coupon) {
    _coupons.insert(0, coupon);
    notifyListeners();
  }

  void toggleCoupon(String couponId) {
    final index = _coupons.indexWhere((c) => c.id == couponId);
    if (index != -1) {
      _coupons[index].isActive = !_coupons[index].isActive;
      notifyListeners();
    }
  }
}
