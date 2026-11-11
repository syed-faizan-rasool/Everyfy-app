import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_colors.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

class RiderMainNavigationScreen extends StatefulWidget {
  const RiderMainNavigationScreen({super.key});

  @override
  State<RiderMainNavigationScreen> createState() => _RiderMainNavigationScreenState();
}

class _RiderMainNavigationScreenState extends State<RiderMainNavigationScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<NotificationProvider>().setRoleAndUser(
        role: 'rider',
        userId: auth.userId > 0 ? auth.userId : null,
      );
      context.read<DeliveryOrderProvider>().startLivePolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const RiderHomeScreen(),
      const RiderOrderHistoryScreen(embedded: true),
      const RiderEarningsScreen(embedded: true),
      const RiderProfileScreen(embedded: true),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_navIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.moped_outlined),
                selectedIcon: Icon(Icons.moped_rounded),
                label: 'Deliveries',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Earnings',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
