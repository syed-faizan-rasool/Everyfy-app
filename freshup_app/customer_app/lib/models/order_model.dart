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

  String get toDbString {
    switch (this) {
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
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

  static OrderStatus parseStatus(String? str) {
    if (str == null) return OrderStatus.placed;
    final s = str.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (s) {
      case 'placed':
        return OrderStatus.placed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'picked_up':
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'on_the_way':
      case 'ontheway':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'address_text': addressText,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> orderItems = [];
    if (json['items'] is List) {
      orderItems = (json['items'] as List)
          .map((i) => CartItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    return OrderModel(
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      items: orderItems,
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      deliveryFee: double.tryParse((json['delivery_fee'] ?? json['deliveryFee'] ?? 0).toString()) ?? 0.0,
      discount: double.tryParse((json['discount'] ?? 0).toString()) ?? 0.0,
      total: double.tryParse((json['total'] ?? json['total_amount'] ?? 0).toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? 'cod',
      addressText: json['address_text'] ?? json['address'] ?? json['addressText'] ?? '',
      status: parseStatus(json['status'] ?? json['order_status']),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
