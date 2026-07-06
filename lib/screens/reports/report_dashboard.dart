import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/report_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/loading_indicator.dart';

class ReportDashboard extends StatefulWidget {
  const ReportDashboard({super.key});

  @override
  _ReportDashboardState createState() => _ReportDashboardState();
}

class _ReportDashboardState extends State<ReportDashboard> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);

    await Future.wait([
      reportProvider.loadDashboardSummary(),
      reportProvider.loadDailySalesReport(),
      reportProvider.loadLowStockReport(),
      reportProvider.loadExpiredReport(),
      medicineProvider.loadLowStockMedicines(),
      medicineProvider.loadExpiringMedicines(),
      medicineProvider.loadExpiredMedicines(),
      saleProvider.loadDailySales(),
    ]);
  }

  void _navigateToLowStock(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlertDetailScreen(
          title: 'Low Stock Medicines',
          alertType: AlertType.lowStock,
        ),
      ),
    );
  }

  void _navigateToExpiring(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlertDetailScreen(
          title: 'Expiring Soon',
          alertType: AlertType.expiring,
        ),
      ),
    );
  }

  void _navigateToExpired(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlertDetailScreen(
          title: 'Expired Medicines',
          alertType: AlertType.expired,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: Consumer3<ReportProvider, MedicineProvider, SaleProvider>(
          builder:
              (context, reportProvider, medicineProvider, saleProvider, child) {
            if (reportProvider.isLoading) {
              return const LoadingIndicator();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Text(
                    'Quick Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        'Total Medicines',
                        '${medicineProvider.medicines.length}',
                        Icons.medical_services,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Low Stock',
                        '${medicineProvider.lowStockMedicines.length}',
                        Icons.warning,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Today\'s Sales',
                        'UGX ${saleProvider.dailyTotal.toStringAsFixed(0)}',
                        Icons.today,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Expired',
                        '${medicineProvider.expiredMedicines.length}',
                        Icons.dangerous,
                        Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Report Categories
                  Text(
                    'Report Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildReportCard(
                    'Sales Report',
                    'View daily and monthly sales with detailed analytics',
                    Icons.show_chart,
                    Colors.green,
                    () {
                      Navigator.pushNamed(context, '/sales-report');
                    },
                  ),

                  _buildReportCard(
                    'Inventory Report',
                    'Check stock levels, expiring medicines, and inventory value',
                    Icons.inventory,
                    Colors.blue,
                    () {
                      Navigator.pushNamed(context, '/inventory-report');
                    },
                  ),

                  _buildReportCard(
                    'Staff Performance',
                    'Monitor staff sales activity and performance metrics',
                    Icons.people,
                    Colors.purple,
                    () {
                      Navigator.pushNamed(context, '/staff-report');
                    },
                  ),

                  const SizedBox(height: 16),

                  // Alerts Section
                  if (medicineProvider.lowStockMedicines.isNotEmpty ||
                      medicineProvider.expiringMedicines.isNotEmpty ||
                      medicineProvider.expiredMedicines.isNotEmpty) ...[
                    Text(
                      'Alerts & Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (medicineProvider.lowStockMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Low Stock Alert',
                        '${medicineProvider.lowStockMedicines.length} medicines need reordering',
                        Icons.warning,
                        Colors.orange,
                        () => _navigateToLowStock(context),
                      ),
                    if (medicineProvider.expiringMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Expiring Soon',
                        '${medicineProvider.expiringMedicines.length} medicines expire within 30 days',
                        Icons.event,
                        Colors.blue,
                        () => _navigateToExpiring(context),
                      ),
                    if (medicineProvider.expiredMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Expired Medicines',
                        '${medicineProvider.expiredMedicines.length} medicines have expired',
                        Icons.dangerous,
                        Colors.red,
                        () => _navigateToExpired(context),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

  Widget _buildReportCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }
}

// Alert Detail Screen - Shows detailed list of medicines based on alert type
enum AlertType { lowStock, expiring, expired }

class AlertDetailScreen extends StatelessWidget {
  final String title;
  final AlertType alertType;

  const AlertDetailScreen({
    super.key,
    required this.title,
    required this.alertType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, medicineProvider, child) {
          List medicines = [];

          switch (alertType) {
            case AlertType.lowStock:
              medicines = medicineProvider.lowStockMedicines;
              break;
            case AlertType.expiring:
              medicines = medicineProvider.expiringMedicines;
              break;
            case AlertType.expired:
              medicines = medicineProvider.expiredMedicines;
              break;
          }

          if (medicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    alertType == AlertType.lowStock
                        ? Icons.check_circle
                        : alertType == AlertType.expiring
                            ? Icons.event_available
                            : Icons.verified,
                    size: 80,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    alertType == AlertType.lowStock
                        ? 'No low stock medicines'
                        : alertType == AlertType.expiring
                            ? 'No expiring medicines'
                            : 'No expired medicines',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return _buildMedicineCard(medicine, alertType, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(
      dynamic medicine, AlertType alertType, BuildContext context) {
    Color cardColor;
    IconData statusIcon;
    String statusText;

    switch (alertType) {
      case AlertType.lowStock:
        cardColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'Low Stock';
        break;
      case AlertType.expiring:
        final daysLeft = medicine.daysUntilExpiry;
        cardColor = daysLeft <= 7 ? Colors.red : Colors.blue;
        statusIcon = Icons.event;
        statusText =
            daysLeft <= 7 ? 'Expiring Soon!' : 'Expiring in $daysLeft days';
        break;
      case AlertType.expired:
        cardColor = Colors.red;
        statusIcon = Icons.dangerous;
        statusText = 'Expired';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to medicine detail
          Navigator.pushNamed(context, '/medicine-detail',
              arguments: {'id': medicine.id});
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: cardColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (medicine.batchNumber != null &&
                            medicine.batchNumber!.isNotEmpty)
                          Text(
                            'Batch: ${medicine.batchNumber}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cardColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Stock',
                      '${medicine.quantity} units',
                      Icons.inventory,
                      Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Price',
                      'UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      alertType == AlertType.expired ? 'Expired' : 'Expiry',
                      alertType == AlertType.expired
                          ? DateFormat('yyyy-MM-dd').format(medicine.expiryDate)
                          : DateFormat('yyyy-MM-dd')
                              .format(medicine.expiryDate),
                      Icons.calendar_today,
                      alertType == AlertType.expired
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              if (alertType == AlertType.lowStock) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: medicine.quantity / medicine.minStockLevel,
                  backgroundColor: Colors.grey.shade200,
                  color: cardColor,
                ),
                const SizedBox(height: 4),
                Text(
                  'Min stock level: ${medicine.minStockLevel} units',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
