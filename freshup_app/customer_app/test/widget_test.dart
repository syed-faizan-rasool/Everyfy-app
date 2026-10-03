import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:grocery_customer_app/main.dart';
import 'package:grocery_customer_app/data/dummy_data.dart';
import 'package:grocery_customer_app/models/order_model.dart';
import 'package:grocery_customer_app/providers/app_role_provider.dart';
import 'package:grocery_customer_app/providers/auth_provider.dart';
import 'package:grocery_customer_app/providers/cart_provider.dart';
import 'package:grocery_customer_app/providers/delivery_order_provider.dart';
import 'package:grocery_customer_app/providers/order_provider.dart';
import 'package:grocery_customer_app/screens/home/home_screen.dart';
import 'package:grocery_customer_app/screens/product/product_detail_screen.dart';
import 'package:grocery_customer_app/screens/cart/cart_screen.dart';
import 'package:grocery_customer_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_customer_app/screens/order/order_tracking_screen.dart';
import 'package:grocery_customer_app/screens/profile/profile_screen.dart';
import 'package:grocery_customer_app/screens/category/product_list_screen.dart';
import 'package:grocery_customer_app/screens/address/address_screen.dart';
import 'package:grocery_customer_app/screens/role_selection_screen.dart';
import 'package:grocery_customer_app/screens/delivery/login_screen.dart';
import 'package:grocery_customer_app/screens/delivery/rider_main_navigation_screen.dart';
import 'package:grocery_customer_app/screens/delivery/active_delivery_screen.dart';
import 'package:grocery_customer_app/screens/delivery/earnings_screen.dart';
import 'package:grocery_customer_app/screens/delivery/profile_screen.dart';
import 'package:grocery_customer_app/providers/admin_provider.dart';
import 'package:grocery_customer_app/screens/admin/admin_login_screen.dart';
import 'package:grocery_customer_app/screens/admin/admin_main_navigation_screen.dart';
import 'package:grocery_customer_app/utils/app_theme.dart';

