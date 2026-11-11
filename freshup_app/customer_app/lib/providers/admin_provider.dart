import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/admin_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/device_notification_service.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  AdminUserModel _adminUser = const AdminUserModel(
    id: 'ADM-01',
    name: 'Store Admin',
    email: 'admin@everyfy.net',
    role: 'super_admin',
    phone: '',
  );

  StoreSettingsModel _settings = StoreSettingsModel();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<AdminOrderModel> _orders = [];
  List<RiderFleetMemberModel> _fleet = [];
  List<CouponModel> _coupons = [];

  Timer? _livePollingTimer;
  final Set<String> _knownOrderIds = {};
  bool _initialOrdersLoaded = false;

  AdminProvider() {
    _initData();
  }

  void _initData() {
    _products = [];
    _categories = [];
    _fleet = [];
    _orders = [];
    _coupons = [];
    fetchLiveFromBackend();
  }

  void startLivePolling() {
    _livePollingTimer?.cancel();
    syncOrdersAndFleetSilently();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      syncOrdersAndFleetSilently();
    });
  }

  void stopLivePolling() {
    _livePollingTimer?.cancel();
    _livePollingTimer = null;
  }

  @override
  void dispose() {
    stopLivePolling();
    super.dispose();
  }

  /// Silent background sync every 4 seconds for real-time live admin management
  Future<void> syncOrdersAndFleetSilently() async {
    try {
      final remoteOrders = await ApiService.getAdminOrdersList();
      final remoteFleet = await ApiService.getAdminRidersList();

      if (remoteOrders.isNotEmpty) {
        if (_initialOrdersLoaded) {
          // Detect brand new incoming orders
          for (var o in remoteOrders) {
            if (!_knownOrderIds.contains(o.id)) {
              _knownOrderIds.add(o.id);
              if (o.status == OrderStatus.placed) {
                final notifId = (int.tryParse(o.id.replaceAll(RegExp(r'\D'), '')) ?? DateTime.now().millisecondsSinceEpoch) % 100000;
                DeviceNotificationService.showSystemNotification(
                  id: notifId,
                  title: 'New Order Received! 🛒',
                  body: 'Order #${o.orderNumber} placed by ${o.customerName} (PKR ${o.total.toStringAsFixed(0)})',
                  payload: o.orderNumber,
                );
                DeviceNotificationService.showInAppAlert(
                  title: 'New Order Received! 🛒',
                  body: 'Order #${o.orderNumber} - PKR ${o.total.toStringAsFixed(0)} (${o.customerName})',
                  orderNumber: o.orderNumber,
                );
              }
            }
          }
        } else {
          for (var o in remoteOrders) {
            _knownOrderIds.add(o.id);
          }
          _initialOrdersLoaded = true;
        }

        _orders = List<AdminOrderModel>.from(remoteOrders);
      }

      if (remoteFleet.isNotEmpty) {
        _fleet = List<RiderFleetMemberModel>.from(remoteFleet);
      }

      notifyListeners();
    } catch (_) {}
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
  Future<bool> login(String identifier, String password, {String? name, String? phone, String? role, String? id}) async {
    _isLoggedIn = true;
    _adminUser = AdminUserModel(
      id: id ?? 'ADM-01',
      name: (name != null && name.isNotEmpty)
          ? name
          : (identifier.isNotEmpty ? identifier.split('@').first : 'Store Admin'),
      email: identifier.contains('@') ? identifier : 'admin@everyfy.net',
      role: role ?? 'super_admin',
      phone: phone ?? (!identifier.contains('@') ? identifier : ''),
    );
    try {
      await ApiService.login(
        identifier: identifier,
        password: password,
        role: 'admin',
      );
    } catch (_) {}
    await fetchLiveFromBackend();
    notifyListeners();
    return true;
  }

  void logout() {
    _isLoggedIn = false;
    _orders = [];
    _fleet = [];
    ApiService.setAuthToken(null);
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
        sizes: p.sizes,
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
        sizes: p.sizes,
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
      ApiService.updateAdminOrderStatus(
        orderId: orderId,
        status: newStatus.toDbString,
      );
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
      ApiService.updateAdminOrderStatus(
        orderId: orderId,
        status: OrderStatus.onTheWay.toDbString,
        riderId: int.tryParse(riderId),
      );
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
      ApiService.updateAdminOrderStatus(
        orderId: orderId,
        status: 'cancelled',
        notes: 'Cancelled by Store: $reason',
      );
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

  /// Live sync from Everyfy Hostinger backend
  Future<void> fetchLiveFromBackend() async {
    try {
      final results = await Future.wait([
        ApiService.getProducts(),
        ApiService.getCategories(),
        ApiService.getAdminOrdersList(),
        ApiService.getAdminRidersList(),
      ]);

      final pList = results[0] as List<ProductModel>;
      final cList = results[1] as List<CategoryModel>;
      final oList = results[2] as List<AdminOrderModel>;
      final rList = results[3] as List<RiderFleetMemberModel>;

      _products = List<ProductModel>.from(pList);
      _categories = List<CategoryModel>.from(cList)..sort(CategoryModel.compareByPreferredOrder);
      _orders = List<AdminOrderModel>.from(oList);
      for (var o in _orders) {
        _knownOrderIds.add(o.id);
      }
      _initialOrdersLoaded = true;
      _fleet = List<RiderFleetMemberModel>.from(rList);
      notifyListeners();
    } catch (_) {}
  }
}
