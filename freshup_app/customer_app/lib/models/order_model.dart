import 'cart_item_model.dart';

enum OrderStatus { placed, confirmed, preparing, ready, pickedUp, onTheWay, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderModel {
  final String orderNumber;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final String addressText;
  final OrderStatus status;
  final DateTime createdAt;

  OrderModel({
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.addressText,
    required this.status,
    required this.createdAt,
  });
}
