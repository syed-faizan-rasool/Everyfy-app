import 'cart_item_model.dart';
import 'order_model.dart';

/// Rider delivery status. Reuses and matches OrderStatus directly
/// so order state is 100% consistent across both Customer and Rider sides.
typedef DeliveryStatus = OrderStatus;

class DeliveryOrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String address;
  final String storeAddress;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final double distanceKm;
  final double earning;
  final DateTime createdAt;
  final OrderStatus status;
  final bool isAvailable;
  final String notes;

  DeliveryOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    this.storeAddress = 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.distanceKm,
    required this.earning,
    required this.createdAt,
    this.status = OrderStatus.ready,
    this.isAvailable = true,
    this.notes = 'Leave package at front gate if not answered',
  });

  DeliveryOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? address,
    String? storeAddress,
    List<CartItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    String? paymentMethod,
    double? distanceKm,
    double? earning,
    DateTime? createdAt,
    OrderStatus? status,
    bool? isAvailable,
    String? notes,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      storeAddress: storeAddress ?? this.storeAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      distanceKm: distanceKm ?? this.distanceKm,
      earning: earning ?? this.earning,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': address,
      'store_address': storeAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': paymentMethod,
      'distance_km': distanceKm,
      'earning': earning,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'is_available': isAvailable,
      'notes': notes,
    };
  }

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> orderItems = [];
    if (json['items'] is List) {
      orderItems = (json['items'] as List)
          .map((i) => CartItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    return DeliveryOrderModel(
      id: (json['id'] ?? '').toString(),
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Customer',
      customerPhone: json['customer_phone'] ?? json['customerPhone'] ?? '',
      address: json['address'] ?? json['address_text'] ?? '',
      storeAddress: json['store_address'] ?? 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
      items: orderItems,
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      deliveryFee: double.tryParse((json['delivery_fee'] ?? json['deliveryFee'] ?? 0).toString()) ?? 0.0,
      total: double.tryParse((json['total'] ?? json['total_amount'] ?? 0).toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cod',
      distanceKm: double.tryParse((json['distance_km'] ?? json['distanceKm'] ?? 3.0).toString()) ?? 3.0,
      earning: double.tryParse((json['earning'] ?? json['rider_earning'] ?? 120.0).toString()) ?? 120.0,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: OrderModel.parseStatus(json['status'] ?? json['order_status']),
      isAvailable: json['is_available'] == 1 || json['is_available'] == true || json['isAvailable'] == true,
      notes: json['notes'] ?? 'Leave package at front gate',
    );
  }
}
