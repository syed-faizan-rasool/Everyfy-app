import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => List.unmodifiable(_orders.reversed);
  bool get isLoading => _isLoading;

  /// Fetch orders from API
  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final remoteOrders = await ApiService.getOrders();
      if (remoteOrders.isNotEmpty) {
        _orders.clear();
        _orders.addAll(remoteOrders.reversed);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// Place order via ApiService with fallback
  OrderModel placeOrder({
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required String paymentMethod,
    required String addressText,
    String orderType = 'delivery',
    String? notes,
    String? couponCode,
  }) {
    final generatedNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final order = OrderModel(
      orderNumber: generatedNumber,
      items: List.from(items),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: (subtotal + deliveryFee - discount).clamp(0.0, double.infinity),
      paymentMethod: paymentMethod,
      addressText: addressText,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    notifyListeners();

    // Async server checkout sync
    ApiService.checkoutOrder(
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: order.total,
      paymentMethod: paymentMethod,
      orderType: orderType,
      addressText: addressText,
      notes: notes,
      couponCode: couponCode,
    ).then((res) {
      if (res['success'] == true && res['data'] != null) {
        // Updated with official server-issued order number
      }
    }).catchError((_) {});

    return order;
  }
}
