// lib/screens/reports/inventory_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/report_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  String _selectedTab = 'Overview';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);

    await Future.wait([
      reportProvider.loadInventoryReport(),
      reportProvider.loadLowStockReport(),
      reportProvider.loadExpiredReport(),
      medicineProvider.loadLowStockMedicines(),
      medicineProvider.loadExpiringMedicines(),
      medicineProvider.loadExpiredMedicines(),
      medicineProvider.loadMedicines(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _downloadPDF() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final report = reportProvider.inventoryReport;

    if (report != null) {
      final content = PdfService.buildInventoryReportContent(report);
      await PdfService.generateAndDownload('Inventory Report', content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inventory report downloaded successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<ReportProvider, MedicineProvider>(
        builder: (context, reportProvider, medicineProvider, child) {
          if (_isLoading || reportProvider.isLoading) {
            return const LoadingIndicator();
          }

          final inventory = reportProvider.inventoryReport;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // Tab Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildTabButton('Overview', _selectedTab == 'Overview'),
                      const SizedBox(width: 8),
                      _buildTabButton('Low Stock', _selectedTab == 'Low Stock'),
                      const SizedBox(width: 8),
                      _buildTabButton('Expiring', _selectedTab == 'Expiring'),
                      const SizedBox(width: 8),
                      _buildTabButton('Expired', _selectedTab == 'Expired'),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildTabContent(
                      _selectedTab,
                      inventory,
                      medicineProvider,
                      reportProvider,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    String tab,
    Map<String, dynamic>? inventory,
    MedicineProvider medicineProvider,
    ReportProvider reportProvider,
  ) {
    switch (tab) {
      case 'Overview':
        return _buildOverviewTab(inventory, medicineProvider);
      case 'Low Stock':
        return _buildLowStockTab(reportProvider, medicineProvider);
      case 'Expiring':
        return _buildExpiringTab(reportProvider, medicineProvider);
      case 'Expired':
        return _buildExpiredTab(reportProvider, medicineProvider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab(
      Map<String, dynamic>? inventory, MedicineProvider medicineProvider) {
    if (inventory == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No inventory data available',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final summary = inventory['summary'];

    final totalItems = summary['total_medicines'] ?? 0;
    final totalActiveItems = summary['total_active_medicines'] ?? 0;
    final inStockItems = summary['in_stock'] ?? 0;
    final lowStockItems = summary['low_stock'] ?? 0;
    final outOfStockItems = summary['out_of_stock'] ?? 0;
    final validItems = summary['valid'] ?? 0;
    final expiredItems = summary['expired'] ?? 0;
    final expiringSoon = summary['expiring_soon'] ?? 0;
    final totalValue = (summary['total_value'] ?? 0) as num;
    final totalValueWithExpired =
        (summary['total_value_with_expired'] ?? 0) as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Definitions Card
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Status Definitions',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Total Products: All medicines (including expired)\n'
                '• Active Products: Non-expired medicines only\n'
                '• In Stock: Above minimum level (excludes expired)\n'
                '• Low Stock: At or below minimum level (excludes expired)\n'
                '• Out of Stock: Quantity = 0 (excludes expired)\n'
                '• Valid: Not expired, >30 days remaining\n'
                '• Expired: Past expiry date (not counted in stock)\n'
                '• Expiring Soon: Within 30 days (not counted in stock)',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.blue.shade700),
              ),
            ],
          ),
        ),

        // Summary Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildSummaryCardWithTooltip(
              'Total Products',
              '$totalItems',
              Icons.inventory,
              Colors.blue,
              'All medicines in database (including expired)',
            ),
            _buildSummaryCardWithTooltip(
              'Active Products',
              '$totalActiveItems',
              Icons.verified,
              Colors.teal,
              'Non-expired medicines only',
            ),
            _buildSummaryCardWithTooltip(
              'Total Value',
              'UGX ${totalValue.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
              'Value of active/non-expired stock',
            ),
            _buildSummaryCardWithTooltip(
              'In Stock',
              '$inStockItems',
              Icons.check_circle,
              Colors.green,
              'Active products above minimum level',
            ),
            _buildSummaryCardWithTooltip(
              'Low Stock',
              '$lowStockItems',
              Icons.warning,
              Colors.orange,
              'Active products need reordering',
            ),
            _buildSummaryCardWithTooltip(
              'Out of Stock',
              '$outOfStockItems',
              Icons.dangerous,
              Colors.red,
              'Active products with zero quantity',
            ),
            _buildSummaryCardWithTooltip(
              'Expiring Soon',
              '$expiringSoon',
              Icons.event,
              Colors.orange,
              'Expires within 30 days',
            ),
            _buildSummaryCardWithTooltip(
              'Expired',
              '$expiredItems',
              Icons.cancel,
              Colors.red,
              'Past expiry date (excluded from stock)',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Category Breakdown
        if (inventory['by_category'] != null &&
            inventory['by_category'].isNotEmpty) ...[
          Text(
            'Category Breakdown (Active Products Only)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inventory['by_category'].length,
            itemBuilder: (context, index) {
              final category = inventory['by_category'][index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                  title: Text(
                    category['category'] ?? 'Uncategorized',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      Text('${category['total_items'] ?? 0} active items'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UGX ${((category['total_value'] ?? 0) as num).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      Text(
                        'Avg: UGX ${((category['avg_price'] ?? 0) as num).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCardWithTooltip(
      String title, String value, IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockTab(
      ReportProvider reportProvider, MedicineProvider medicineProvider) {
    final lowStockMedicines = medicineProvider.lowStockMedicines;

    if (lowStockMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text('No low stock items',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('All medicines are above minimum stock levels',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have ${lowStockMedicines.length} medicine(s) that need to be reordered.',
                  style: GoogleFonts.poppins(color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Low Stock Alert (${lowStockMedicines.length} items)',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lowStockMedicines.length,
          itemBuilder: (context, index) {
            final medicine = lowStockMedicines[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.orange.shade50,
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.warning, color: Colors.white)),
                title: Text(medicine.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Batch: ${medicine.batchNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Stock: ${medicine.quantity}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700)),
                    Text('Min: ${medicine.minStockLevel}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                onTap: () => Navigator.pushNamed(context, '/medicine-detail',
                    arguments: {'id': medicine.id}),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpiringTab(
      ReportProvider reportProvider, MedicineProvider medicineProvider) {
    final expiring = medicineProvider.expiringMedicines;

    if (expiring.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text('No expiring medicines',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('All medicines have more than 30 days until expiry',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200)),
          child: Row(
            children: [
              Icon(Icons.event, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      '${expiring.length} medicine(s) will expire within the next 30 days.',
                      style: GoogleFonts.poppins(color: Colors.blue.shade700))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Expiring Soon (${expiring.length} items)',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expiring.length,
          itemBuilder: (context, index) {
            final medicine = expiring[index];
            final daysLeft = medicine.daysUntilExpiry;
            final isUrgent = daysLeft <= 7;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isUrgent ? Colors.red.shade50 : Colors.blue.shade50,
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: isUrgent ? Colors.red : Colors.blue,
                    child: Icon(isUrgent ? Icons.dangerous : Icons.event,
                        color: Colors.white)),
                title: Text(medicine.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Batch: ${medicine.batchNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('yyyy-MM-dd').format(medicine.expiryDate),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color:
                                isUrgent ? Colors.red : Colors.blue.shade700)),
                    Text('$daysLeft days left',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isUrgent
                                ? Colors.red.shade700
                                : Colors.grey.shade600,
                            fontWeight: isUrgent
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ],
                ),
                onTap: () => Navigator.pushNamed(context, '/medicine-detail',
                    arguments: {'id': medicine.id}),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpiredTab(
      ReportProvider reportProvider, MedicineProvider medicineProvider) {
    final expired = medicineProvider.expiredMedicines;

    if (expired.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 80, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text('No expired medicines',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('All medicines are within their expiry date',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200)),
          child: Row(
            children: [
              Icon(Icons.dangerous, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Warning: ${expired.length} medicine(s) have expired and should be removed from inventory.',
                      style: GoogleFonts.poppins(color: Colors.red.shade700))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Expired Medicines (${expired.length} items)',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expired.length,
          itemBuilder: (context, index) {
            final medicine = expired[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.red.shade50,
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.dangerous, color: Colors.white)),
                title: Text(medicine.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700)),
                subtitle: Text('Batch: ${medicine.batchNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        'Expired: ${DateFormat('yyyy-MM-dd').format(medicine.expiryDate)}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.red.shade700)),
                    Text('Qty: ${medicine.quantity}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                onTap: () => Navigator.pushNamed(context, '/medicine-detail',
                    arguments: {'id': medicine.id}),
              ),
            );
          },
        ),
      ],
    );
  }
}
