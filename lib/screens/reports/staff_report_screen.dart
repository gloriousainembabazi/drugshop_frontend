// lib/screens/reports/staff_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/report_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/loading_indicator.dart';

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({super.key});

  @override
  State<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends State<StaffReportScreen> {
  DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 30),
  );

  DateTime _endDate = DateTime.now();

  String _selectedPeriod = 'Last 30 Days';

  bool _isLoading = false;

  final List<Map<String, dynamic>> _staffMetrics = [];

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

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    final reportProvider = Provider.of<ReportProvider>(
      context,
      listen: false,
    );

    await reportProvider.loadStaffReport();

    _calculateStaffMetrics(reportProvider);

    setState(() => _isLoading = false);
  }

  void _calculateStaffMetrics(
    ReportProvider reportProvider,
  ) {
    _staffMetrics.clear();

    final report = reportProvider.staffReport;

    if (report == null) return;

    final List<dynamic> staffList = report['staff_summary'] ?? [];

    debugPrint(
      '📊 STAFF REPORT COUNT: ${staffList.length}',
    );

    for (var staff in staffList) {
      final cashSales = (staff['total_cash_sales'] ?? 0).toDouble();

      final creditSales = (staff['total_credit_sales'] ?? 0).toDouble();

      final totalSales = (staff['total_sales'] ?? 0).toDouble();

      final expenses = (staff['total_expenses'] ?? 0).toDouble();

      final netContribution = (staff['net_contribution'] ?? 0).toDouble();

      _staffMetrics.add({
        'staff_id': staff['staff_id'],
        'name': staff['name'] ?? 'Unknown',
        'role': staff['role'] ?? 'staff',

        // SALES
        'cash_sales': cashSales,
        'credit_sales': creditSales,
        'credit_collected': (staff['total_credit_collected'] ?? 0).toDouble(),
        'total_sales': totalSales,

        // COUNTS
        'transactions': staff['transaction_count'] ?? 0,

        'credit_count': staff['credit_count'] ?? 0,

        // PERFORMANCE
        'avg_transaction': (staff['avg_transaction'] ?? 0).toDouble(),

        'unique_medicines': staff['unique_medicines'] ?? 0,

        // EXPENSES
        'expenses': expenses,

        'expense_count': staff['expense_count'] ?? 0,

        // PRESCRIPTIONS
        'prescriptions': staff['prescription_count'] ?? 0,

        // NET
        'net_profit': netContribution,
      });

      debugPrint(
        '📊 ${staff['name']} | Cash=$cashSales | Credit=$creditSales | Expenses=$expenses',
      );
    }

    _staffMetrics.sort(
      (a, b) => (b['net_profit'] as double).compareTo(
        a['net_profit'] as double,
      ),
    );
  }

  Future<void> _downloadPDF() async {
    final reportProvider = Provider.of<ReportProvider>(
      context,
      listen: false,
    );

    final report = reportProvider.staffReport;

    if (report != null) {
      final content = PdfService.buildStaffReportContent(
        report,
      );

      await PdfService.generateAndDownload(
        'Staff Performance Report',
        content,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Staff report downloaded successfully',
            ),
          ),
        );
      }
    }
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();

    setState(() {
      _selectedPeriod = period;

      switch (period) {
        case 'Today':
          _startDate = DateTime(
            now.year,
            now.month,
            now.day,
          );

          _endDate = now;
          break;

        case 'Yesterday':
          _startDate = DateTime(
            now.year,
            now.month,
            now.day - 1,
          );

          _endDate = DateTime(
            now.year,
            now.month,
            now.day - 1,
          );
          break;

        case 'Last 7 Days':
          _startDate = now.subtract(
            const Duration(days: 6),
          );

          _endDate = now;
          break;

        case 'Last 30 Days':
          _startDate = now.subtract(
            const Duration(days: 29),
          );

          _endDate = now;
          break;

        case 'This Month':
          _startDate = DateTime(
            now.year,
            now.month,
            1,
          );

          _endDate = now;
          break;

        case 'Last Month':
          _startDate = DateTime(
            now.year,
            now.month - 1,
            1,
          );

          _endDate = DateTime(
            now.year,
            now.month,
            0,
          );
          break;
      }
    });

    _loadReport();
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
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

  String _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return '👑';

      case 'manager':
        return '📊';

      case 'pharmacist':
        return '💊';

      case 'cashier':
        return '💰';

      default:
        return '👤';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Staff Performance Report',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
            onPressed: _downloadPDF,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(
                      height: 16,
                    ),
                    if (_staffMetrics.isEmpty) _buildEmptyState(),
                    if (_staffMetrics.isNotEmpty) ..._buildStaffCards(),
                  ],
                ),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Period',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((period) {
                return Padding(
                  padding: const EdgeInsets.only(
                    right: 6,
                  ),
                  child: FilterChip(
                    label: Text(
                      period,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    selected: _selectedPeriod == period,
                    onSelected: (value) {
                      if (period == 'Custom Range') {
                        _selectCustomRange();
                      } else {
                        _updateDateRange(
                          period,
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                '${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No staff data available for this period',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStaffCards() {
    final List<Widget> cards = [];

    for (int i = 0; i < _staffMetrics.length; i++) {
      cards.add(
        _buildStaffCard(
          _staffMetrics[i],
          i + 1,
        ),
      );

      if (i != _staffMetrics.length - 1) {
        cards.add(
          const SizedBox(height: 12),
        );
      }
    }

    return cards;
  }

  Widget _buildStaffCard(
    Map<String, dynamic> staff,
    int rank,
  ) {
    final cashSales = staff['cash_sales'] as double;

    final creditSales = staff['credit_sales'] as double;

    final totalSales = staff['total_sales'] as double;

    final expenses = staff['expenses'] as double;

    final netProfit = staff['net_profit'] as double;

    final topSales = _staffMetrics.isNotEmpty
        ? (_staffMetrics[0]['total_sales'] as double)
        : 1;

    final performancePercent = topSales > 0 ? (totalSales / topSales) * 100 : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    _getRoleIcon(
                      staff['role'],
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        staff['role'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'UGX ${netProfit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  'Cash Sales',
                  'UGX ${cashSales.toStringAsFixed(0)}',
                  Icons.money,
                  Colors.green,
                ),
                _buildStatChip(
                  'Credit Sales',
                  'UGX ${creditSales.toStringAsFixed(0)}',
                  Icons.credit_card,
                  Colors.orange,
                ),
                _buildStatChip(
                  'Total Sales',
                  'UGX ${totalSales.toStringAsFixed(0)}',
                  Icons.bar_chart,
                  Colors.blue,
                ),
                _buildStatChip(
                  'Expenses',
                  'UGX ${expenses.toStringAsFixed(0)}',
                  Icons.receipt_long,
                  Colors.red,
                ),
                _buildStatChip(
                  'Transactions',
                  '${staff['transactions']}',
                  Icons.receipt,
                  Colors.purple,
                ),
                _buildStatChip(
                  'Credit Count',
                  '${staff['credit_count']}',
                  Icons.credit_card,
                  Colors.orange,
                ),
                _buildStatChip(
                  'Prescriptions',
                  '${staff['prescriptions']}',
                  Icons.description,
                  Colors.teal,
                ),
                _buildStatChip(
                  'Performance',
                  '${performancePercent.toStringAsFixed(0)}%',
                  Icons.analytics,
                  Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
