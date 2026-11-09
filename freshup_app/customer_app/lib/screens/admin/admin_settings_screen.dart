import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/app_role_provider.dart';
import '../home/home_screen.dart';
import '../delivery/rider_main_navigation_screen.dart';
import '../auth/unified_auth_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_coupons_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final settings = admin.settings;
    final user = admin.adminUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Store Settings & Tools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manager Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.role,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0D5C3A), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Store Operations Setting
            const Text(
              'Store Parameters',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Store Ordering Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text(
                      settings.isOpen ? 'Accepting customer orders' : 'Ordering temporarily paused',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: settings.isOpen,
                    activeTrackColor: const Color(0xFF0D5C3A),
                    activeThumbColor: Colors.white,
                    onChanged: (_) => admin.toggleStoreOpen(),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    title: const Text('Base Delivery Fee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('Current: Rs ${settings.baseDeliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _editNumericSetting(
                      context,
                      'Base Delivery Fee (Rs)',
                      settings.baseDeliveryFee.toStringAsFixed(0),
                      (val) => admin.updateSettings(settings.copyWith(baseDeliveryFee: val)),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    title: const Text('Free Delivery Threshold', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('Orders above: Rs ${settings.freeDeliveryThreshold.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _editNumericSetting(
                      context,
                      'Free Delivery Minimum (Rs)',
                      settings.freeDeliveryThreshold.toStringAsFixed(0),
                      (val) => admin.updateSettings(settings.copyWith(freeDeliveryThreshold: val)),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: Color(0xFF0D5C3A)),
                    title: const Text('Operating Hours (Timer)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text(settings.openingHours, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _editOperatingHoursWithTimer(
                      context,
                      admin,
                      settings.openingHours,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Store Catalog & Marketing Tools
            const Text(
              'Management Tools',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.category_outlined, color: Color(0xFF0D5C3A)),
                    title: const Text('Categories Manager', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${admin.categories.length} categories active', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const Icon(Icons.discount_outlined, color: Color(0xFFD97706)),
                    title: const Text('Promotions & Coupons', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${admin.coupons.length} promotional codes', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCouponsScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Role Switcher for Testing
            const Text(
              'Switch App Experience (Testing)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview the app as Customer or Delivery Rider:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<AppRoleProvider>().setRole(AppRole.customer);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                          label: const Text('Customer View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0D5C3A),
                            side: const BorderSide(color: Color(0xFF0D5C3A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<AppRoleProvider>().setRole(AppRole.rider);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const RiderMainNavigationScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.electric_moped_rounded, size: 16),
                          label: const Text('Rider View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(color: Color(0xFFD97706)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout & Exit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AdminProvider>().logout();
                  context.read<AppRoleProvider>().resetRole();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const UnifiedAuthScreen(initialRole: AppRole.admin)),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Exit Manager Portal / Switch Role', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _editNumericSetting(BuildContext context, String title, String currentVal, Function(double) onSave) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null) {
                onSave(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5C3A)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editOperatingHoursWithTimer(BuildContext context, AdminProvider admin, String currentHours) {
    TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closeTime = const TimeOfDay(hour: 23, minute: 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatTime(TimeOfDay t) {
              final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
              final m = t.minute.toString().padLeft(2, '0');
              final p = t.period == DayPeriod.am ? 'AM' : 'PM';
              return '$h:$m $p';
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.timer_outlined, color: Color(0xFF0D5C3A)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Operating Hours', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text('Pick store opening & closing timer', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: openTime,
                            );
                            if (picked != null) {
                              setModalState(() => openTime = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Opening Timer', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFD97706)),
                                    const SizedBox(width: 6),
                                    Text(formatTime(openTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: closeTime,
                            );
                            if (picked != null) {
                              setModalState(() => closeTime = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Closing Timer', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.nightlight_round_outlined, size: 16, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 6),
                                    Text(formatTime(closeTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final formatted = '${formatTime(openTime)} - ${formatTime(closeTime)}';
                        admin.updateSettings(admin.settings.copyWith(openingHours: formatted));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Operating timer set to $formatted')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Operating Timer', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
