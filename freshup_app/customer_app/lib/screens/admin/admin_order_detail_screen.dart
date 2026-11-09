import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_model.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/order_receipt_service.dart';
import '../../widgets/order_slip_preview_sheet.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final orderList = admin.orders.where((o) => o.id == orderId).toList();

    if (orderList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = orderList.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF0D5C3A), size: 22),
            tooltip: 'Print Rider Delivery Slip',
            onPressed: () => OrderSlipPreviewSheet.show(context, order, admin.settings),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _buildStatusBadge(order.status)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Transition Control Card
            _buildStatusControlCard(context, admin, order),
            const SizedBox(height: 16),

            // Customer Contact & Delivery Info
            _buildCustomerCard(context, order),
            const SizedBox(height: 16),

            // Assigned Rider Card
            _buildRiderCard(context, admin, order),
            const SizedBox(height: 16),

            // Order Items
            _buildOrderItemsCard(order),
            const SizedBox(height: 16),

            // Bill Breakdown
            _buildBillSummaryCard(order),
            const SizedBox(height: 24),

            // Cancel Order Action
            if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancelOrder(context, admin, order),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusControlCard(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Pipeline',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Update state as order progresses through store and delivery',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Action Stepper Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(context, admin, order, OrderStatus.placed, 'Placed', const Color(0xFFDC2626)),
              _buildStatusPill(context, admin, order, OrderStatus.preparing, 'Kitchen Prep', const Color(0xFF7C3AED)),
              _buildStatusPill(context, admin, order, OrderStatus.ready, 'Ready for Rider', const Color(0xFFD97706)),
              _buildStatusPill(context, admin, order, OrderStatus.onTheWay, 'Dispatched', const Color(0xFF0284C7)),
              _buildStatusPill(context, admin, order, OrderStatus.delivered, 'Delivered', const Color(0xFF059669)),
            ],
          ),

          if (order.status == OrderStatus.ready || order.status == OrderStatus.onTheWay) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5C3A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D5C3A), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rider Dispatch Slip Ready',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D5C3A)),
                        ),
                        Text(
                          'Includes notes, checklist, and barcode for rider',
                          style: TextStyle(fontSize: 10, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => OrderSlipPreviewSheet.show(context, order, admin.settings),
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5C3A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, AdminProvider admin, AdminOrderModel order, OrderStatus target, String label, Color color) {
    final isCurrent = order.status == target;

    return ChoiceChip(
      selected: isCurrent,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          color: isCurrent ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selectedColor: color,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isCurrent ? color : const Color(0xFFE2E8F0)),
      ),
      onSelected: (selected) {
        if (selected) {
          admin.updateOrderStatus(order.id, target);
          if (target == OrderStatus.ready) {
            _showReadyAndPrintPrompt(context, admin, order);
          }
        }
      },
    );
  }

  void _showReadyAndPrintPrompt(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Order ${order.orderNumber} is Ready!',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Print the dispatch slip to give to the rider upon collection.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        OrderSlipPreviewSheet.show(context, order, admin.settings);
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Preview Slip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        OrderReceiptService.printOrderSlip(context, order, admin.settings);
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Rider Slip', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerCard(BuildContext context, AdminOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Customer & Delivery Destination',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0D5C3A), size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling customer ${order.customerPhone}...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.customerName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            order.customerPhone,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0D5C3A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.address,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
              ),
            ],
          ),
          if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: ${order.customerNotes}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    final hasRider = order.assignedRiderName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Delivery Dispatch',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              TextButton(
                onPressed: () => _openAssignRiderSheet(context, admin, order.id),
                child: Text(
                  hasRider ? 'Change Rider' : 'Assign Rider',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (hasRider)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.electric_moped_rounded, color: Color(0xFF15803D), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.assignedRiderName!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        order.assignedRiderPhone ?? '0301-9876543',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF15803D), size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling rider ${order.assignedRiderName}...')),
                    );
                  },
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No delivery partner assigned yet. Tap "Assign Rider" to dispatch.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(AdminOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${order.items.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.image,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          item.product.finalPrice > 0
                              ? '${item.quantity} x Rs ${item.product.finalPrice.toStringAsFixed(0)} · ${item.product.unit}'
                              : '${item.quantity} x As per Market Rate · ${item.product.unit}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (item.quantity * item.product.finalPrice) > 0
                        ? 'Rs ${(item.quantity * item.product.finalPrice).toStringAsFixed(0)}'
                        : 'As per Market Rate',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0D5C3A)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard(AdminOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment & Total',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          _buildBillRow('Subtotal', 'Rs ${order.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildBillRow('Delivery Fee', 'Rs ${order.deliveryFee.toStringAsFixed(0)}'),
          if (order.discount > 0) ...[
            const SizedBox(height: 6),
            _buildBillRow('Discount', '- Rs ${order.discount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(order.paymentMethod, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Text(
                order.total > 0
                    ? 'Rs ${order.total.toStringAsFixed(0)}'
                    : 'As per Market Rate',
                style: TextStyle(
                  fontSize: order.total > 0 ? 18 : 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D5C3A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  void _openAssignRiderSheet(BuildContext context, AdminProvider admin, String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final fleet = admin.fleet;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign Delivery Partner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text('Select rider from active fleet to dispatch order', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ...fleet.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.electric_moped_rounded, color: Color(0xFF0D5C3A)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(r.vehicle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            admin.assignRiderToOrder(orderId, r.id);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5C3A),
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _confirmCancelOrder(BuildContext context, AdminProvider admin, AdminOrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Are you sure you want to cancel order ${order.orderNumber}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
          ElevatedButton(
            onPressed: () {
              admin.cancelOrder(order.id, 'Cancelled by store manager');
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order ${order.orderNumber} cancelled')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
