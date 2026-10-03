import 'package:flutter/foundation.dart';
import '../data/dummy_delivery_data.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';

class DeliveryOrderProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isLoggedIn = false;
  String _riderName = 'Ahmed Khan';
  String _riderPhone = '03019876543';
  final String _riderVehicle = 'Honda CD70 · LEB-4921';
  final double _riderRating = 4.9;
  int _totalDeliveriesAllTime = 142;

  List<DeliveryOrderModel> _availableOrders = [];
  DeliveryOrderModel? _activeOrder;
  List<DeliveryOrderModel> _completedOrders = [];

  DeliveryOrderProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    _availableOrders = DummyDeliveryData.getInitialAvailableOrders();
    _completedOrders = DummyDeliveryData.getInitialCompletedOrders();
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isLoggedIn => _isLoggedIn;
  String get riderName => _riderName;
  String get riderPhone => _riderPhone;
  String get riderVehicle => _riderVehicle;
  double get riderRating => _riderRating;
  int get totalDeliveriesAllTime => _totalDeliveriesAllTime + _completedOrders.length;

  List<DeliveryOrderModel> get availableOrders => _isOnline ? List.unmodifiable(_availableOrders) : [];
  DeliveryOrderModel? get activeOrder => _activeOrder;
  List<DeliveryOrderModel> get completedOrders => List.unmodifiable(_completedOrders);

  // Financial calculations
  double get todayEarnings {
    final earnings = _completedOrders.fold<double>(0.0, (sum, o) => sum + o.earning);
    return earnings;
  }

  double get weeklyEarnings => todayEarnings + 4350.0;
  double get monthlyEarnings => weeklyEarnings + 18600.0;

  int get todayDeliveriesCount => _completedOrders.length;

  double get todayDistanceKm {
    return _completedOrders.fold<double>(0.0, (sum, o) => sum + o.distanceKm);
  }

  // Online / Offline toggle
  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  void setOnlineStatus(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  // TODO: Replace with real API call to POST /rider/auth/login
  Future<bool> login(String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (phone.isNotEmpty && password.length >= 4) {
      _isLoggedIn = true;
      _riderPhone = phone;
      _riderName = 'Ahmed Khan';
      notifyListeners();
      return true;
    }
    return false;
  }

  // Rider logout
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // Accept a delivery request
  // TODO: Replace with real API call to POST /rider/orders/{id}/accept
  void acceptOrder(DeliveryOrderModel order) {
    _availableOrders.removeWhere((o) => o.id == order.id);
    _activeOrder = order.copyWith(
      status: OrderStatus.ready,
      isAvailable: false,
    );
    notifyListeners();
  }

  // Reject a delivery request
  // TODO: Replace with real API call to POST /rider/orders/{id}/reject
  void rejectOrder(String orderId) {
    _availableOrders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  // Advance the active order status to the next step
  // TODO: Replace with real API call to PATCH /rider/orders/{id}/status
  void advanceActiveOrderStatus() {
    if (_activeOrder == null) return;

    final currentStatus = _activeOrder!.status;

    if (currentStatus == OrderStatus.ready || currentStatus == OrderStatus.placed || currentStatus == OrderStatus.confirmed || currentStatus == OrderStatus.preparing) {
      _activeOrder = _activeOrder!.copyWith(status: OrderStatus.pickedUp);
      notifyListeners();
    } else if (currentStatus == OrderStatus.pickedUp) {
      _activeOrder = _activeOrder!.copyWith(status: OrderStatus.onTheWay);
      notifyListeners();
    } else if (currentStatus == OrderStatus.onTheWay) {
      final finishedOrder = _activeOrder!.copyWith(status: OrderStatus.delivered);
      _completedOrders.insert(0, finishedOrder);
      _totalDeliveriesAllTime++;
      _activeOrder = null;
      notifyListeners();
    }
  }

  // Cancel an active order
  // TODO: Replace with real API call to POST /rider/orders/{id}/cancel
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
