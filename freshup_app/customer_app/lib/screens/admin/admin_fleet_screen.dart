import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_model.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';

class AdminFleetScreen extends StatelessWidget {
  const AdminFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final fleet = admin.fleet;

    final availableCount = fleet.where((r) => r.status == FleetDutyStatus.available).length;
    final onDeliveryCount = fleet.where((r) => r.status == FleetDutyStatus.onDelivery).length;
    final offlineCount = fleet.where((r) => r.status == FleetDutyStatus.offline).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Delivery Fleet & Riders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fleet Status KPI Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                  _buildFleetKpi('Active Riders', '${fleet.length}', const Color(0xFF1E293B)),
                  const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1),
                  _buildFleetKpi('Available', '$availableCount', const Color(0xFF15803D)),
                  const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1),
                  _buildFleetKpi('On Delivery', '$onDeliveryCount', const Color(0xFFD97706)),
                  const VerticalDivider(color: Color(0xFFE2E8F0), thickness: 1),
                  _buildFleetKpi('Offline', '$offlineCount', const Color(0xFF94A3B8)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Rider Roster',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            ...fleet.map((rider) => _buildRiderCard(context, admin, rider)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetKpi(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, AdminProvider admin, RiderFleetMemberModel rider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D5C3A), Color(0xFF16794F)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.electric_moped_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rider.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        _buildDutyStatusBadge(rider.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rider.vehicle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '${rider.rating} rating',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.task_alt_rounded, size: 14, color: Color(0xFF0D5C3A)),
                        const SizedBox(width: 4),
                        Text(
                          '${rider.completedToday} orders today',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Row 1: Phone number & Quick Call Button
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                rider.phone,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling rider ${rider.name}...')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFF0D5C3A)),
                      SizedBox(width: 4),
                      Text(
                        'Call',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D5C3A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Action Buttons with full width responsiveness
          Row(
            children: [
              if (rider.status == FleetDutyStatus.available) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openAssignOrderToRiderModal(context, admin, rider),
                    icon: const Icon(Icons.add_task_rounded, size: 15),
                    label: const Text('Assign Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => admin.toggleRiderDuty(rider.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    rider.status == FleetDutyStatus.offline ? 'Go Online' : 'Set Offline',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAssignOrderToRiderModal(BuildContext context, AdminProvider admin, RiderFleetMemberModel rider) {
    final assignableOrders = admin.orders
        .where((o) => o.status == OrderStatus.ready || o.status == OrderStatus.preparing)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Order to ${rider.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text('Select an order ready for dispatch', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              if (assignableOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No orders currently pending dispatch', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              else
                ...assignableOrders.map((o) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D5C3A)),
                      title: Text('${o.orderNumber} · Rs ${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('${o.customerName} · ${o.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          admin.assignRiderToOrder(o.id, rider.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Order ${o.orderNumber} assigned to ${rider.name}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C3A),
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDutyStatusBadge(FleetDutyStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case FleetDutyStatus.available:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Available';
        break;
      case FleetDutyStatus.onDelivery:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'On Delivery';
        break;
      case FleetDutyStatus.offline:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
