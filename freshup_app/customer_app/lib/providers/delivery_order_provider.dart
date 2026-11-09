import 'package:flutter/foundation.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class WithdrawalRequest {
  final String id;
  final String method;
  final String accountNumber;
  final double amount;
  final DateTime date;
  final String status;

  const WithdrawalRequest({
    required this.id,
    required this.method,
    required this.accountNumber,
    required this.amount,
    required this.date,
    this.status = 'Pending',
  });
}

class DeliveryOrderProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isLoggedIn = false;
  String _riderName = '';
  String _riderPhone = '';
  String _riderVehicle = '';
  String _riderAvatar = '';
  String get riderAvatar => _riderAvatar;
  double _riderRating = 5.0;
  int _totalDeliveriesAllTime = 0;

  List<DeliveryOrderModel> _availableOrders = [];
  DeliveryOrderModel? _activeOrder;
  List<DeliveryOrderModel> _completedOrders = [];
  final List<WithdrawalRequest> _withdrawals = [];

  DeliveryOrderProvider() {
    _loadInitialData();
  }

  void updateRiderAvatar(String url) {
    _riderAvatar = url;
    notifyListeners();
  }

  void _loadInitialData() {
    _availableOrders = [];
    _completedOrders = [];
    _withdrawals.clear();
  }

  /// Refresh available orders from server
  Future<void> fetchAvailableOrders() async {
    try {
      final remoteOrders = await ApiService.getRiderAvailableOrders();
      _availableOrders = remoteOrders;
      notifyListeners();
    } catch (_) {}
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isLoggedIn => _isLoggedIn;
  String get riderName => _riderName.isNotEmpty ? _riderName : 'Delivery Rider';
  String get riderPhone => _riderPhone;
  String get riderVehicle => _riderVehicle.isNotEmpty ? _riderVehicle : 'Motorcycle';
  double get riderRating => _riderRating;
  int get totalDeliveriesAllTime => _totalDeliveriesAllTime + _completedOrders.length;

  List<DeliveryOrderModel> get availableOrders => _isOnline ? List.unmodifiable(_availableOrders) : [];
  DeliveryOrderModel? get activeOrder => _activeOrder;
  List<DeliveryOrderModel> get completedOrders => List.unmodifiable(_completedOrders);
  List<WithdrawalRequest> get withdrawals => List.unmodifiable(_withdrawals);

  // Financial calculations
  double get todayEarnings {
    final earnings = _completedOrders.fold<double>(0.0, (sum, o) => sum + o.earning);
    return earnings;
  }

  double get weeklyEarnings => todayEarnings;
  double get monthlyEarnings => todayEarnings;

  double get totalWithdrawn => _withdrawals.fold<double>(0.0, (sum, w) => sum + w.amount);
  double get availableBalance => (todayEarnings - totalWithdrawn).clamp(0.0, double.infinity);

  int get todayDeliveriesCount => _completedOrders.length;

  double get todayDistanceKm {
    return _completedOrders.fold<double>(0.0, (sum, o) => sum + o.distanceKm);
  }

  bool requestWithdrawal({
    required String method,
    required String accountNumber,
    required double amount,
  }) {
    if (amount <= 0 || amount > availableBalance) return false;
    final req = WithdrawalRequest(
      id: 'WD-${DateTime.now().millisecondsSinceEpoch % 100000}',
      method: method,
      accountNumber: accountNumber,
      amount: amount,
      date: DateTime.now(),
      status: 'Pending',
    );
    _withdrawals.insert(0, req);
    notifyListeners();
    return true;
  }

  // Online / Offline toggle
  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    ApiService.riderToggleOnline(_isOnline).catchError((_) => false);
    notifyListeners();
  }

  void setOnlineStatus(bool value) {
    _isOnline = value;
    ApiService.riderToggleOnline(value).catchError((_) => false);
    notifyListeners();
  }

  /// Set rider session from AuthProvider
  void setRiderSession({
    required String name,
    required String phone,
    String? vehicle,
    double? rating,
    int? totalDeliveries,
  }) {
    _isLoggedIn = true;
    _riderName = name;
    _riderPhone = phone;
    if (vehicle != null && vehicle.isNotEmpty) _riderVehicle = vehicle;
    if (rating != null) _riderRating = rating;
    if (totalDeliveries != null) _totalDeliveriesAllTime = totalDeliveries;
    notifyListeners();
    fetchAvailableOrders();
  }

  /// Rider login with backend API
  Future<bool> login(String identifier, String password) async {
    try {
      final res = await ApiService.login(
        identifier: identifier,
        password: password,
        role: 'rider',
      );
      if (res['success'] == true && res['data'] != null) {
        _isLoggedIn = true;
        _riderPhone = identifier;
        final riderData = res['data']['user'] ?? res['data']['rider'];
        if (riderData != null) {
          _riderName = riderData['name'] ?? 'Delivery Rider';
          _riderVehicle = riderData['vehicle'] ?? riderData['vehicle_number'] ?? _riderVehicle;
          _riderRating = double.tryParse((riderData['rating'] ?? 5.0).toString()) ?? 5.0;
          _totalDeliveriesAllTime = int.tryParse((riderData['total_deliveries'] ?? 0).toString()) ?? 0;
        }
        notifyListeners();
        fetchAvailableOrders();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Rider logout
  void logout() {
    _isLoggedIn = false;
    ApiService.setAuthToken(null);
    notifyListeners();
  }

  // Accept a delivery request
  void acceptOrder(DeliveryOrderModel order) {
    _availableOrders.removeWhere((o) => o.id == order.id);
    _activeOrder = order.copyWith(
      status: OrderStatus.ready,
      isAvailable: false,
    );
    notifyListeners();

    ApiService.riderAcceptOrder(order.id).catchError((_) => false);
  }

  // Reject a delivery request
  void rejectOrder(String orderId) {
    _availableOrders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  // Advance the active order status to the next step
  void advanceActiveOrderStatus() {
    if (_activeOrder == null) return;

    final currentStatus = _activeOrder!.status;
    String nextApiStatus = 'picked_up';

    if (currentStatus == OrderStatus.ready || currentStatus == OrderStatus.placed || currentStatus == OrderStatus.confirmed || currentStatus == OrderStatus.preparing) {
      _activeOrder = _activeOrder!.copyWith(status: OrderStatus.pickedUp);
      nextApiStatus = 'picked_up';
      notifyListeners();
    } else if (currentStatus == OrderStatus.pickedUp) {
      _activeOrder = _activeOrder!.copyWith(status: OrderStatus.onTheWay);
      nextApiStatus = 'on_the_way';
      notifyListeners();
    } else if (currentStatus == OrderStatus.onTheWay) {
      final finishedOrder = _activeOrder!.copyWith(status: OrderStatus.delivered);
      _completedOrders.insert(0, finishedOrder);
      _totalDeliveriesAllTime++;
      final orderIdToDeliver = _activeOrder!.id;
      _activeOrder = null;
      nextApiStatus = 'delivered';
      notifyListeners();
      ApiService.riderUpdateStatus(orderIdToDeliver, 'delivered').catchError((_) => false);
      return;
    }

    if (_activeOrder != null) {
      ApiService.riderUpdateStatus(_activeOrder!.id, nextApiStatus).catchError((_) => false);
    }
  }

  // Cancel an active order
  void cancelActiveOrder(String reason) {
    if (_activeOrder == null) return;
    final cancelledOrder = _activeOrder!.copyWith(
      status: OrderStatus.cancelled,
      notes: 'Cancelled: $reason',
    );
    _completedOrders.insert(0, cancelledOrder);
    _activeOrder = null;
    notifyListeners();
  }
}
