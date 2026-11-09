import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_fleet_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_settings_screen.dart';

class AdminMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainNavigationScreen> createState() => _AdminMainNavigationScreenState();
}

class _AdminMainNavigationScreenState extends State<AdminMainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final pendingOrdersCount = admin.orders.where((o) => o.status == OrderStatus.placed).length;
    final lowStockCount = admin.products.where((p) => p.stockQty <= 10).length;

    final screens = [
      AdminDashboardScreen(onNavigateToTab: _switchTab),
      const AdminOrdersScreen(),
      const AdminInventoryScreen(),
      const AdminFleetScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _switchTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0D5C3A),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingOrdersCount > 0,
                  label: Text('$pendingOrdersCount'),
                  backgroundColor: const Color(0xFFDC2626),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: pendingOrdersCount > 0,
                  label: Text('$pendingOrdersCount'),
                  backgroundColor: const Color(0xFFDC2626),
                  child: const Icon(Icons.receipt_long_rounded),
                ),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: lowStockCount > 0,
                  label: Text('$lowStockCount'),
                  backgroundColor: const Color(0xFFD97706),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: lowStockCount > 0,
                  label: Text('$lowStockCount'),
                  backgroundColor: const Color(0xFFD97706),
                  child: const Icon(Icons.inventory_2_rounded),
                ),
                label: 'Inventory',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.electric_moped_outlined),
                activeIcon: Icon(Icons.electric_moped_rounded),
                label: 'Fleet',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.tune_rounded),
                activeIcon: Icon(Icons.tune_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
