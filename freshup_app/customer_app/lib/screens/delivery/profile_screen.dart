import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_role_provider.dart';
import '../../providers/delivery_order_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../auth/unified_auth_screen.dart';

class RiderProfileScreen extends StatelessWidget {
  final bool embedded;
  const RiderProfileScreen({super.key, this.embedded = false});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rider Logout', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to end your shift and return to role selection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DeliveryOrderProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const UnifiedAuthScreen(initialRole: AppRole.rider)),
                (r) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryOrderProvider>();

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rider Header Card
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
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.riderName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+92 ${provider.riderPhone}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            provider.riderVehicle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              // Performance stats bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat('Deliveries', '${provider.totalDeliveriesAllTime}'),
                  Container(width: 1, height: 24, color: Colors.white24),
                  _buildHeaderStat('Rating', '${provider.riderRating} ★'),
                  Container(width: 1, height: 24, color: Colors.white24),
                  _buildHeaderStat('On-Time', '99.2%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Online / Offline Shift Status Toggle Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: provider.isOnline ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: provider.isOnline ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.isOnline ? 'Active on Shift (Online)' : 'Shift Paused (Offline)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.isOnline ? 'Receiving delivery requests' : 'Not receiving delivery requests',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: provider.isOnline,
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
                onChanged: (val) => provider.toggleOnlineStatus(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Documents & Accounts
        const Text(
          'Documents & Payouts',
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
              _buildRiderMenuTile(
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.primary,
                label: 'CNIC & Driving License',
                badgeText: 'Verified',
                badgeColor: AppColors.success,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your documents are verified and valid until 2028.')),
                  );
                },
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _buildRiderMenuTile(
                icon: Icons.two_wheeler_outlined,
                iconColor: const Color(0xFF3B82F6),
                label: 'Vehicle Registration (LEB-4921)',
                badgeText: 'Approved',
                badgeColor: AppColors.success,
                onTap: () {},
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _buildRiderMenuTile(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.accent,
                label: 'Payout Accounts (Easypaisa / JazzCash)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primary payout method: Easypaisa (0301-9876543)')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Preferences & Support
        const Text(
          'Support & Platform',
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
              _buildRiderMenuTile(
                icon: Icons.map_outlined,
                iconColor: const Color(0xFF06B6D4),
                label: 'Delivery Zone (Lahore Central)',
                onTap: () {},
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _buildRiderMenuTile(
                icon: Icons.headset_mic_outlined,
                iconColor: const Color(0xFF8B5CF6),
                label: '24/7 Rider Emergency Helpline',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rider helpline: 042-111-373-748')),
                  );
                },
              ),
              const Divider(indent: 52, color: AppColors.divider),
              _buildRiderMenuTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textSecondary,
                label: 'Rider App Version 1.0.0',
                showArrow: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Logout / Switch Role Button
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
                  'End Shift & Switch Role',
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
        const SizedBox(height: 24),
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
                'Rider Profile',
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
        title: const Text('Rider Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRiderMenuTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
    bool showArrow = true,
  }) {
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
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor ?? AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
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
