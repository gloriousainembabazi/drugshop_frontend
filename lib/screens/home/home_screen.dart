// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/credit_provider.dart';
import '../../models/medicine.dart';
import '../../models/sale.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  String _selectedPeriod = 'daily';
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingCredit = true;
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _filteredMedicines = [];
  double _totalCredit = 0;
  double _totalCreditPaid = 0;
  bool _notificationsViewed = false; // ADD THIS LINE

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedPeriod = 'daily';
              break;
            case 1:
              _selectedPeriod = 'weekly';
              break;
            case 2:
              _selectedPeriod = 'monthly';
              break;
          }
        });
      }
    });
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final creditProvider = Provider.of<CreditProvider>(context, listen: false);

    try {
      await Future.wait([
        medicineProvider.loadMedicines(refresh: true),
        medicineProvider.loadLowStockMedicines(),
        medicineProvider.loadExpiringMedicines(),
        medicineProvider.loadExpiredMedicines(),
        saleProvider.loadSales(refresh: true),
        saleProvider.loadDailySales(),
      ]);

      await _loadCreditData();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCreditData() async {
    setState(() => _isLoadingCredit = true);

    final creditProvider = Provider.of<CreditProvider>(context, listen: false);
    await creditProvider.loadCreditSales();

    final totalCredit =
        creditProvider.creditSales.fold<double>(0, (sum, s) => sum + s.balance);

    final totalCreditPaid = creditProvider.creditSales
        .fold<double>(0, (sum, s) => sum + s.amountPaid);

    if (mounted) {
      setState(() {
        _totalCredit = totalCredit;
        _totalCreditPaid = totalCreditPaid;
        _isLoadingCredit = false;
      });
    }
  }

  void _filterMedicines(String query) {
    final medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = [];
        _isSearching = false;
      } else {
        _filteredMedicines = medicineProvider.medicines
            .where((m) =>
                m.name.toLowerCase().contains(query.toLowerCase()) ||
                m.genericName.toLowerCase().contains(query.toLowerCase()) ||
                m.batchNumber.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _isSearching = true;
      }
    });
  }

  void _showMedicineDetails(Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medicine.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (medicine.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Low Stock',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (medicine.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Expired',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                medicine.genericName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 20),
              _buildDetailRow('Batch Number', medicine.batchNumber),
              _buildDetailRow('Category', medicine.categoryName),
              _buildDetailRow('Supplier', medicine.supplierName),
              _buildDetailRow(
                  'Quantity in Stock', medicine.quantity.toString()),
              _buildDetailRow(
                  'Minimum Stock', medicine.minStockLevel.toString()),
              _buildDetailRow('Retail Price',
                  'UGX ${medicine.retailPrice.toStringAsFixed(0)}'),
              _buildDetailRow('Expiry Date',
                  '${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}'),
              _buildDetailRow(
                  'Days Until Expiry', medicine.daysUntilExpiry.toString()),
              const SizedBox(height: 20),
              if (medicine.isLowStock)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning,
                          size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low stock! Only ${medicine.quantity} left. Min: ${medicine.minStockLevel}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              if (medicine.isExpired)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.dangerous,
                          size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This medicine has expired!',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (medicine.isLowStock)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/add-stock',
                              arguments: medicine.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Order More'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        titleSpacing: 12,
        title: Row(
          children: [
            // Logo Image instead of icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_pharmacy,
                      size: 20,
                      color: AppColors.primaryGreen,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'His Grace Drugshop',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Welcome, ${user?.firstName ?? 'User'}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white, size: 22),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredMedicines = [];
                }
              });
            },
          ),
          const SizedBox(width: 4),
          Consumer<MedicineProvider>(
            builder: (context, provider, child) {
              final totalAlerts = provider.lowStockMedicines.length +
                  provider.expiringMedicines.length +
                  provider.expiredMedicines.length;

              // Only show badge if there are alerts AND user hasn't viewed them
              final showBadge = totalAlerts > 0 && !_notificationsViewed;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                    onPressed: () => _showNotifications(context, totalAlerts),
                  ),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalAlerts > 9 ? '9+' : '$totalAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                user?.initials ?? 'U',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'more':
                  Navigator.pushNamed(context, '/more');
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'more',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('More Features'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _isSearching
              ? _buildSearchResults()
              : _buildMainContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _selectedIndex = index);
          } else {
            _navigateToScreen(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 22),
            activeIcon: Icon(Icons.home, size: 22),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined, size: 22),
            activeIcon: Icon(Icons.medical_services, size: 22),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined, size: 22),
            activeIcon: Icon(Icons.shopping_cart, size: 22),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined, size: 22),
            activeIcon: Icon(Icons.assessment, size: 22),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/add-medicine'),
              backgroundColor: AppColors.primaryGreen,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search medicines...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterMedicines('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterMedicines,
          ),
        ),
        Expanded(
          child: _filteredMedicines.isEmpty && _searchController.text.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No medicines found',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : _filteredMedicines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Type to search medicines',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredMedicines.length,
                      itemBuilder: (context, index) {
                        final medicine = _filteredMedicines[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: medicine.isLowStock
                                  ? Colors.orange
                                  : medicine.isExpired
                                      ? Colors.red
                                      : Colors.green,
                              child: Text(
                                medicine.quantity.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            title: Text(
                              medicine.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Stock: ${medicine.quantity} | UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: medicine.isLowStock
                                ? const Icon(Icons.warning,
                                    color: Colors.orange, size: 18)
                                : medicine.isExpired
                                    ? const Icon(Icons.dangerous,
                                        color: Colors.red, size: 18)
                                    : null,
                            onTap: () => _showMedicineDetails(medicine),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Consumer2<MedicineProvider, SaleProvider>(
              builder: (context, medicineProvider, saleProvider, child) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      'Total Medicines',
                      '${medicineProvider.medicines.length}',
                      Icons.medical_services,
                      Colors.blue,
                      () => Navigator.pushNamed(context, '/medicines'),
                    ),
                    _buildStatCard(
                      'Low Stock',
                      '${medicineProvider.lowStockMedicines.length}',
                      Icons.warning,
                      Colors.orange,
                      () => _showLowStockDetails(context, medicineProvider),
                    ),
                    _buildStatCard(
                      'Today\'s Sales',
                      'UGX ${saleProvider.dailyTotal.toStringAsFixed(0)}',
                      Icons.today,
                      Colors.green,
                      () => Navigator.pushNamed(context, '/sales'),
                    ),
                    _buildStatCard(
                      'Transactions',
                      '${saleProvider.dailyTransactions}',
                      Icons.receipt,
                      Colors.purple,
                      () => Navigator.pushNamed(context, '/sales'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Sales Overview Chart
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade700,
                        labelStyle: GoogleFonts.poppins(fontSize: 12),
                        tabs: const [
                          Tab(text: 'Daily'),
                          Tab(text: 'Weekly'),
                          Tab(text: 'Monthly'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<SaleProvider>(
                      builder: (context, saleProvider, child) {
                        return _buildSalesChart(saleProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Financial Overview
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinancialCard(
                            'Today\'s Sales',
                            'UGX ${_getTodaySales().toStringAsFixed(0)}',
                            Icons.today,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFinancialCard(
                            'Monthly Sales',
                            'UGX ${_getMonthlySales().toStringAsFixed(0)}',
                            Icons.calendar_month,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _isLoadingCredit
                              ? _buildFinancialCard(
                                  'Credit O/S',
                                  'Loading...',
                                  Icons.credit_card,
                                  Colors.orange,
                                )
                              : _buildFinancialCard(
                                  'Credit O/S',
                                  'UGX ${_totalCredit.toStringAsFixed(0)}',
                                  Icons.credit_card,
                                  Colors.orange,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isLoadingCredit
                              ? _buildFinancialCard(
                                  'Credit Paid',
                                  'Loading...',
                                  Icons.payment,
                                  Colors.purple,
                                )
                              : _buildFinancialCard(
                                  'Credit Paid',
                                  'UGX ${_totalCreditPaid.toStringAsFixed(0)}',
                                  Icons.payment,
                                  Colors.purple,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 16),

            // Alerts Section
            Consumer<MedicineProvider>(
              builder: (context, provider, child) {
                final hasLowStock = provider.lowStockMedicines.isNotEmpty;
                final hasExpiring = provider.expiringMedicines.isNotEmpty;
                final hasExpired = provider.expiredMedicines.isNotEmpty;

                if (!hasLowStock && !hasExpiring && !hasExpired) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerts & Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (hasLowStock)
                      _buildAlertCard(
                        '⚠️ Low Stock Alert',
                        '${provider.lowStockMedicines.length} medicine(s) need reordering',
                        Icons.warning,
                        Colors.orange,
                        () => _showLowStockDetails(context, provider),
                      ),
                    if (hasExpiring)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildAlertCard(
                          '⏰ Expiring Soon',
                          '${provider.expiringMedicines.length} medicine(s) will expire within 30 days',
                          Icons.event,
                          Colors.blue,
                          () => _showExpiringDetails(context, provider),
                        ),
                      ),
                    if (hasExpired)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildAlertCard(
                          '❌ Expired Medicines',
                          '${provider.expiredMedicines.length} medicine(s) have expired',
                          Icons.dangerous,
                          Colors.red,
                          () => _showExpiredDetails(context, provider),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Recent Sales Preview - FIXED navigation
            Consumer<SaleProvider>(
              builder: (context, provider, child) {
                if (provider.dailySales.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Sales',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/sales'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                          ),
                          child: Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...provider.dailySales
                        .take(3)
                        .map((sale) => _buildRecentSaleCard(sale)),
                  ],
                );
              },
            ),

            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  double _getTodaySales() {
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    return saleProvider.dailyTotal;
  }

  double _getMonthlySales() {
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final now = DateTime.now();
    return saleProvider.sales
        .where(
            (s) => s.saleDate.year == now.year && s.saleDate.month == now.month)
        .fold<double>(0, (sum, s) => sum + s.totalPrice);
  }

  Widget _buildSalesChart(SaleProvider saleProvider) {
    List<Map<String, dynamic>> chartData = [];

    switch (_selectedPeriod) {
      case 'daily':
        chartData = _prepareDailyChartData(saleProvider.sales);
        break;
      case 'weekly':
        chartData = _prepareWeeklyChartData(saleProvider.sales);
        break;
      case 'monthly':
        chartData = _prepareMonthlyChartData(saleProvider.sales);
        break;
    }

    if (chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.show_chart, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              'No sales data available',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final maxValue = chartData.fold<double>(
        0, (max, d) => d['value'] > max ? d['value'] : max);
    final chartHeight = 160.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(chartData.length, (index) {
              final data = chartData[index];
              final height = maxValue > 0
                  ? (data['value'] / maxValue) * (chartHeight - 40)
                  : 0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (data['value'] > 0)
                      Text(
                        '${(data['value'] / 1000).toStringAsFixed(0)}K',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['label'],
                      style: GoogleFonts.poppins(
                        fontSize: _selectedPeriod == 'daily' ? 8 : 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${_selectedPeriod.toUpperCase()} Sales:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                'UGX ${chartData.fold<double>(0, (sum, d) => sum + d['value']).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _prepareDailyChartData(List<Sale> sales) {
    if (sales.isEmpty) return [];

    final today = DateTime.now();
    final todaySales = sales
        .where((s) =>
            s.saleDate.year == today.year &&
            s.saleDate.month == today.month &&
            s.saleDate.day == today.day)
        .toList();

    if (todaySales.isEmpty) return [];

    final periods = {
      'Morning': 0.0,
      'Afternoon': 0.0,
      'Evening': 0.0,
      'Night': 0.0,
    };

    for (var sale in todaySales) {
      final hour = sale.saleDate.hour;
      if (hour >= 6 && hour < 12) {
        periods['Morning'] = (periods['Morning'] ?? 0) + sale.totalPrice;
      } else if (hour >= 12 && hour < 16) {
        periods['Afternoon'] = (periods['Afternoon'] ?? 0) + sale.totalPrice;
      } else if (hour >= 16 && hour < 20) {
        periods['Evening'] = (periods['Evening'] ?? 0) + sale.totalPrice;
      } else {
        periods['Night'] = (periods['Night'] ?? 0) + sale.totalPrice;
      }
    }

    final result = <Map<String, dynamic>>[];
    if (periods['Morning']! > 0)
      result.add({'label': 'Morning', 'value': periods['Morning']!});
    if (periods['Afternoon']! > 0)
      result.add({'label': 'Afternoon', 'value': periods['Afternoon']!});
    if (periods['Evening']! > 0)
      result.add({'label': 'Evening', 'value': periods['Evening']!});
    if (periods['Night']! > 0)
      result.add({'label': 'Night', 'value': periods['Night']!});

    return result;
  }

  List<Map<String, dynamic>> _prepareWeeklyChartData(List<Sale> sales) {
    if (sales.isEmpty) return [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklySales =
        sales.where((s) => s.saleDate.isAfter(weekAgo)).toList();

    if (weeklySales.isEmpty) return [];

    Map<String, double> dailyTotals = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0
    };

    for (var sale in weeklySales) {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = dayNames[sale.saleDate.weekday - 1];
      dailyTotals[dayName] = (dailyTotals[dayName] ?? 0) + sale.totalPrice;
    }

    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        .map((day) => {'label': day, 'value': dailyTotals[day] ?? 0})
        .toList();
  }

  List<Map<String, dynamic>> _prepareMonthlyChartData(List<Sale> sales) {
    if (sales.isEmpty) return [];

    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final monthlySales =
        sales.where((s) => s.saleDate.isAfter(sixMonthsAgo)).toList();

    if (monthlySales.isEmpty) return [];

    Map<String, double> monthlyTotals = {};
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    for (var sale in monthlySales) {
      final monthName = monthNames[sale.saleDate.month - 1];
      monthlyTotals[monthName] =
          (monthlyTotals[monthName] ?? 0) + sale.totalPrice;
    }

    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = monthNames[date.month - 1];
      result.add({'label': monthName, 'value': monthlyTotals[monthName] ?? 0});
    }
    return result;
  }

  Widget _buildFinancialCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: [
            _buildQuickActionItem(
                'New Sale', Icons.add_shopping_cart, Colors.green, '/new-sale'),
            _buildQuickActionItem(
                'Add Med', Icons.add_box, Colors.blue, '/add-medicine'),
            _buildQuickActionItem(
                'Stock', Icons.inventory, Colors.brown, '/stock-take'),
            _buildQuickActionItem(
                'Credit', Icons.credit_card, Colors.purple, '/credit'),
            _buildQuickActionItem('prescriptions', Icons.description,
                Colors.teal, '/prescriptions'),
            _buildQuickActionItem(
                'Expense', Icons.receipt, Colors.red, '/expenses'),
            _buildQuickActionItem(
                'Reports', Icons.assessment, Colors.orange, '/reports'),
            _buildQuickActionItem(
                'More', Icons.more_horiz, Colors.grey, '/more'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
      String label, IconData icon, Color color, String route) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 11),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: color),
        onTap: onTap,
      ),
    );
  }

  // FIXED: Recent sale card with correct navigation using sale_id
  Widget _buildRecentSaleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.veryLightGreen,
          child: Text(
            sale.medicineName.substring(0, 1).toUpperCase(),
            style: GoogleFonts.poppins(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          sale.medicineName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${sale.saleDate.hour}:${sale.saleDate.minute.toString().padLeft(2, '0')} • ${sale.staffName}',
          style: GoogleFonts.poppins(fontSize: 10),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'UGX ${sale.totalPrice.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              'Qty: ${sale.quantity}',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        // FIXED: Use sale_id instead of id
        onTap: () {
          if (sale.saleId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/sale-detail',
              arguments: {'sale_id': sale.saleId},
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot view sale details: Invalid sale ID'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showLowStockDetails(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Low Stock Medicines (${provider.lowStockMedicines.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'These medicines need to be reordered',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.lowStockMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = provider.lowStockMedicines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        onTap: () {
                          Navigator.pop(context);
                          _showMedicineDetails(medicine);
                        },
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange,
                          child: Text(
                            medicine.quantity.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(
                          medicine.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Current: ${medicine.quantity} | Min: ${medicine.minStockLevel}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/add-stock',
                                arguments: medicine.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: const Size(80, 30),
                          ),
                          child: const Text('Order',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpiringDetails(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Expiring Soon (${provider.expiringMedicines.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.expiringMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = provider.expiringMedicines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        onTap: () {
                          Navigator.pop(context);
                          _showMedicineDetails(medicine);
                        },
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Text(
                            medicine.daysUntilExpiry.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(
                          medicine.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Expires in ${medicine.daysUntilExpiry} days',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpiredDetails(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Expired Medicines (${provider.expiredMedicines.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.expiredMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = provider.expiredMedicines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      color: Colors.red.shade50,
                      child: ListTile(
                        dense: true,
                        onTap: () {
                          Navigator.pop(context);
                          _showMedicineDetails(medicine);
                        },
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.dangerous,
                              color: Colors.white, size: 16),
                        ),
                        title: Text(
                          medicine.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Expired on ${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.warning,
                            color: Colors.red, size: 16),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context, int totalAlerts) {
    // Mark notifications as viewed - this will clear the badge
    setState(() {
      _notificationsViewed = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  if (provider.lowStockMedicines.isEmpty &&
                      provider.expiringMedicines.isEmpty &&
                      provider.expiredMedicines.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No new notifications'),
                      ),
                    ),
                  if (provider.lowStockMedicines.isNotEmpty)
                    _buildNotificationSection(
                      '⚠️ Low Stock Alert',
                      provider.lowStockMedicines,
                      Colors.orange,
                      Icons.warning,
                      'Stock:',
                    ),
                  if (provider.expiringMedicines.isNotEmpty)
                    _buildNotificationSection(
                      '⏰ Expiring Soon',
                      provider.expiringMedicines,
                      Colors.blue,
                      Icons.event,
                      'Expires in:',
                    ),
                  if (provider.expiredMedicines.isNotEmpty)
                    _buildNotificationSection(
                      '❌ Expired Medicines',
                      provider.expiredMedicines,
                      Colors.red,
                      Icons.dangerous,
                      'Expired:',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationSection(String title, List<Medicine> medicines,
      Color color, IconData icon, String detailLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...medicines.take(3).map(
              (medicine) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: Icon(icon, color: color, size: 18),
                title: Text(
                  medicine.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$detailLabel ${title.contains('Low') ? '${medicine.quantity} (Min: ${medicine.minStockLevel})' : title.contains('Expiring') ? '${medicine.daysUntilExpiry} days' : '${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}'}',
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showMedicineDetails(medicine);
                },
              ),
            ),
        if (medicines.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              '+${medicines.length - 3} more',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/medicines').then((_) {
          if (mounted) setState(() => _selectedIndex = 1);
        });
        break;
      case 2:
        Navigator.pushNamed(context, '/sales').then((_) {
          if (mounted) setState(() => _selectedIndex = 2);
        });
        break;
      case 3:
        Navigator.pushNamed(context, '/reports').then((_) {
          if (mounted) setState(() => _selectedIndex = 3);
        });
        break;
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
