// lib/screens/reports/sales_report_screen.dart - Full corrected code

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/sale_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/loading_indicator.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Last 30 Days';
  bool _isLoading = false;
  List<Map<String, dynamic>> _cashSalesHistory = [];
  List<Map<String, dynamic>> _creditSalesHistory = [];
  double _totalCashSales = 0;
  double _totalCreditSales = 0;
  double _totalCreditCollected = 0;
  String? _errorMessage;

  final List<String> _periods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final saleProvider = Provider.of<SaleProvider>(context, listen: false);
      final creditProvider =
          Provider.of<CreditProvider>(context, listen: false);

      await Future.wait([
        saleProvider.loadSales(refresh: true),
        creditProvider.loadCreditSales(),
      ]);

      final startDateTime = _startOfDay(_startDate);
      final endDateTime = _endOfDay(_endDate);

      final allSales = saleProvider.sales;
      final filteredSales = allSales.where((s) {
        final saleDate = s.saleDate;
        return saleDate
                .isAfter(startDateTime.subtract(const Duration(seconds: 1))) &&
            saleDate.isBefore(endDateTime.add(const Duration(seconds: 1)));
      }).toList();

      final allCreditSales = creditProvider.creditSales;

      final filteredCreditSales = allCreditSales.where((credit) {
        return credit.createdAt
                .isAfter(startDateTime.subtract(const Duration(seconds: 1))) &&
            credit.createdAt
                .isBefore(endDateTime.add(const Duration(seconds: 1)));
      }).toList();

      double cashTotal = 0;
      for (var sale in filteredSales) {
        cashTotal += sale.totalPrice;
      }

      double creditTotal = 0;
      double creditCollected = 0;

      List<Map<String, dynamic>> creditHistory = [];

      for (var credit in filteredCreditSales) {
        creditTotal += credit.totalAmount;
        creditCollected += credit.amountPaid;

        final items = credit.items;
        if (items.isNotEmpty) {
          for (var item in items) {
            creditHistory.add({
              'sale_date': credit.createdAt,
              'due_date': credit.dueDate,
              'customer_name': credit.customerName,
              'credit_id': credit.creditId,
              'medicine_name': item.medicineName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              'amount_paid': credit.amountPaid,
              'balance': credit.balance,
              'status': credit.status,
              'type': 'Credit',
            });
          }
        } else {
          creditHistory.add({
            'sale_date': credit.createdAt,
            'due_date': credit.dueDate,
            'customer_name': credit.customerName,
            'credit_id': credit.creditId,
            'medicine_name': 'Multiple Items',
            'quantity': 0,
            'unit_price': 0,
            'total_price': credit.totalAmount,
            'amount_paid': credit.amountPaid,
            'balance': credit.balance,
            'status': credit.status,
            'type': 'Credit',
          });
        }
      }

      List<Map<String, dynamic>> cashHistory = filteredSales
          .map((s) => {
                'sale_date': s.saleDate,
                'customer_name': s.customerName ?? 'Walk-in',
                'medicine_name': s.medicineName,
                'quantity': s.quantity,
                'total_price': s.totalPrice,
                'type': 'Cash',
              })
          .toList();

      if (mounted) {
        setState(() {
          _cashSalesHistory = cashHistory;
          _creditSalesHistory = creditHistory;
          _totalCashSales = cashTotal;
          _totalCreditSales = creditTotal;
          _totalCreditCollected = creditCollected;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ERROR LOADING REPORT: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load sales data: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PDF DOWNLOAD METHOD
  // ============================================================

  Future<void> _downloadPDF() async {
    debugPrint('🟢 DOWNLOAD PDF BUTTON TAPPED');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF... Please wait')),
      );

      final totalRevenue = _totalCashSales + _totalCreditSales;
      final totalTransactions =
          _cashSalesHistory.length + _creditSalesHistory.length;
      final averageTransaction =
          totalTransactions > 0 ? totalRevenue / totalTransactions : 0;
      final maxTransaction = _cashSalesHistory.isNotEmpty
          ? _cashSalesHistory
              .map((s) => s['total_price'] ?? 0.0)
              .reduce((a, b) => a > b ? a : b)
          : 0.0;

      final reportData = {
        'summary': {
          'total_revenue': totalRevenue,
          'total_transactions': totalTransactions,
          'average_transaction': averageTransaction,
          'max_transaction': maxTransaction,
        },
        'period': {
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
          'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
        }
      };

      final salesForPdf = _cashSalesHistory
          .map((sale) => {
                'sale_date': sale['sale_date'],
                'customer_name': sale['customer_name'],
                'medicine_name': sale['medicine_name'],
                'quantity': sale['quantity'],
                'total_price': sale['total_price'],
              })
          .toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          margin: const pw.EdgeInsets.all(30),
          header: (pw.Context context) => _buildPdfHeader(),
          footer: (pw.Context context) => _buildPdfFooter(context),
          build: (pw.Context context) =>
              [_buildPdfContent(reportData, salesForPdf)],
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sales report downloaded successfully')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _downloadPDF: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green700, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'His Grace Drugshop',
            style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Sales Report',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Period: ${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
          pw.Text(
            'Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        'Page ${context.pageNumber}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _buildPdfContent(
      Map<String, dynamic> report, List<dynamic> salesData) {
    final summary = report['summary'] ?? {};
    final limitedSales =
        salesData.length > 50 ? salesData.sublist(0, 50) : salesData;

    final List<List<String>> salesRows = [];
    for (var sale in limitedSales) {
      DateTime? saleDate = sale['sale_date'];
      String formattedDate = '';
      if (saleDate != null) {
        formattedDate = DateFormat('yyyy-MM-dd').format(saleDate);
      } else {
        formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }

      salesRows.add([
        formattedDate,
        sale['customer_name']?.toString() ?? 'Walk-in',
        sale['medicine_name']?.toString() ?? '',
        '${sale['quantity'] ?? 0}',
        'UGX ${(sale['total_price'] ?? 0.0).toStringAsFixed(0)}',
      ]);
    }

    final outstandingCredit = _totalCreditSales - _totalCreditCollected;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfSummaryBox(
                  'Total Revenue',
                  'UGX ${(summary['total_revenue'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.green700),
              _buildPdfSummaryBox('Transactions',
                  '${summary['total_transactions'] ?? 0}', PdfColors.blue700),
              _buildPdfSummaryBox(
                  'Average',
                  'UGX ${(summary['average_transaction'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.orange700),
              _buildPdfSummaryBox(
                  'Max Sale',
                  'UGX ${(summary['max_transaction'] ?? 0).toStringAsFixed(0)}',
                  PdfColors.purple700),
            ],
          ),
        ),
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
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
                  pw.Text('Cash Sales',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('UGX ${_totalCashSales.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700)),
                ],
              ),
              pw.Container(width: 1, height: 30, color: PdfColors.grey300),
              pw.Column(
                children: [
                  pw.Text('Credit Sales',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('UGX ${_totalCreditSales.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange700)),
                ],
              ),
              pw.Container(width: 1, height: 30, color: PdfColors.grey300),
              pw.Column(
                children: [
                  pw.Text('Credit Collected',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('UGX ${_totalCreditCollected.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700)),
                ],
              ),
              pw.Container(width: 1, height: 30, color: PdfColors.grey300),
              pw.Column(
                children: [
                  pw.Text('Outstanding',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('UGX ${outstandingCredit.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Cash Sales Transactions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _buildPdfTable(
          headers: ['Date', 'Customer', 'Medicine', 'Qty', 'Total'],
          rows: salesRows,
        ),
        if (salesData.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Note: Showing last 50 transactions only',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        if (_creditSalesHistory.isNotEmpty) ...[
          pw.SizedBox(height: 30),
          pw.Text('Credit Sales Summary',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(
              'Total Credit Invoices: ${_creditSalesHistory.map((c) => c['credit_id']).toSet().length}',
              style: pw.TextStyle(fontSize: 11)),
          pw.Text(
              'Total Credit Amount: UGX ${_totalCreditSales.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 11)),
          pw.Text(
              'Total Collected: UGX ${_totalCreditCollected.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 11)),
          pw.Text(
              'Outstanding Balance: UGX ${(_totalCreditSales - _totalCreditCollected).toStringAsFixed(0)}',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700)),
        ],
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(
            'Thank you for choosing His Grace Drugshop',
            style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryBox(String title, String value, PdfColor color) {
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
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: lightColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: color),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text('No data available',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(4),
    );
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Yesterday':
          _startDate = DateTime(now.year, now.month, now.day - 1);
          _endDate = DateTime(now.year, now.month, now.day - 1);
          break;
        case 'Last 7 Days':
          _startDate = DateTime(now.year, now.month, now.day - 6);
          _endDate = now;
          break;
        case 'Last 30 Days':
          _startDate = DateTime(now.year, now.month, now.day - 29);
          _endDate = now;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'Custom Range':
          break;
      }
    });
    if (period != 'Custom Range') {
      _loadReport();
    }
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom Range';
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _downloadPDF,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: GoogleFonts.poppins(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReport, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_cashSalesHistory.isEmpty && _creditSalesHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No sales data found for this period',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 16),
            if (_creditSalesHistory.isNotEmpty) _buildCreditSalesSection(),
            if (_creditSalesHistory.isNotEmpty && _cashSalesHistory.isNotEmpty)
              const SizedBox(height: 16),
            if (_cashSalesHistory.isNotEmpty) _buildCashSalesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Period',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _periods.map((period) {
              return FilterChip(
                label: Text(period, style: const TextStyle(fontSize: 12)),
                selected: _selectedPeriod == period,
                onSelected: (value) {
                  if (period == 'Custom Range') {
                    _selectCustomRange();
                  } else {
                    _updateDateRange(period);
                  }
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.green.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _totalCashSales + _totalCreditSales;
    final outstandingCredit = _totalCreditSales - _totalCreditCollected;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildSummaryCard(
            'Cash Sales',
            'UGX ${_totalCashSales.toStringAsFixed(0)}',
            Icons.money,
            Colors.green),
        _buildSummaryCard(
            'Credit Sales',
            'UGX ${_totalCreditSales.toStringAsFixed(0)}',
            Icons.credit_card,
            Colors.orange),
        _buildSummaryCard(
            'Credit Collected',
            'UGX ${_totalCreditCollected.toStringAsFixed(0)}',
            Icons.payment,
            Colors.blue),
        _buildSummaryCard(
            'Outstanding',
            'UGX ${outstandingCredit.toStringAsFixed(0)}',
            Icons.warning,
            Colors.red),
        _buildSummaryCard(
            'Total Revenue',
            'UGX ${totalRevenue.toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.purple),
        _buildSummaryCard(
            'Transactions',
            '${_cashSalesHistory.length + _creditSalesHistory.length}',
            Icons.receipt,
            Colors.teal),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCreditSalesSection() {
    final Map<String, Map<String, dynamic>> groupedCredits = {};

    for (var sale in _creditSalesHistory) {
      final creditId = sale['credit_id']?.toString() ?? '';
      if (creditId.isEmpty) continue;

      if (!groupedCredits.containsKey(creditId)) {
        groupedCredits[creditId] = {
          'credit_id': creditId,
          'customer_name': sale['customer_name'] ?? 'Unknown',
          'due_date': sale['due_date'],
          'total_amount': 0.0,
          'amount_paid': sale['amount_paid'] ?? 0.0,
          'balance': 0.0,
          'status': sale['status'] ?? 'pending',
          'items': [],
        };
      }
      groupedCredits[creditId]!['total_amount'] += (sale['total_price'] ?? 0.0);
      groupedCredits[creditId]!['balance'] =
          groupedCredits[creditId]!['total_amount'] -
              groupedCredits[creditId]!['amount_paid'];
      (groupedCredits[creditId]!['items'] as List).add(sale);
    }

    final creditSummaries = groupedCredits.values.toList();

    if (creditSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Credit Sales (${creditSummaries.length} invoices)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: creditSummaries.length,
          itemBuilder: (context, index) {
            final credit = creditSummaries[index];
            final isPaid = credit['status'] == 'paid';
            dynamic dueDateValue = credit['due_date'];
            String dueDateStr = 'N/A';

            if (dueDateValue is DateTime) {
              dueDateStr = DateFormat('yyyy-MM-dd').format(dueDateValue);
            } else if (dueDateValue != null) {
              dueDateStr = dueDateValue.toString();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(credit['credit_id'] ?? ''),
                subtitle: Text(credit['customer_name'] ?? ''),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'UGX ${(credit['balance'] ?? 0.0).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text(
                      'Due: $dueDateStr',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ...(credit['items'] as List)
                            .map<Widget>((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            '${item['quantity'] ?? 0}x ${item['medicine_name'] ?? ''}'),
                                      ),
                                      Text(
                                          'UGX ${(item['total_price'] ?? 0.0).toStringAsFixed(0)}'),
                                    ],
                                  ),
                                )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'UGX ${(credit['total_amount'] ?? 0.0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paid:'),
                            Text(
                                'UGX ${(credit['amount_paid'] ?? 0.0).toStringAsFixed(0)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Balance:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'UGX ${(credit['balance'] ?? 0.0).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (credit['status'] ?? 'pending')
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              color: isPaid ? Colors.green : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCashSalesSection() {
    if (_cashSalesHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cash Sales Transactions (${_cashSalesHistory.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontSize: 11))),
                DataColumn(
                    label: Text('Customer', style: TextStyle(fontSize: 11))),
                DataColumn(
                    label: Text('Medicine', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('Qty', style: TextStyle(fontSize: 11))),
                DataColumn(
                    label: Text('Total', style: TextStyle(fontSize: 11))),
              ],
              rows: _cashSalesHistory.take(20).map((sale) {
                DateTime? saleDate = sale['sale_date'];
                String formattedDate = '';
                if (saleDate != null) {
                  formattedDate = DateFormat('yyyy-MM-dd').format(saleDate);
                } else {
                  formattedDate = 'N/A';
                }

                return DataRow(cells: [
                  DataCell(Text(formattedDate,
                      style: const TextStyle(fontSize: 11))),
                  DataCell(Text(sale['customer_name'] ?? 'Walk-in',
                      style: const TextStyle(fontSize: 11))),
                  DataCell(Text(sale['medicine_name'] ?? '',
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
                  DataCell(Text('${sale['quantity'] ?? 0}',
                      style: const TextStyle(fontSize: 11))),
                  DataCell(Text(
                      'UGX ${(sale['total_price'] ?? 0.0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11))),
                ]);
              }).toList(),
            ),
          ),
        ),
        if (_cashSalesHistory.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                'Showing last 20 of ${_cashSalesHistory.length} transactions',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ),
      ],
    );
  }
}
