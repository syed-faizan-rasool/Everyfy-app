import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/admin_model.dart';
import '../../providers/admin_provider.dart';

class AdminCouponsScreen extends StatelessWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final coupons = admin.coupons;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Promotions & Coupons',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0D5C3A), size: 24),
            onPressed: () => _openAddCouponDialog(context, admin),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: coupons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final cpn = coupons[idx];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cpn.isActive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0D5C3A).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        cpn.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D5C3A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: cpn.isActive,
                      activeTrackColor: const Color(0xFF0D5C3A),
                      activeThumbColor: Colors.white,
                      onChanged: (_) => admin.toggleCoupon(cpn.id),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${cpn.discountPercent.toStringAsFixed(0)}% OFF (Up to Rs ${cpn.maxDiscount.toStringAsFixed(0)})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid on orders above Rs ${cpn.minOrderValue.toStringAsFixed(0)} · Expires: ${dateFormat.format(cpn.expiryDate)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAddCouponDialog(BuildContext context, AdminProvider admin) {
    final codeController = TextEditingController();
    final percentController = TextEditingController(text: '15');
    final maxController = TextEditingController(text: '250');
    final minController = TextEditingController(text: '800');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Discount Coupon', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Coupon Code', hintText: 'e.g. FLASH25'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount %', hintText: '15'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max Discount (Rs)', hintText: '250'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min Order Amount (Rs)', hintText: '800'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                admin.addCoupon(
                  CouponModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    code: codeController.text.trim().toUpperCase(),
                    discountPercent: double.tryParse(percentController.text.trim()) ?? 10,
                    maxDiscount: double.tryParse(maxController.text.trim()) ?? 200,
                    minOrderValue: double.tryParse(minController.text.trim()) ?? 500,
                    expiryDate: DateTime.now().add(const Duration(days: 30)),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon ${codeController.text.trim().toUpperCase()} activated')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5C3A)),
            child: const Text('Create Coupon'),
          ),
        ],
      ),
    );
  }
}
