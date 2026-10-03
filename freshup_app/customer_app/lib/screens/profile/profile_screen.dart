import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_role_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../address/address_screen.dart';
import '../admin/admin_login_screen.dart';
import '../delivery/login_screen.dart';
import '../role_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (r) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 42),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.name.isEmpty ? 'Guest Customer' : auth.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.phone.isNotEmpty ? '+92 ${auth.phone}' : '+92 300 1234567',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🌟 Fresh Club Member',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section: Account & Orders
        const Text(
          'Account & Preferences',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.primary,
                label: 'Saved Delivery Addresses',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressScreen()),
                ),
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _MenuTile(
                icon: Icons.local_offer_outlined,
                iconColor: AppColors.accent,
                label: 'Coupons & Discounts',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Use coupon code FRESH20 for Rs 50 OFF')),
                  );
                },
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _MenuTile(
                icon: Icons.payment_rounded,
                iconColor: const Color(0xFF3B82F6),
                label: 'Payment Methods & Wallets',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('COD, Cards, and Wallets are active')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Switch Portal
        const Text(
          'Switch Portal',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.electric_moped_rounded,
                iconColor: AppColors.accent,
                label: 'Switch to Delivery Partner (Rider Portal)',
                onTap: () {
                  context.read<AppRoleProvider>().setRole(AppRole.rider);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RiderLoginScreen()),
                  );
                },
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _MenuTile(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: const Color(0xFF1E293B),
                label: 'Switch to Store Admin / Manager Portal',
                onTap: () {
                  context.read<AppRoleProvider>().setRole(AppRole.admin);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: General & Support
        const Text(
          'Support & About',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.headset_mic_outlined,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Help & Customer Support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support available 24/7 at support@freshcart.com')),
                  );
                },
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _MenuTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF06B6D4),
                label: 'Privacy Policy & Terms',
                onTap: () {},
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _MenuTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textSecondary,
                label: 'App Version 1.0.0',
                showArrow: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Logout Button
        BouncingButton(
          onTap: () => _showLogoutDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  'Log Out of FreshCart',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (embedded) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool showArrow;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
