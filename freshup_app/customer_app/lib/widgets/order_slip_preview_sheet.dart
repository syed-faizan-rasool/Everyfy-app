import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/admin_model.dart';
import '../services/order_receipt_service.dart';

class OrderSlipPreviewSheet extends StatelessWidget {
  final AdminOrderModel order;
  final StoreSettingsModel storeSettings;

  const OrderSlipPreviewSheet({
    super.key,
    required this.order,
    required this.storeSettings,
  });

  static void show(BuildContext context, AdminOrderModel order, StoreSettingsModel storeSettings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderSlipPreviewSheet(
        order: order,
        storeSettings: storeSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy · hh:mm a').format(order.createdAt);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5C3A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0D5C3A), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rider Order Slip (${order.orderNumber})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Ready for Rider Handover & Dispatch',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Receipt Paper Preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D5C3A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'FRESH',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'CART',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFFF58220),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              storeSettings.storeName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              storeSettings.storeAddress,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Helpline: ${storeSettings.supportPhone}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      _buildDashedDivider(),
                      const SizedBox(height: 8),

                      // Slip Banner
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0D5C3A), width: 0.8),
                          ),
                          child: const Text(
                            '*** RIDER DISPATCH SLIP ***',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D5C3A),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Order Metadata
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ORDER ID', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text(
                                order.orderNumber,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Text(
                            'Placed: $formattedDate',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),

                      // Customer Details
                      const Text(
                        'CUSTOMER & DESTINATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  order.customerPhone,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D5C3A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.address,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                            ),
                          ],
                        ),
                      ),

                      // Customer Special Instructions Note
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.note_alt_rounded, size: 18, color: Color(0xFFB45309)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CUSTOMER NOTE / INSTRUCTIONS:',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (order.customerNotes != null && order.customerNotes!.trim().isNotEmpty)
                                        ? '"${order.customerNotes!.trim()}"'
                                        : 'No special customer notes provided.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF78350F),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Assigned Rider
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining_rounded, size: 16, color: Color(0xFF0D5C3A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rider: ${order.assignedRiderName ?? "Pending Assignment"} ${order.assignedRiderPhone != null ? "(${order.assignedRiderPhone})" : ""}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _buildDashedDivider(),
                      const SizedBox(height: 10),

                      // Item Checklist
                      const Row(
                        children: [
                          SizedBox(width: 22, child: Text('[V]', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                          Expanded(child: Text('ITEM DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                          SizedBox(width: 36, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                          SizedBox(width: 60, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                        ],
                      ),
                      const Divider(height: 12, color: Color(0xFFE2E8F0)),

                      ...order.items.map((item) {
                        final itemTotal = item.quantity * item.product.finalPrice;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 22,
                                child: Icon(Icons.check_box_outline_blank_rounded, size: 15, color: Color(0xFF94A3B8)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      'Rs ${item.product.finalPrice.toStringAsFixed(0)} / ${item.product.unit}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${item.quantity}x',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'Rs ${itemTotal.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D5C3A)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const Divider(height: 16, color: Color(0xFFE2E8F0)),

                      // Bill Summary
                      _buildSummaryRow('Subtotal (${order.items.length} items)', 'Rs ${order.subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 4),
                      _buildSummaryRow('Delivery Fee', 'Rs ${order.deliveryFee.toStringAsFixed(0)}'),
                      if (order.discount > 0) ...[
                        const SizedBox(height: 4),
                        _buildSummaryRow('Discount Voucher', '- Rs ${order.discount.toStringAsFixed(0)}', isDiscount: true),
                      ],
                      const Divider(height: 14, color: Color(0xFF0F172A)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NET AMOUNT:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Rs ${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0D5C3A)),
                          ),
                        ],
                      ),


                      const SizedBox(height: 14),
                      _buildDashedDivider(),
                      const SizedBox(height: 12),

                      // Signatures
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Packer: ____________', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Rider Sign: ____________', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          'Thank you for delivering with FreshCart!',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text('Print Preview - ${order.orderNumber}'),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            body: PdfPreview(
                              build: (format) => OrderReceiptService.generateReceiptPdf(
                                order,
                                storeSettings,
                                format: format,
                              ),
                              canChangePageFormat: false,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('PDF Preview', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => OrderReceiptService.printOrderSlip(context, order, storeSettings),
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: const Text('Print Rider Slip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5C3A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String val, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(
          val,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  static Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.constrainWidth() / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const SizedBox(
              width: 4,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF94A3B8))),
            ),
          ),
        );
      },
    );
  }
}
