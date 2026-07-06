import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  _SaleListScreenState createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadSales();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSales() async {
    final provider = Provider.of<SaleProvider>(context, listen: false);
    await provider.loadSales(refresh: true);
    await provider.loadDailySales();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<SaleProvider>(context, listen: false);
      if (!provider.isLoading) {
        provider.loadSales();
      }
    }
  }

  List<SaleGroup> _getFilteredSales(List<SaleGroup> saleGroups) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return saleGroups.where((group) {
          return group.saleDate.year == now.year &&
              group.saleDate.month == now.month &&
              group.saleDate.day == now.day;
        }).toList();
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return saleGroups
            .where((group) => group.saleDate.isAfter(weekAgo))
            .toList();
      case 'This Month':
        return saleGroups.where((group) {
          return group.saleDate.year == now.year &&
              group.saleDate.month == now.month;
        }).toList();
      default:
        return saleGroups;
    }
  }

  void _navigateToSaleDetail(String saleId) {
    if (saleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid sale ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('🔍 Navigating to sale detail with ID: $saleId');

    Navigator.pushNamed(
      context,
      '/sale-detail',
      arguments: {'sale_id': saleId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor:
                          AppConstants.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppConstants.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.saleGroups.isEmpty) {
            return const LoadingIndicator();
          }

          final filteredSales = _getFilteredSales(provider.saleGroups);

          if (filteredSales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sales found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isAdmin)
                    Text(
                      'Tap the + button to create a new sale',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadSales,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredSales.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredSales.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final saleGroup = filteredSales[index];

                // Skip if saleId is empty
                if (saleGroup.saleId.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SaleGroupCard(
                  saleGroup: saleGroup,
                  onTap: () => _navigateToSaleDetail(saleGroup.saleId),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton:
          !(Provider.of<AuthProvider>(context).currentUser?.isAdmin ?? false)
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/new-sale').then((_) {
                      _loadSales();
                    });
                  },
                  backgroundColor: AppConstants.primaryColor,
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class SaleGroupCard extends StatelessWidget {
  final SaleGroup saleGroup;
  final VoidCallback onTap;

  const SaleGroupCard({
    super.key,
    required this.saleGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // USE THE CLEAN GETTERS from SaleGroup
    final displaySaleId = saleGroup.cleanSaleId;
    final displayCustomer = saleGroup.cleanCustomerName;
    final displayStaff = saleGroup.staffName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt,
                      color: AppConstants.primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displaySaleId,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${saleGroup.medicineCount} item${saleGroup.medicineCount > 1 ? 's' : ''} • ${saleGroup.totalItems} unit${saleGroup.totalItems > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayCustomer != 'Walk-in Customer'
                              ? 'Customer: $displayCustomer • By: $displayStaff'
                              : 'By: $displayStaff',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UGX ${saleGroup.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${saleGroup.saleDate.day}/${saleGroup.saleDate.month}/${saleGroup.saleDate.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (saleGroup.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: saleGroup.items.take(3).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.medicineName} (${item.quantity})',
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
                if (saleGroup.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${saleGroup.items.length - 3} more',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
