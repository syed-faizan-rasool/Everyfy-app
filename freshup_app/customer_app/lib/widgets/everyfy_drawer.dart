import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/address/address_screen.dart';
import '../screens/auth/unified_auth_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/order/custom_order_screen.dart';
import '../screens/order/order_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/role_selection_screen.dart';
import '../utils/app_colors.dart';
import 'app_network_image.dart';

class EveryfyDrawer extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;

  const EveryfyDrawer({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: auth.avatar.isNotEmpty
                          ? (auth.avatar.startsWith('http')
                              ? AppNetworkImage(imageUrl: auth.avatar, fit: BoxFit.cover)
                              : (File(auth.avatar).existsSync()
                                  ? Image.file(File(auth.avatar), fit: BoxFit.cover)
                                  : Image.asset('assets/images/app_logo.png', fit: BoxFit.cover)))
                          : Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shopping_bag_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.isLoggedIn && auth.name.isNotEmpty ? auth.name : 'Welcome to Everyfy',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            auth.isLoggedIn && auth.phone.isNotEmpty
                                ? '+92 ${auth.phone}'
                                : (auth.isLoggedIn && auth.email.isNotEmpty ? auth.email : 'Fresh Groceries Delivered in 15 Mins'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.storefront_rounded,
                  title: 'Shop & Groceries',
                  subtitle: 'Fresh fruits, vegetables, food & bakery',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSwitchTab != null) {
                      onSwitchTab!(0);
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (r) => false,
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'My Orders',
                  subtitle: 'Live order tracking & history',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSwitchTab != null) {
                      onSwitchTab!(1);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Custom Grocery Order',
                  subtitle: "Can't find an item? We'll pick it up",
                  badge: 'NEW',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSwitchTab != null) {
                      onSwitchTab!(2);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomOrderScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Shopping Cart',
                  subtitle: 'View cart items & checkout',
                  badge: cart.itemCount > 0 ? '${cart.itemCount}' : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (onSwitchTab != null) {
                      onSwitchTab!(3);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.location_on_outlined,
                  title: 'Delivery Addresses',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressScreen()),
                    );
                  },
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                _buildDrawerItem(
                  customIcon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF22C55E), size: 20),
                  title: 'WhatsApp Helpline',
                  subtitle: '+92 308 9375296 · 15-min reply',
                  onTap: () async {
                    Navigator.pop(context);
                    final url = Uri.parse('https://wa.me/923089375296?text=Hello%20Everyfy%2C%20I%20need%20assistance');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.pop(context);
                    _showPrivacyPolicyDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.pop(context);
                    _showTermsDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.call_outlined,
                  title: 'Contact Us & Store Info',
                  onTap: () {
                    Navigator.pop(context);
                    _showContactDialog(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile Settings',
                  onTap: () {
                    Navigator.pop(context);
                    if (onSwitchTab != null) {
                      onSwitchTab!(4);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Switch Portal (Rider / Admin)',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Logout / Sign In Tile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: auth.isLoggedIn
                ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                        fontSize: 14.5,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const UnifiedAuthScreen()),
                          (r) => false,
                        );
                      }
                    },
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.login_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Sign In / Register',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 14.5,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UnifiedAuthScreen()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    IconData? icon,
    Widget? customIcon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: customIcon ?? Icon(icon, color: const Color(0xFF334155), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            )
          : null,
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Everyfy Pakistan - User Privacy Notice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(height: 8),
              Text(
                '1. Information We Collect:\nEveryfy collects your delivery address, phone number, and name strictly to fulfill grocery orders within 15 minutes.\n\n'
                '2. Data Security:\nYour login and order data are encrypted and transmitted securely to our cloud servers. We do not sell your personal data to third parties.\n\n'
                '3. Location & GPS:\nYour address location is only used to route the closest delivery partner to your doorstep.\n\n'
                '4. Contact:\nFor inquiries, WhatsApp us at +92 308 9375296 or email support@everyfy.net.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.description_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Everyfy Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(height: 8),
              Text(
                '1. 15-Minute Express Delivery:\nOrders are prepared and dispatched swiftly. In inclement weather or road closures, delivery times may vary slightly.\n\n'
                '2. Pricing & Market Rates:\nFresh vegetables and fruits are priced as per daily Mandi market rates in Gojra.\n\n'
                '3. Cash on Delivery:\nPayment must be made in Pakistani Rupees to the rider upon parcel handover.\n\n'
                '4. Returns & Replacements:\nDamaged or incorrect fresh items will be refunded or replaced immediately upon notifying support.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Everyfy Gojra Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏪 Main Store Address:\nEveryfy Hub, Main Bazaar, Gojra, Punjab', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text('⏰ Operating Hours:\n8:00 AM - 11:30 PM (7 Days a Week)', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
            SizedBox(height: 10),
            Text('📞 Helpline & WhatsApp:\n+92 308 9375296', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Text('✉️ Email:\nsupport@everyfy.net / orders@everyfy.net', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

