import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders.reversed);

  // TODO: Replace with real API call to POST /orders/checkout
  OrderModel placeOrder({
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required String paymentMethod,
    required String addressText,
  }) {
    final order = OrderModel(
      orderNumber: 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      items: List.from(items),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: subtotal + deliveryFee - discount,
      paymentMethod: paymentMethod,
      addressText: addressText,
      status: OrderStatus.placed,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    notifyListeners();
    return order;
  }
}
