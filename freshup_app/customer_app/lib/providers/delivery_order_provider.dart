import 'package:flutter/foundation.dart';
import '../data/dummy_delivery_data.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class DeliveryOrderProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isLoggedIn = false;
  String _riderName = 'Ahmed Khan';
  String _riderPhone = '03019876543';
  String _riderVehicle = 'Honda CD70 · LEB-4921';
  double _riderRating = 4.9;
  int _totalDeliveriesAllTime = 142;

  List<DeliveryOrderModel> _availableOrders = [];
  DeliveryOrderModel? _activeOrder;
  List<DeliveryOrderModel> _completedOrders = [];

  DeliveryOrderProvider() {
    _loadInitialData();
    fetchAvailableOrders();
  }

  void _loadInitialData() {
    _availableOrders = DummyDeliveryData.getInitialAvailableOrders();
    _completedOrders = DummyDeliveryData.getInitialCompletedOrders();
  }

  /// Refresh available orders from server
  Future<void> fetchAvailableOrders() async {
    try {
      final remoteOrders = await ApiService.getRiderAvailableOrders();
      if (remoteOrders.isNotEmpty) {
        _availableOrders = remoteOrders;
        notifyListeners();
      }
    } catch (_) {}
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
    ApiService.riderToggleOnline(_isOnline).catchError((_) => false);
    notifyListeners();
  }

  void setOnlineStatus(bool value) {
    _isOnline = value;
    ApiService.riderToggleOnline(value).catchError((_) => false);
    notifyListeners();
  }

  /// Rider login with backend API & fallback
  Future<bool> login(String phone, String password) async {
    try {
      final res = await ApiService.riderLogin(phone, password);
      if (res['success'] == true && res['data'] != null) {
        _isLoggedIn = true;
        _riderPhone = phone;
        final riderData = res['data']['rider'];
        if (riderData != null) {
          _riderName = riderData['name'] ?? 'Ahmed Khan';
          _riderVehicle = riderData['vehicle_number'] ?? _riderVehicle;
          _riderRating = double.tryParse((riderData['rating'] ?? 4.9).toString()) ?? 4.9;
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
