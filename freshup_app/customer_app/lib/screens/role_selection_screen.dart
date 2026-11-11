import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/app_role_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_order_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/animated_widgets.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_main_navigation_screen.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'delivery/login_screen.dart';
import 'delivery/rider_main_navigation_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _selectCustomer(BuildContext context) {
    final auth = context.read<AuthProvider>();
    context.read<AppRoleProvider>().setRole(AppRole.customer);
    context.read<NotificationProvider>().setRoleAndUser(
      role: 'customer',
      userId: auth.userId > 0 ? auth.userId : null,
    );
    final isCustomerLoggedIn = auth.isLoggedIn;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isCustomerLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  void _selectRider(BuildContext context) {
    final auth = context.read<AuthProvider>();
    context.read<AppRoleProvider>().setRole(AppRole.rider);
    context.read<NotificationProvider>().setRoleAndUser(
      role: 'rider',
      userId: auth.userId > 0 ? auth.userId : null,
    );
    context.read<DeliveryOrderProvider>().startLivePolling();
    final isRiderLoggedIn = context.read<DeliveryOrderProvider>().isLoggedIn;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isRiderLoggedIn ? const RiderMainNavigationScreen() : const RiderLoginScreen(),
      ),
    );
  }

  void _selectAdmin(BuildContext context) {
    context.read<AppRoleProvider>().setRole(AppRole.admin);
    context.read<NotificationProvider>().setRoleAndUser(role: 'admin');
    context.read<AdminProvider>().startLivePolling();
    final isAdminLoggedIn = context.read<AdminProvider>().isLoggedIn;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isAdminLoggedIn ? const AdminMainNavigationScreen() : const AdminLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Brand Logo Header
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF136E44), AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.shopping_basket_rounded, size: 42, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Fresh',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Cart',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your role to get started',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Option 1: Customer Role Card
              BouncingButton(
                onTap: () => _selectCustomer(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Portal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Buy Fresh Groceries',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Order fresh produce, dairy, bakery and daily essentials with fast doorstep delivery in 30 minutes.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => _selectCustomer(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue as Customer'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Option 2: Rider / Delivery Boy Role Card
              BouncingButton(
                onTap: () => _selectRider(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.electric_moped_rounded,
                              color: AppColors.accent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Partner',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Drive & Earn Daily',
                                  style: TextStyle(
                                    color: AppColors.accentDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Accept instant delivery orders, navigate optimized routes, and earn competitive payouts with daily cashout.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        onPressed: () => _selectRider(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentDark,
                          side: const BorderSide(color: AppColors.accent, width: 1.5),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue as Rider'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Option 3: Store Manager / Admin Portal Card
              BouncingButton(
                onTap: () => _selectAdmin(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF1E293B).withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Color(0xFF1E293B),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store Admin Portal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage Catalog, Orders & Fleet',
                                  style: TextStyle(
                                    color: Color(0xFF0D5C3A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Full operational control: live order kitchen queue, rider dispatching, inventory stock levels, and store analytics.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => _selectAdmin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue as Store Admin'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Bottom note
              const Center(
                child: Text(
                  'You can switch roles anytime from your profile settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
