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
    this.storeAddress = 'FreshCart Hub · Main Boulevard, Gulberg III, Lahore',
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
}
