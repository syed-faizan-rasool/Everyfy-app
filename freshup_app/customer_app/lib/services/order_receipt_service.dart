import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/admin_model.dart';

class OrderReceiptService {
  OrderReceiptService._();

  /// Generates the raw PDF bytes for an order dispatch slip.
  static Future<Uint8List> generateReceiptPdf(
    AdminOrderModel order,
    StoreSettingsModel storeSettings, {
    PdfPageFormat format = PdfPageFormat.roll80,
  }) async {
    final doc = pw.Document();

    // Use default font or fallback font
    final fontBold = await PdfGoogleFonts.interBold();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontMedium = await PdfGoogleFonts.interMedium();

    final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final orderTime = dateTimeFormat.format(order.createdAt);
    final printTime = dateTimeFormat.format(DateTime.now());

    final primaryColor = PdfColor.fromHex('#0D5C3A');
    final accentColor = PdfColor.fromHex('#F58220');
    final darkText = PdfColor.fromHex('#0F172A');
    final mutedText = PdfColor.fromHex('#475569');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final alertBg = PdfColor.fromHex('#FFFBEB');
    final alertBorder = PdfColor.fromHex('#F59E0B');


    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ================= BRAND HEADER =================
              pw.Center(
                child: pw.Column(
                  children: [
                    // Brand Badge / Logo
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            'EVERY',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: PdfColors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.Text(
                            'FY',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: accentColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      storeSettings.storeName,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: darkText,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      storeSettings.storeAddress,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.5,
                        color: mutedText,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Helpline: ${storeSettings.supportPhone}',
                      style: pw.TextStyle(
                        font: fontMedium,
                        fontSize: 8.5,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed, color: PdfColors.grey600),
              pw.SizedBox(height: 4),

              // ================= SLIP TITLE & META =================
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: lightBg,
                    border: pw.Border.all(color: primaryColor, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    '*** RIDER DISPATCH SLIP ***',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 8),

              // Order ID & Timestamps
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ORDER NUMBER',
                        style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: mutedText),
                      ),
                      pw.Text(
                        order.orderNumber,
                        style: pw.TextStyle(font: fontBold, fontSize: 13, color: darkText),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Placed: $orderTime', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: mutedText)),
                      pw.Text('Printed: $printTime', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: mutedText)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.8, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // ================= CUSTOMER & DESTINATION =================
              pw.Text(
                'CUSTOMER & DELIVERY DETAILS',
                style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: darkText, letterSpacing: 0.5),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            order.customerName,
                            style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText),
                          ),
                        ),
                        pw.Text(
                          order.customerPhone,
                          style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Address:',
                      style: pw.TextStyle(font: fontMedium, fontSize: 7.5, color: mutedText),
                    ),
                    pw.Text(
                      order.address,
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: darkText),
                    ),
                  ],
                ),
              ),

              // ================= CUSTOMER SPECIAL NOTE =================
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(7),
                decoration: pw.BoxDecoration(
                  color: alertBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: alertBorder, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CUSTOMER NOTE / INSTRUCTIONS:',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: alertBorder,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      (order.customerNotes != null && order.customerNotes!.trim().isNotEmpty)
                          ? '"${order.customerNotes!.trim()}"'
                          : 'No special instructions provided.',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),

              // ================= ASSIGNED RIDER INFO =================
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Assigned Rider: ${order.assignedRiderName ?? 'Not Assigned Yet'}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: darkText),
                  ),
                  if (order.assignedRiderPhone != null)
                    pw.Text(
                      'Tel: ${order.assignedRiderPhone}',
                      style: pw.TextStyle(font: fontMedium, fontSize: 8, color: mutedText),
                    ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed, color: PdfColors.grey600),
              pw.SizedBox(height: 6),

              // ================= ITEM CHECKLIST =================
              pw.Row(
                children: [
                  pw.SizedBox(width: 14, child: pw.Text('[V]', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
                  pw.Expanded(child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.SizedBox(width: 32, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 8))),
                  pw.SizedBox(width: 48, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 8))),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              ...order.items.map((item) {
                final itemTotal = item.quantity * item.product.finalPrice;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 14,
                        child: pw.Text('[ ]', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: mutedText)),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.product.name,
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: darkText),
                            ),
                            pw.Text(
                              'Rs ${item.product.finalPrice.toStringAsFixed(0)} / ${item.product.unit}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7, color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(
                        width: 32,
                        child: pw.Text(
                          '${item.quantity}x',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: darkText),
                        ),
                      ),
                      pw.SizedBox(
                        width: 48,
                        child: pw.Text(
                          'Rs ${itemTotal.toStringAsFixed(0)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: darkText),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.8, color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              // ================= BILL BREAKDOWN =================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal (${order.items.length} items)', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: mutedText)),
                  pw.Text('Rs ${order.subtotal.toStringAsFixed(0)}', style: pw.TextStyle(font: fontMedium, fontSize: 8, color: darkText)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Delivery Charges', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: mutedText)),
                  pw.Text('Rs ${order.deliveryFee.toStringAsFixed(0)}', style: pw.TextStyle(font: fontMedium, fontSize: 8, color: darkText)),
                ],
              ),
              if (order.discount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount Voucher', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: primaryColor)),
                    pw.Text('- Rs ${order.discount.toStringAsFixed(0)}', style: pw.TextStyle(font: fontMedium, fontSize: 8, color: primaryColor)),
                  ],
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: darkText),
              pw.SizedBox(height: 3),

              // TOTAL ROW
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NET PAYABLE:',
                    style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkText),
                  ),
                  pw.Text(
                    'Rs ${order.total.toStringAsFixed(0)}',
                    style: pw.TextStyle(font: fontBold, fontSize: 13, color: primaryColor),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ================= BARCODE =================
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 34,
                      width: 170,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: order.orderNumber,
                        drawText: false,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      order.orderNumber,
                      style: pw.TextStyle(font: fontMedium, fontSize: 8, color: darkText, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed, color: PdfColors.grey600),
              pw.SizedBox(height: 6),

              // ================= SIGNATURE & HANDOVER =================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Store Packer: ____________', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: mutedText)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Rider Sign: ____________', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: mutedText)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ================= FOOTER NOTE =================
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for delivering with Everyfy!',
                      style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: darkText),
                    ),
                    pw.Text(
                      'Report delivery issues to dispatch hub immediately.',
                      style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Directly sends to printer using device native print manager
  static Future<void> printOrderSlip(
    BuildContext context,
    AdminOrderModel order,
    StoreSettingsModel storeSettings,
  ) async {
    try {
      await Printing.layoutPdf(
        name: 'Rider_Slip_${order.orderNumber}.pdf',
        format: PdfPageFormat.roll80,
        onLayout: (PdfPageFormat format) async {
          return await generateReceiptPdf(order, storeSettings, format: format);
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open print dialog: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Shares the generated receipt PDF through the device share sheet
  static Future<void> shareReceipt(
    BuildContext context,
    AdminOrderModel order,
    StoreSettingsModel storeSettings,
  ) async {
    try {
      final pdfBytes = await generateReceiptPdf(order, storeSettings);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Rider_Slip_${order.orderNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing slip: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
