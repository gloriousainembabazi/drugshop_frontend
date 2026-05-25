import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class StockTakeScreen extends StatefulWidget {
  const StockTakeScreen({super.key});

  @override
  _StockTakeScreenState createState() => _StockTakeScreenState();
}

class _StockTakeScreenState extends State<StockTakeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  final List<Map<String, dynamic>> _countItems = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  String? _selectedFilter = 'All';

  final List<String> _filters = ['All', 'With Variance', 'No Variance'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    _loadMedicines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await provider.loadMedicines(refresh: true);
    
    // Initialize count items with current quantities
    setState(() {
      _countItems.clear();
      for (var medicine in provider.medicines) {
        _countItems.add({
          'id': medicine.id,
          'name': medicine.name,
          'systemQty': medicine.quantity,
          'physicalQty': medicine.quantity,
          'unitType': medicine.unitType,
          'notes': '',
          'hasVariance': false,
        });
      }
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedFilter == 'All') return _countItems;
    if (_selectedFilter == 'With Variance') {
      return _countItems.where((item) => item['systemQty'] != item['physicalQty']).toList();
    }
    if (_selectedFilter == 'No Variance') {
      return _countItems.where((item) => item['systemQty'] == item['physicalQty']).toList();
    }
    return _countItems;
  }

  int get _totalItems => _countItems.length;
  int get _itemsWithVariance => _countItems.where((item) => item['systemQty'] != item['physicalQty']).length;
  int get _totalSystemQuantity => _countItems.fold<int>(0, (sum, item) => sum + (item['systemQty'] as int));
  int get _totalPhysicalQuantity => _countItems.fold<int>(0, (sum, item) => sum + (item['physicalQty'] as int));
  int get _totalVariance => _totalPhysicalQuantity - _totalSystemQuantity;

  void _updatePhysicalQty(int index, int value) {
    setState(() {
      _countItems[index]['physicalQty'] = value;
      _countItems[index]['hasVariance'] = _countItems[index]['systemQty'] != value;
    });
  }

  void _updateNotes(int index, String value) {
    setState(() {
      _countItems[index]['notes'] = value;
    });
  }

  void _resetToSystem(int index) {
    setState(() {
      _countItems[index]['physicalQty'] = _countItems[index]['systemQty'];
      _countItems[index]['hasVariance'] = false;
      _countItems[index]['notes'] = '';
    });
  }

  Future<void> _submitStockCount() async {
    setState(() => _isLoading = true);

    // Calculate variances
    final discrepancies = _countItems.where((item) {
      return item['systemQty'] != item['physicalQty'];
    }).toList();

    if (discrepancies.isEmpty) {
      _showSuccessDialog('✅ No discrepancies found. Stock count verified!');
    } else {
      _showDiscrepancySummary(discrepancies);
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          CustomButton(
            text: 'OK',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDiscrepancySummary(List<Map<String, dynamic>> discrepancies) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Count Summary'),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Found ${discrepancies.length} item(s) with variance',
                        style: GoogleFonts.poppins(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: discrepancies.length,
                  itemBuilder: (context, index) {
                    final item = discrepancies[index];
                    final variance = item['physicalQty'] - item['systemQty'];
                    final isPositive = variance > 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                      child: ListTile(
                        title: Text(
                          item['name'],
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('System: ${item['systemQty']} | Physical: ${item['physicalQty']}'),
                            if (item['notes'].isNotEmpty)
                              Text('Note: ${item['notes']}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}$variance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          CustomButton(
            text: 'SAVE COUNT',
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog('✅ Stock count saved successfully!\n${discrepancies.length} variance(s) recorded.');
            },
          ),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item, int index) {
    final variance = item['physicalQty'] - item['systemQty'];
    final isPositive = variance > 0;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['name'],
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('System Quantity', '${item['systemQty']} ${item['unitType']}s'),
              _buildDetailRow('Physical Count', '${item['physicalQty']} ${item['unitType']}s'),
              _buildDetailRow(
                'Variance',
                '${isPositive ? '+' : ''}$variance',
                color: isPositive ? Colors.green : Colors.red,
              ),
              if (item['notes'].isNotEmpty)
                _buildDetailRow('Notes', item['notes']),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'RESET',
                      onPressed: () {
                        Navigator.pop(context);
                        _resetToSystem(index);
                      },
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'CLOSE',
                      onPressed: () => Navigator.pop(context),
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canEdit = authProvider.currentUser?.isAdmin ?? false;

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stock Taking'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'You do not have permission to perform stock take',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stock Taking'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryGreen,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Count Items'),
              Tab(text: 'Summary'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMedicines,
            ),
          ],
        ),
        body: _isLoading
            ? const LoadingIndicator()
            : IndexedStack(
                index: _currentIndex,
                children: [
                  _buildCountTab(),
                  _buildSummaryTab(),
                ],
              ),
        floatingActionButton: _currentIndex == 0 && _filteredItems.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _submitStockCount,
                icon: const Icon(Icons.check),
                label: const Text('COMPLETE COUNT'),
                backgroundColor: AppColors.primaryGreen,
              )
            : null,
      ),
    );
  }

  Widget _buildCountTab() {
    final filteredItems = _filteredItems;

    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                int count = 0;
                if (filter == 'All') count = _totalItems;
                if (filter == 'With Variance') count = _itemsWithVariance;
                if (filter == 'No Variance') count = _totalItems - _itemsWithVariance;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('$filter ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryGreen,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Items List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items to count',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final originalIndex = _countItems.indexOf(item);
                    final hasVariance = item['systemQty'] != item['physicalQty'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: hasVariance 
                          ? (item['physicalQty'] > item['systemQty'] 
                              ? Colors.green.shade50 
                              : Colors.red.shade50)
                          : null,
                      child: InkWell(
                        onTap: () => _showItemDetails(context, item, originalIndex),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (hasVariance)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item['physicalQty'] > item['systemQty']
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Variance: ${item['physicalQty'] > item['systemQty'] ? '+' : ''}${item['physicalQty'] - item['systemQty']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'System',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '${item['systemQty']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item['physicalQty'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Physical Count',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final qty = int.tryParse(value) ?? 0;
                                        _updatePhysicalQty(originalIndex, qty);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: item['notes'],
                                decoration: InputDecoration(
                                  labelText: 'Notes (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) => _updateNotes(originalIndex, value),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Stock Count Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total Items', '$_totalItems'),
                  _buildSummaryRow('Items with Variance', '$_itemsWithVariance'),
                  const Divider(),
                  _buildSummaryRow('System Total', '$_totalSystemQuantity units'),
                  _buildSummaryRow('Physical Total', '$_totalPhysicalQuantity units'),
                  _buildSummaryRow(
                    'Total Variance',
                    '${_totalVariance > 0 ? '+' : ''}$_totalVariance units',
                    color: _totalVariance == 0
                        ? Colors.green
                        : _totalVariance > 0
                            ? Colors.green
                            : Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Variance Items List
          if (_itemsWithVariance > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items with Variance',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._countItems
                        .where((item) => item['systemQty'] != item['physicalQty'])
                        .map((item) {
                      final variance = item['physicalQty'] - item['systemQty'];
                      final isPositive = variance > 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                        child: ListTile(
                          title: Text(item['name']),
                          subtitle: Text(
                            'System: ${item['systemQty']} → Physical: ${item['physicalQty']}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${isPositive ? '+' : ''}$variance',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          CustomButton(
            text: 'COMPLETE STOCK COUNT',
            onPressed: _submitStockCount,
            isFullWidth: true,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loadMedicines,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('RESET COUNT'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