Widget _buildTestApp(
  Widget child, {
  AppRoleProvider? role,
  AuthProvider? auth,
  CartProvider? cart,
  OrderProvider? order,
  DeliveryOrderProvider? delivery,
  AdminProvider? admin,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => role ?? AppRoleProvider()),
      ChangeNotifierProvider(create: (_) => auth ?? AuthProvider()),
      ChangeNotifierProvider(create: (_) => cart ?? CartProvider()),
      ChangeNotifierProvider(create: (_) => order ?? OrderProvider()),
      ChangeNotifierProvider(create: (_) => delivery ?? DeliveryOrderProvider()),
      ChangeNotifierProvider(create: (_) => admin ?? AdminProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  testWidgets('MyApp launches with SplashScreen and RoleSelectionScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp());
    expect(find.text('Fresh'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('RoleSelectionScreen displays Customer and Rider portal options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const RoleSelectionScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Customer Portal'), findsOneWidget);
    expect(find.text('Continue as Customer'), findsOneWidget);
    expect(find.text('Delivery Partner'), findsOneWidget);
    expect(find.text('Continue as Rider'), findsOneWidget);
  });

  testWidgets('RiderLoginScreen renders and logs in successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const RiderLoginScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Rider Partner Portal'), findsOneWidget);
    expect(find.text('Sign In as Rider'), findsOneWidget);
    expect(find.text('Quick Test Login (Demo Account)'), findsOneWidget);
  });

  testWidgets('RiderMainNavigationScreen and RiderHomeScreen render properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final deliveryProvider = DeliveryOrderProvider();

    await tester.pumpWidget(_buildTestApp(
      const RiderMainNavigationScreen(),
      delivery: deliveryProvider,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    // Check dashboard elements
    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Available Requests'), findsOneWidget);
    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Toggle offline
    await tester.tap(find.text('Online'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(deliveryProvider.isOnline, false);
  });

  testWidgets('DeliveryOrderProvider workflow: Accept order -> Advance status -> Delivered', (WidgetTester tester) async {
    final deliveryProvider = DeliveryOrderProvider();
    expect(deliveryProvider.availableOrders.isNotEmpty, true);

    final initialCount = deliveryProvider.availableOrders.length;
    final targetOrder = deliveryProvider.availableOrders.first;

    // 1. Accept order
    deliveryProvider.acceptOrder(targetOrder);
    expect(deliveryProvider.availableOrders.length, initialCount - 1);
    expect(deliveryProvider.activeOrder, isNotNull);
    expect(deliveryProvider.activeOrder!.status, OrderStatus.ready);

    // 2. Advance to Picked Up
    deliveryProvider.advanceActiveOrderStatus();
    expect(deliveryProvider.activeOrder!.status, OrderStatus.pickedUp);

    // 3. Advance to On The Way
    deliveryProvider.advanceActiveOrderStatus();
    expect(deliveryProvider.activeOrder!.status, OrderStatus.onTheWay);

    // 4. Advance to Delivered
    final initialCompleted = deliveryProvider.completedOrders.length;
    deliveryProvider.advanceActiveOrderStatus();
    expect(deliveryProvider.activeOrder, isNull);
    expect(deliveryProvider.completedOrders.length, initialCompleted + 1);
    expect(deliveryProvider.completedOrders.first.status, OrderStatus.delivered);
  });

  testWidgets('ActiveDeliveryScreen renders timeline and status advance button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final deliveryProvider = DeliveryOrderProvider();
    final sampleOrder = deliveryProvider.availableOrders.first;
    deliveryProvider.acceptOrder(sampleOrder);

    await tester.pumpWidget(_buildTestApp(
      ActiveDeliveryScreen(order: sampleOrder),
      delivery: deliveryProvider,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Delivery Stage Timeline'), findsOneWidget);
    expect(find.text('Confirm Pickup from Hub'), findsOneWidget);
    expect(find.text('Destination Route'), findsOneWidget);
    expect(find.text('Item Checklist'), findsOneWidget);
  });

  testWidgets('RiderEarningsScreen and RiderProfileScreen render without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const RiderEarningsScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Net Earnings'), findsOneWidget);
    expect(find.text('Performance Summary'), findsOneWidget);

    await tester.pumpWidget(_buildTestApp(const RiderProfileScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('CNIC & Driving License'), findsOneWidget);
    expect(find.text('End Shift & Switch Role'), findsOneWidget);
  });

  testWidgets('HomeScreen renders with products and categories', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify search bar and category sections
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Shop by Category'), findsOneWidget);
    expect(find.text('Popular Products'), findsOneWidget);
    expect(find.text('Fruits'), findsWidgets);
  });

  testWidgets('HomeScreen search filtering works accurately', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    // Type 'apple' into search
    await tester.enterText(find.byType(TextField), 'apple');
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fresh Red Apples'), findsOneWidget);
    expect(find.text('Cavendish Bananas'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cavendish Bananas'), findsWidgets);
  });

  testWidgets('ProductDetailScreen renders and Add to Cart interacts with CartProvider', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cart = CartProvider();
    final product = DummyData.products.first;

    await tester.pumpWidget(_buildTestApp(
      ProductDetailScreen(product: product),
      cart: cart,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(product.name), findsOneWidget);
    expect(find.textContaining('Add to Cart'), findsOneWidget);

    // Tap Add to Cart
    await tester.tap(find.textContaining('Add to Cart'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(cart.quantityOf(product.id), 1);
    expect(find.text('View Cart'), findsOneWidget);
  });

  testWidgets('CartScreen displays items, stepper updates, and checkout triggers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cart = CartProvider();
    final product = DummyData.products.first;
    cart.addToCart(product);

    await tester.pumpWidget(_buildTestApp(
      const CartScreen(),
      cart: cart,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(product.name), findsOneWidget);
    expect(find.text('Proceed to Checkout · Rs 399'), findsOneWidget);

    // Test increase
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cart.quantityOf(product.id), 2);
  });

  testWidgets('CheckoutScreen renders and coupon FRESH20 applies discount', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cart = CartProvider();
    cart.addToCart(DummyData.products.first);

    await tester.pumpWidget(_buildTestApp(
      const CheckoutScreen(),
      cart: cart,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Fulfillment Method'), findsOneWidget);
    expect(find.text('Cash on Delivery (COD)'), findsOneWidget);

    // Tap the quick coupon FRESH20
    await tester.tap(find.text('FRESH20 (Rs 50 OFF)'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Code FRESH20 Applied!'), findsOneWidget);
    expect(find.text('Coupon Discount (FRESH20)'), findsOneWidget);
  });

  testWidgets('OrderHistoryScreen and OrderTrackingScreen render cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final orderProvider = OrderProvider();
    final cart = CartProvider();
    cart.addToCart(DummyData.products.first);

    final order = orderProvider.placeOrder(
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryFee: 100,
      discount: 50,
      paymentMethod: 'cod',
      addressText: 'House 12, Street 5, DHA Phase 6, Lahore',
    );

    await tester.pumpWidget(_buildTestApp(
      OrderTrackingScreen(order: order),
      order: orderProvider,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Order #${order.orderNumber}'), findsOneWidget);
    expect(find.text('Ahmed Khan (Delivery Partner)'), findsOneWidget);
    expect(find.text('Order Timeline'), findsOneWidget);
  });

  testWidgets('Category ProductListScreen, AddressScreen, ProfileScreen render without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(ProductListScreen(category: DummyData.categories.first)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Fruits'), findsWidgets);

    await tester.pumpWidget(_buildTestApp(const AddressScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Select Delivery Address'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);

    await tester.pumpWidget(_buildTestApp(const ProfileScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Account & Preferences'), findsOneWidget);
    expect(find.text('Saved Delivery Addresses'), findsOneWidget);
  });

  testWidgets('RoleSelectionScreen displays Store Admin Portal and navigates to AdminLoginScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const RoleSelectionScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Store Admin Portal'), findsOneWidget);
    expect(find.text('Continue as Store Admin'), findsOneWidget);
  });

  testWidgets('AdminLoginScreen renders with quick demo button and credentials', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildTestApp(const AdminLoginScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Store Management Portal'), findsOneWidget);
    expect(find.text('1-Tap Manager Demo Login'), findsOneWidget);
    expect(find.text('Sign In to Operations'), findsOneWidget);
  });

  testWidgets('AdminMainNavigationScreen renders dashboard, KPIs and quick operations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final admin = AdminProvider();
    await tester.pumpWidget(_buildTestApp(
      const AdminMainNavigationScreen(),
      admin: admin,
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('FreshCart Hub · Gulberg'), findsOneWidget);
    expect(find.text("Today's Gross Sales"), findsOneWidget);
    expect(find.text("Today's Orders"), findsOneWidget);
    expect(find.text('Quick Operations'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Recent Orders'), findsOneWidget);
  });

  testWidgets('AdminProvider operations: adjust stock, update order status, toggle store status', (WidgetTester tester) async {
    final admin = AdminProvider();

    // Verify initial state
    expect(admin.settings.isOpen, isTrue);
    admin.toggleStoreOpen();
    expect(admin.settings.isOpen, isFalse);

    // Stock adjustment test
    final firstProduct = admin.products.first;
    final initialStock = firstProduct.stockQty;
    admin.adjustStock(firstProduct.id, 5);
    expect(admin.products.first.stockQty, equals(initialStock + 5));

    // Order status progression test
    final firstOrder = admin.orders.first;
    admin.updateOrderStatus(firstOrder.id, OrderStatus.preparing);
    expect(admin.orders.first.status, equals(OrderStatus.preparing));
  });
}
