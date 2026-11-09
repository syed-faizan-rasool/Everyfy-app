import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/delivery_order_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';

class RiderEarningsScreen extends StatefulWidget {
  final bool embedded;
  const RiderEarningsScreen({super.key, this.embedded = false});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  int _selectedPeriod = 0; // 0 = Today, 1 = This Week, 2 = This Month

  void _showWithdrawModal(BuildContext context, double balance) {
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No withdrawable balance available yet. Complete deliveries to earn cash!'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    final provider = context.read<DeliveryOrderProvider>();
    String selectedMethod = 'Easypaisa';
    final accountController = TextEditingController(text: provider.riderPhone);
    final amountController = TextEditingController(text: balance.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Withdraw Earnings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Available to withdraw: Rs ${balance.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 18),
              const Text('Select Payout Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              for (final method in ['Easypaisa', 'JazzCash', 'Bank Transfer'])
                InkWell(
                  onTap: () => setModalState(() => selectedMethod = method),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          selectedMethod == method
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selectedMethod == method ? AppColors.primary : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(method, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: accountController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '$selectedMethod Number / Account',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Withdraw Amount (Rs)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  final enteredAccount = accountController.text.trim();
                  if (enteredAccount.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your account number.')),
                    );
                    return;
                  }
                  if (enteredAmount <= 0 || enteredAmount > balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter an amount between Rs 1 and Rs ${balance.toStringAsFixed(0)}.')),
                    );
                    return;
                  }

                  final success = provider.requestWithdrawal(
                    method: selectedMethod,
                    accountNumber: enteredAccount,
                    amount: enteredAmount,
                  );

                  Navigator.pop(ctx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cashout request of Rs ${enteredAmount.toStringAsFixed(0)} submitted successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Confirm Cashout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryOrderProvider>();

    final displayedEarnings = provider.todayEarnings;
    final displayedDeliveries = provider.todayDeliveriesCount;
    final displayedDistance = provider.todayDistanceKm;
    const tips = 0.0;
    final availableBal = provider.availableBalance;

    final avgPerOrder = displayedDeliveries > 0 ? (displayedEarnings / displayedDeliveries) : 0.0;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Time period selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              _buildPeriodTab(0, 'Today'),
              _buildPeriodTab(1, 'This Week'),
              _buildPeriodTab(2, 'This Month'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Main Balance Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Instant Payout',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rs ${availableBal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total Earned: Rs ${provider.todayEarnings.toStringAsFixed(0)} · Withdrawn: Rs ${provider.totalWithdrawn.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: BouncingButton(
                      onTap: () => _showWithdrawModal(context, availableBal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Withdraw Cash',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2x2 Performance Grid
        const Text(
          'Performance Summary',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.delivery_dining_rounded,
                iconColor: AppColors.primary,
                title: 'Deliveries',
                value: '$displayedDeliveries orders',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.route_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Distance',
                value: '${displayedDistance.toStringAsFixed(1)} km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.accent,
                title: 'Customer Tips',
                value: 'Rs ${tips.toStringAsFixed(0)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.success,
                title: 'Avg. per Trip',
                value: 'Rs ${avgPerOrder.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Payout Transfers
        const Text(
          'Recent Payout History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        provider.withdrawals.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history_rounded, size: 36, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text(
                      'No payout requests yet',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'When you cash out your earnings, they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < provider.withdrawals.length; i++) ...[
                      if (i > 0) const Divider(indent: 56, color: AppColors.divider),
                      _buildPayoutTile(
                        title: 'Transferred via ${provider.withdrawals[i].method}',
                        subtitle: '${DateFormat('MMM d, h:mm a').format(provider.withdrawals[i].date)} · ${provider.withdrawals[i].accountNumber}',
                        amount: 'Rs ${provider.withdrawals[i].amount.toStringAsFixed(0)}',
                        status: provider.withdrawals[i].status,
                      ),
                    ],
                  ],
                ),
              ),
        const SizedBox(height: 24),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Earnings & Payouts',
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
        title: const Text('Earnings & Payouts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildPeriodTab(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutTile({
    required String title,
    required String subtitle,
    required String amount,
    required String status,
    bool isBonus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isBonus ? AppColors.accentLight : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBonus ? Icons.card_giftcard_rounded : Icons.arrow_outward_rounded,
              color: isBonus ? AppColors.accent : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
