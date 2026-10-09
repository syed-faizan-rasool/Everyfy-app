import '../models/cart_item_model.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';
import 'dummy_data.dart';

class DummyDeliveryData {
  static List<DeliveryOrderModel> getInitialAvailableOrders() {
    return [
      DeliveryOrderModel(
        id: 'DEL-101',
        orderNumber: 'ORD-9821',
        customerName: 'Fatima Zahra',
        customerPhone: '03004455667',
        address: 'House 42, Street 6, Sector Y, Phase 3, DHA, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[0], quantity: 2), // Apples
          CartItemModel(product: DummyData.products[4], quantity: 3), // Milk
          CartItemModel(product: DummyData.products[6], quantity: 1), // Bread
        ],
        subtotal: 1408,
        deliveryFee: 150,
        total: 1558,
        paymentMethod: 'Cash on Delivery',
        distanceKm: 3.4,
        earning: 180,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        status: OrderStatus.ready,
        isAvailable: true,
        notes: 'Ring bell twice upon arrival',
      ),
      DeliveryOrderModel(
        id: 'DEL-102',
        orderNumber: 'ORD-9822',
        customerName: 'Ali Raza',
        customerPhone: '03217891234',
        address: 'Apartment 4B, Gulberg Heights, Block G, Gulberg II, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[1], quantity: 2), // Bananas
          CartItemModel(product: DummyData.products[2], quantity: 1), // Tomatoes
          CartItemModel(product: DummyData.products[7], quantity: 2), // Orange Juice
        ],
        subtotal: 960,
        deliveryFee: 120,
        total: 1080,
        paymentMethod: 'Paid Online (Debit Card)',
        distanceKm: 1.8,
        earning: 140,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        status: OrderStatus.ready,
        isAvailable: true,
        notes: 'Leave at front reception with Mr. Aslam',
      ),
      DeliveryOrderModel(
        id: 'DEL-103',
        orderNumber: 'ORD-9825',
        customerName: 'Usman Tariq',
        customerPhone: '03339012345',
        address: 'Villa 18, Block B, Model Town, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[5], quantity: 2), // Cheese
          CartItemModel(product: DummyData.products[4], quantity: 2), // Milk
          CartItemModel(product: DummyData.products[8], quantity: 4), // Crisps
        ],
        subtotal: 1740,
        deliveryFee: 180,
        total: 1920,
        paymentMethod: 'Cash on Delivery',
        distanceKm: 5.2,
        earning: 240,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: OrderStatus.ready,
        isAvailable: true,
        notes: 'Call before arriving at the security gate',
      ),
      DeliveryOrderModel(
        id: 'DEL-104',
        orderNumber: 'ORD-9830',
        customerName: 'Ayesha Malik',
        customerPhone: '03124567890',
        address: 'House 88, Lane 4, Cavalry Ground, Cantt, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[0], quantity: 1), // Apples
          CartItemModel(product: DummyData.products[3], quantity: 2), // Potatoes
          CartItemModel(product: DummyData.products[7], quantity: 1), // Juice
        ],
        subtotal: 759,
        deliveryFee: 150,
        total: 909,
        paymentMethod: 'Paid Online (JazzCash)',
        distanceKm: 4.1,
        earning: 210,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        status: OrderStatus.ready,
        isAvailable: true,
        notes: 'Deliver quickly please, cooking dinner',
      ),
    ];
  }

  static List<DeliveryOrderModel> getInitialCompletedOrders() {
    return [
      DeliveryOrderModel(
        id: 'DEL-095',
        orderNumber: 'ORD-9780',
        customerName: 'Zainab Bibi',
        customerPhone: '03021122334',
        address: 'House 14, Main Canal Bank Road, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[4], quantity: 4), // Milk
          CartItemModel(product: DummyData.products[6], quantity: 2), // Bread
        ],
        subtotal: 1200,
        deliveryFee: 150,
        total: 1350,
        paymentMethod: 'Cash on Delivery',
        distanceKm: 3.8,
        earning: 190,
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        status: OrderStatus.delivered,
        isAvailable: false,
      ),
      DeliveryOrderModel(
        id: 'DEL-094',
        orderNumber: 'ORD-9774',
        customerName: 'Bilal Hassan',
        customerPhone: '03456677889',
        address: 'Plaza 12, Civic Center, Johar Town, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[0], quantity: 3), // Apples
          CartItemModel(product: DummyData.products[5], quantity: 1), // Cheese
        ],
        subtotal: 1317,
        deliveryFee: 200,
        total: 1517,
        paymentMethod: 'Paid Online (Easypaisa)',
        distanceKm: 6.5,
        earning: 270,
        createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
        status: OrderStatus.delivered,
        isAvailable: false,
      ),
      DeliveryOrderModel(
        id: 'DEL-093',
        orderNumber: 'ORD-9762',
        customerName: 'Hina Qureshi',
        customerPhone: '03225566778',
        address: 'Street 9, Sector K, Phase 5, DHA, Lahore',
        storeAddress: 'Everyfy Hub · Main Boulevard, Gulberg III, Lahore',
        items: [
          CartItemModel(product: DummyData.products[1], quantity: 3), // Bananas
          CartItemModel(product: DummyData.products[7], quantity: 3), // Juice
          CartItemModel(product: DummyData.products[8], quantity: 2), // Crisps
        ],
        subtotal: 1500,
        deliveryFee: 180,
        total: 1680,
        paymentMethod: 'Cash on Delivery',
        distanceKm: 5.0,
        earning: 230,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        status: OrderStatus.delivered,
        isAvailable: false,
      ),
    ];
  }
}
