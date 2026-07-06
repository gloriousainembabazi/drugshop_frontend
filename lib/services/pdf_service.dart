import 'package:flutter/foundation.dart';
// lib/services/pdf_service.dart - Add font handling at the top

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';

class PdfService {
  static const primaryColor = PdfColors.green700;
  static const secondaryColor = PdfColors.grey600;

  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static bool _fontsLoaded = false;

  // Load custom font for Unicode support with fallback
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;

    try {
      // Try to load custom fonts, fall back to default if not found
      final regularFontData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      _regularFont = pw.Font.ttf(regularFontData);

      try {
        final boldFontData =
            await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
        _boldFont = pw.Font.ttf(boldFontData);
      } catch (e) {
        debugPrint('Bold font loading failed, using regular font: $e');
        _boldFont = _regularFont;
      }

      _fontsLoaded = true;
    } catch (e) {
      debugPrint('Font loading failed, using default fonts: $e');
      _fontsLoaded = true; // Don't try again
    }
  }

  static pw.TextStyle _getTextStyle({
    double fontSize = 12,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? _boldFont : _regularFont,
      fontSize: fontSize,
      color: color,
    );
  }

  // ============================================================
  // SALE RECEIPT PDF GENERATION
  // ============================================================

  static Future<void> generateSaleReceipt(SaleGroup saleGroup) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) => _buildReceiptHeader(saleGroup),
        footer: (pw.Context context) => _buildReceiptFooter(context),
        build: (pw.Context context) => _buildReceiptContent(saleGroup),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'receipt_${saleGroup.saleId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> generateSaleReceiptBytes(SaleGroup saleGroup) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) => _buildReceiptHeader(saleGroup),
        footer: (pw.Context context) => _buildReceiptFooter(context),
        build: (pw.Context context) => _buildReceiptContent(saleGroup),
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildReceiptHeader(SaleGroup saleGroup) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryColor, width: 2),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'His Grace Drugshop',
            style: _getTextStyle(fontSize: 24, bold: true, color: primaryColor),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Your Trusted Drugshop',
            style: _getTextStyle(fontSize: 12, color: secondaryColor),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Tel: +256 750414748 | Email: info@hisgracedrugshop.com',
            style: _getTextStyle(fontSize: 10, color: secondaryColor),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RECEIPT',
                    style: _getTextStyle(
                        fontSize: 18, bold: true, color: primaryColor),
                  ),
                  pw.Text(
                    'Receipt No: ${saleGroup.saleId}',
                    style: _getTextStyle(fontSize: 12, bold: true),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date: ${_formatDate(saleGroup.saleDate)}',
                    style: _getTextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Time: ${_formatTime(saleGroup.saleDate)}',
                    style: _getTextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReceiptFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your purchase!',
            style: _getTextStyle(fontSize: 12, bold: true, color: primaryColor),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'This is a computer generated receipt. No signature required.',
            style: _getTextStyle(fontSize: 8, color: secondaryColor),
          ),
          pw.Text(
            'Page ${context.pageNumber}',
            style: _getTextStyle(fontSize: 8, color: secondaryColor),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildReceiptContent(SaleGroup saleGroup) {
    return [
      // Cashier and Customer Info
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('👤 Cashier:',
                    style: _getTextStyle(fontSize: 10, bold: true)),
                pw.Text(saleGroup.staffName,
                    style: _getTextStyle(fontSize: 10)),
              ],
            ),
            if (saleGroup.customerName.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('👤 Customer:',
                      style: _getTextStyle(fontSize: 10, bold: true)),
                  pw.Text(saleGroup.customerName,
                      style: _getTextStyle(fontSize: 10)),
                ],
              ),
          ],
        ),
      ),

      // Payment Method
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        child: pw.Row(
          children: [
            pw.Text('Payment Method: ',
                style: _getTextStyle(fontSize: 10, bold: true)),
            pw.Text(
              saleGroup.paymentMethod ?? 'Cash',
              style: _getTextStyle(fontSize: 10),
            ),
          ],
        ),
      ),

      pw.Divider(),
      pw.SizedBox(height: 10),

      // Items Header
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey300,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Medicine',
                style: _getTextStyle(fontSize: 11, bold: true),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'Qty',
                textAlign: pw.TextAlign.center,
                style: _getTextStyle(fontSize: 11, bold: true),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Price',
                textAlign: pw.TextAlign.right,
                style: _getTextStyle(fontSize: 11, bold: true),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Total',
                textAlign: pw.TextAlign.right,
                style: _getTextStyle(fontSize: 11, bold: true),
              ),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 5),

      // Items List
      ...saleGroup.items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    item.medicineName,
                    style: _getTextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '${item.quantity}',
                    textAlign: pw.TextAlign.center,
                    style: _getTextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'UGX ${item.unitPrice.toStringAsFixed(0)}',
                    textAlign: pw.TextAlign.right,
                    style: _getTextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'UGX ${item.totalPrice.toStringAsFixed(0)}',
                    textAlign: pw.TextAlign.right,
                    style: _getTextStyle(fontSize: 10, bold: true),
                  ),
                ),
              ],
            ),
          )),

      pw.Divider(),
      pw.SizedBox(height: 10),

      // Summary
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Subtotal: ', style: _getTextStyle(fontSize: 12)),
                    pw.Text(
                      'UGX ${saleGroup.totalAmount.toStringAsFixed(0)}',
                      style: _getTextStyle(fontSize: 12, bold: true),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Tax (0%): ', style: _getTextStyle(fontSize: 11)),
                    pw.Text('UGX 0', style: _getTextStyle(fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Discount: ', style: _getTextStyle(fontSize: 11)),
                    pw.Text('UGX 0', style: _getTextStyle(fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(width: 250, height: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Text(
                      'TOTAL: ',
                      style: _getTextStyle(fontSize: 16, bold: true),
                    ),
                    pw.Text(
                      'UGX ${saleGroup.totalAmount.toStringAsFixed(0)}',
                      style: _getTextStyle(
                          fontSize: 16, bold: true, color: primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 20),

      // Medicine Count Summary
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Text(
                  '${saleGroup.medicineCount}',
                  style: _getTextStyle(
                      fontSize: 16, bold: true, color: primaryColor),
                ),
                pw.Text('Medicine Types', style: _getTextStyle(fontSize: 10)),
              ],
            ),
            pw.Container(width: 1, height: 30, color: PdfColors.grey300),
            pw.Column(
              children: [
                pw.Text(
                  '${saleGroup.totalItems}',
                  style: _getTextStyle(
                      fontSize: 16, bold: true, color: primaryColor),
                ),
                pw.Text('Total Units', style: _getTextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // REPORT PDF GENERATION - FIXED VERSION
  // ============================================================

  static Future<void> generateAndDownload(
      String title, pw.Widget content) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) => _buildReportHeader(title),
        footer: (pw.Context context) => _buildReportFooter(context),
        build: (pw.Context context) => [content],
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            '${title.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildReportHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'His Grace Drugshop Management System',
                style: _getTextStyle(
                    fontSize: 18, bold: true, color: primaryColor),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: _getTextStyle(fontSize: 14, color: secondaryColor),
              ),
            ],
          ),
          pw.Text(
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            style: _getTextStyle(fontSize: 10, color: secondaryColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        'Generated on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} | Page ${context.pageNumber}',
        style: _getTextStyle(fontSize: 8, color: secondaryColor),
      ),
    );
  }

  static pw.Widget buildSalesReportContent(
      Map<String, dynamic> report, List<dynamic> salesData) {
    final summary = report['summary'] ?? {};
    final limitedSales =
        salesData.length > 50 ? salesData.sublist(0, 50) : salesData;

    final List<List<String>> salesRows = [];
    for (var sale in limitedSales) {
      salesRows.add([
        sale['sale_date']?.toString().split('T')[0] ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
        sale['customer_name']?.toString() ?? 'Walk-in',
        sale['medicine_name']?.toString() ?? '',
        '${sale['quantity'] ?? 0}',
        'UGX ${(sale['total_price'] ?? 0).toStringAsFixed(0)}',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            children: [
              pw.Text('📅', style: _getTextStyle(fontSize: 16)),
              pw.SizedBox(width: 10),
              pw.Text(
                'Period: ${report['period']?['start_date'] ?? 'N/A'} - ${report['period']?['end_date'] ?? 'N/A'}',
                style: _getTextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryBox(
                  'Total Revenue',
                  'UGX ${(summary['total_revenue'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.green700),
              _buildSummaryBox('Transactions',
                  '${summary['total_transactions'] ?? 0}', PdfColors.blue700),
              _buildSummaryBox(
                  'Average',
                  'UGX ${(summary['average_transaction'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.orange700),
              _buildSummaryBox(
                  'Max Sale',
                  'UGX ${(summary['max_transaction'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.purple700),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Sales Transactions',
            style: _getTextStyle(fontSize: 16, bold: true)),
        pw.SizedBox(height: 10),
        _buildTable(
          headers: ['Date', 'Customer', 'Medicine', 'Qty', 'Total'],
          rows: salesRows,
        ),
        if (salesData.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Note: Showing last 50 transactions only',
              style: _getTextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  static pw.Widget buildInventoryReportContent(Map<String, dynamic> report) {
    final summary = report['summary'] ?? {};
    final byCategory = report['by_category'] ?? [];
    final lowStockItems = report['low_stock_items'] ?? [];
    final expiredItems = report['expired_items'] ?? [];

    final limitedCategories =
        byCategory.length > 20 ? byCategory.sublist(0, 20) : byCategory;
    final List<List<String>> categoryRows = [];
    for (var category in limitedCategories) {
      categoryRows.add([
        category['category']?.toString() ?? 'Uncategorized',
        '${category['total_items'] ?? 0}',
        'UGX ${(category['total_value'] ?? 0).toStringAsFixed(0)}',
        'UGX ${(category['avg_price'] ?? 0).toStringAsFixed(0)}',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSummaryBox('Total Items',
                  '${summary['total_medicines'] ?? 0}', PdfColors.blue700),
              _buildSummaryBox(
                  'Total Value',
                  'UGX ${(summary['total_value'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.green700),
              _buildSummaryBox('Low Stock', '${summary['low_stock'] ?? 0}',
                  PdfColors.orange700),
              _buildSummaryBox(
                  'Expired', '${summary['expired'] ?? 0}', PdfColors.red700),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Category Breakdown',
            style: _getTextStyle(fontSize: 16, bold: true)),
        pw.SizedBox(height: 10),
        _buildTable(
          headers: ['Category', 'Items', 'Total Value', 'Avg Price'],
          rows: categoryRows,
        ),
        if (lowStockItems.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Low Stock Items',
              style: _getTextStyle(
                  fontSize: 16, bold: true, color: PdfColors.orange700)),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: ['Medicine', 'Batch', 'Current Stock', 'Min Level'],
            rows: lowStockItems
                .take(20)
                .map<Map<String, dynamic>>((item) => item)
                .toList()
                .map((item) => [
                      item['name']?.toString() ?? '',
                      item['batch_number']?.toString() ?? '',
                      '${item['quantity'] ?? 0}',
                      '${item['min_stock_level'] ?? 0}',
                    ])
                .toList(),
          ),
        ],
      ],
    );
  }

  static pw.Widget buildStaffReportContent(Map<String, dynamic> report) {
    final staffSummary = report['staff_summary'] ?? [];

    final List<List<String>> staffRows = [];
    for (int i = 0; i < staffSummary.length; i++) {
      final staff = staffSummary[i];
      staffRows.add([
        '${i + 1}',
        staff['name']?.toString() ?? '',
        staff['role']?.toString() ?? 'Staff',
        'UGX ${(staff['total_sales'] ?? 0).toStringAsFixed(0)}',
        '${staff['transaction_count'] ?? 0}',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Staff Performance Summary',
            style: _getTextStyle(fontSize: 16, bold: true)),
        pw.SizedBox(height: 10),
        _buildTable(
          headers: ['#', 'Staff Name', 'Role', 'Total Sales', 'Transactions'],
          rows: staffRows,
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(
      String title, String value, PdfColor color) {
    PdfColor lightColor;
    if (color == PdfColors.green700) {
      lightColor = PdfColors.green100;
    } else if (color == PdfColors.blue700) {
      lightColor = PdfColors.blue100;
    } else if (color == PdfColors.orange700) {
      lightColor = PdfColors.orange100;
    } else if (color == PdfColors.purple700) {
      lightColor = PdfColors.purple100;
    } else if (color == PdfColors.red700) {
      lightColor = PdfColors.red100;
    } else {
      lightColor = PdfColors.grey100;
    }

    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: _getTextStyle(fontSize: 12, bold: true, color: color),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: _getTextStyle(fontSize: 10, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text('No data available',
            style: _getTextStyle(fontSize: 12, color: PdfColors.grey600)),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: _getTextStyle(fontSize: 10, bold: true),
      cellStyle: _getTextStyle(fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(4),
    );
  }
}
