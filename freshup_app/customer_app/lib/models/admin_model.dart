import 'order_model.dart';
import 'cart_item_model.dart';
import 'product_model.dart';

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "Store Owner", "Operations Manager"
  final String phone;
  final String avatarUrl;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Store Operations Manager',
    required this.phone,
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
  });
}

class StoreSettingsModel {
  bool isOpen;
  double minOrderAmount;
  double baseDeliveryFee;
  double freeDeliveryThreshold;
  String storeName;
  String storeAddress;
  String supportPhone;
  String openingHours;

  StoreSettingsModel({
    this.isOpen = true,
    this.minOrderAmount = 300,
    this.baseDeliveryFee = 120,
    this.freeDeliveryThreshold = 2000,
    this.storeName = 'Everyfy Hub · Gojra',
    this.storeAddress = 'Main Bazaar, Gojra',
    this.supportPhone = '046-3510099',
    this.openingHours = '08:00 AM - 11:30 PM',
  });

  StoreSettingsModel copyWith({
    bool? isOpen,
    double? minOrderAmount,
    double? baseDeliveryFee,
    double? freeDeliveryThreshold,
    String? storeName,
    String? storeAddress,
    String? supportPhone,
    String? openingHours,
  }) {
    return StoreSettingsModel(
      isOpen: isOpen ?? this.isOpen,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      baseDeliveryFee: baseDeliveryFee ?? this.baseDeliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      supportPhone: supportPhone ?? this.supportPhone,
      openingHours: openingHours ?? this.openingHours,
    );
  }
}

enum FleetDutyStatus { available, onDelivery, offline }

class RiderFleetMemberModel {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final double rating;
  final int completedToday;
  final double earningsToday;
  FleetDutyStatus status;
  String? currentOrderId;

  RiderFleetMemberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    this.rating = 4.8,
    this.completedToday = 0,
    this.earningsToday = 0,
    this.status = FleetDutyStatus.available,
    this.currentOrderId,
  });

  RiderFleetMemberModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicle,
    double? rating,
    int? completedToday,
    double? earningsToday,
    FleetDutyStatus? status,
    String? currentOrderId,
  }) {
    return RiderFleetMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      rating: rating ?? this.rating,
      completedToday: completedToday ?? this.completedToday,
      earningsToday: earningsToday ?? this.earningsToday,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }

  factory RiderFleetMemberModel.fromJson(Map<String, dynamic> json) {
    FleetDutyStatus status = FleetDutyStatus.available;
    final isOnline = json['is_online'] == true || json['is_online'] == 1 || json['is_online'] == '1';
    final currentOrder = json['current_order']?.toString();
    if (currentOrder != null && currentOrder.isNotEmpty) {
      status = FleetDutyStatus.onDelivery;
    } else if (!isOnline) {
      status = FleetDutyStatus.offline;
    } else {
      status = FleetDutyStatus.available;
    }

    final vehicleStr = json['vehicle'] != null
        ? json['vehicle'].toString()
        : '${json['vehicle_type'] ?? 'Motorcycle'} · ${json['vehicle_number'] ?? ''}';

    return RiderFleetMemberModel(
      id: json['id']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Rider',
      phone: json['phone']?.toString() ?? '',
      vehicle: vehicleStr,
      rating: double.tryParse((json['rating'] ?? 5.0).toString()) ?? 5.0,
      completedToday: int.tryParse((json['total_deliveries'] ?? 0).toString()) ?? 0,
      earningsToday: 0.0,
      status: status,
      currentOrderId: currentOrder,
    );
  }
}

class CouponModel {
  final String id;
  final String code;
  final double discountPercent;
  final double maxDiscount;
  final double minOrderValue;
  final DateTime expiryDate;
  bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.expiryDate,
    this.isActive = true,
  });
}

class AdminOrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String address;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;
  OrderStatus status;
  String? assignedRiderId;
  String? assignedRiderName;
  String? assignedRiderPhone;
  final String? customerNotes;

  AdminOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.status = OrderStatus.placed,
    this.assignedRiderId,
    this.assignedRiderName,
    this.assignedRiderPhone,
    this.customerNotes,
  });

  AdminOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? address,
    List<CartItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    String? paymentMethod,
    DateTime? createdAt,
    OrderStatus? status,
    String? assignedRiderId,
    String? assignedRiderName,
    String? assignedRiderPhone,
    String? customerNotes,
  }) {
    return AdminOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedRiderId: assignedRiderId ?? this.assignedRiderId,
      assignedRiderName: assignedRiderName ?? this.assignedRiderName,
      assignedRiderPhone: assignedRiderPhone ?? this.assignedRiderPhone,
      customerNotes: customerNotes ?? this.customerNotes,
    );
  }

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List).map((i) {
        final pName = i['name'] ?? i['product_name'] ?? 'Product';
        final pPrice = double.tryParse((i['price'] ?? i['product_price'] ?? 0).toString()) ?? 0.0;
        final pQty = int.tryParse((i['quantity'] ?? 1).toString()) ?? 1;
        return CartItemModel(
          product: ProductModel(
            id: int.tryParse((i['product_id'] ?? 0).toString()) ?? 0,
            categoryId: 1,
            name: pName.toString(),
            description: '',
            image: i['image']?.toString() ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500',
            price: pPrice,
            unit: i['unit']?.toString() ?? '1 pc',
            stockQty: int.tryParse((i['stock_qty'] ?? 10).toString()) ?? 10,
          ),
          quantity: pQty,
        );
      }).toList();
    }

    return AdminOrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? (json['id']?.toString() ?? 'ORD-0'),
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      address: json['address']?.toString() ?? (json['address_text']?.toString() ?? ''),
      items: items,
      subtotal: double.tryParse((json['subtotal'] ?? 0).toString()) ?? 0.0,
      deliveryFee: double.tryParse((json['delivery_fee'] ?? 0).toString()) ?? 0.0,
      discount: double.tryParse((json['discount'] ?? 0).toString()) ?? 0.0,
      total: double.tryParse((json['total'] ?? json['total_amount'] ?? 0).toString()) ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'Cash on Delivery',
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      status: OrderModel.parseStatus(json['status']?.toString() ?? json['order_status']?.toString()),
      assignedRiderId: json['delivery_boy_id']?.toString(),
      assignedRiderName: json['rider_name']?.toString(),
      assignedRiderPhone: json['rider_phone']?.toString(),
      customerNotes: json['notes']?.toString(),
    );
  }
}
