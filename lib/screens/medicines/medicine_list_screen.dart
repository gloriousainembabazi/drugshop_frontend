import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../models/category.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/medicine_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';
import 'medicine_detail_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  _MedicineListScreenState createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Name';
  Category? _selectedCategory;
  
  final List<String> _filters = ['All', 'Low Stock', 'Expiring Soon', 'Expired'];
  final List<String> _sortOptions = ['Name', 'Price', 'Stock', 'Most Sold'];
  
  List<Category> _categories = [];
  List<Map<String, dynamic>> _mostSoldMedicines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    
    _loadInitialData();
    
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadInitialData() async {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    
    await Future.wait([
      medicineProvider.loadCategories(),
      medicineProvider.loadMedicines(refresh: true),
      medicineProvider.loadLowStockMedicines(),
      medicineProvider.loadExpiringMedicines(),
      medicineProvider.loadExpiredMedicines(),
      saleProvider.loadSales(),
    ]);
    
    if (mounted) {
      setState(() {
        _categories = medicineProvider.categories;
      });
    }
    
    _calculateMostSoldMedicines(saleProvider, medicineProvider);
  }

  void _calculateMostSoldMedicines(SaleProvider saleProvider, MedicineProvider medicineProvider) {
    final Map<String, Map<String, dynamic>> salesData = {};
    
    for (var sale in saleProvider.sales) {
      if (!salesData.containsKey(sale.medicineName)) {
        // Find medicine - if not found, skip this sale
        Medicine? medicine;
        try {
          medicine = medicineProvider.medicines.firstWhere(
            (m) => m.name == sale.medicineName,
          );
        } catch (e) {
          // Medicine not found, skip this sale
          continue;
        }
        
        if (medicine != null) {
          salesData[sale.medicineName] = {
            'name': sale.medicineName,
            'quantity': 0,
            'revenue': 0.0,
            'medicineId': medicine.id,
          };
        }
      }
      
      if (salesData.containsKey(sale.medicineName)) {
        salesData[sale.medicineName]!['quantity'] += sale.quantity;
        salesData[sale.medicineName]!['revenue'] += sale.totalPrice;
      }
    }
    
    final sortedList = salesData.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    
    if (mounted) {
      setState(() {
        _mostSoldMedicines = sortedList.take(10).toList();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<MedicineProvider>(context, listen: false);
      if (!provider.isLoading) {
        provider.loadMedicines();
      }
    }
  }

  List<Medicine> _getFilteredMedicines(MedicineProvider provider) {
    List<Medicine> medicines;
    
    switch (_selectedFilter) {
      case 'Low Stock':
        medicines = provider.lowStockMedicines;
        break;
      case 'Expiring Soon':
        medicines = provider.expiringMedicines;
        break;
      case 'Expired':
        medicines = provider.expiredMedicines;
        break;
      default:
        medicines = provider.medicines;
    }
    
    if (_selectedCategory != null) {
      medicines = medicines.where((m) => m.categoryId == _selectedCategory!.id).toList();
    }
    
    return medicines;
  }

  List<Medicine> _filterBySearch(List<Medicine> medicines) {
    if (_searchQuery.isEmpty) return medicines;
    return medicines.where((medicine) =>
      medicine.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      medicine.genericName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      medicine.batchNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Medicine> _sortMedicines(List<Medicine> medicines) {
    final sorted = List<Medicine>.from(medicines);
    
    switch (_selectedSort) {
      case 'Name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Price':
        sorted.sort((a, b) => a.retailPrice.compareTo(b.retailPrice));
        break;
      case 'Stock':
        sorted.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Most Sold':
        sorted.sort((a, b) {
          final soldA = _mostSoldMedicines.firstWhere(
            (item) => item['name'] == a.name,
            orElse: () => {'quantity': 0},
          )['quantity'] as int;
          final soldB = _mostSoldMedicines.firstWhere(
            (item) => item['name'] == b.name,
            orElse: () => {'quantity': 0},
          )['quantity'] as int;
          return soldB.compareTo(soldA);
        });
        break;
    }
    
    return sorted;
  }

  void _navigateToMedicineDetail(Medicine medicine) {
    print('🔍 Navigating to medicine detail:');
    print('   Name: ${medicine.name}');
    print('   ID: ${medicine.id}');
    print('   Is Expired: ${medicine.isExpired}');
    
    if (medicine.id == null || medicine.id == 0) {
      print('❌ ERROR: Medicine ID is null or 0!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid medicine ID')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailScreen(medicineId: medicine.id),
      ),
    ).then((_) {
      print('✅ Navigation completed');
    }).catchError((error) {
      print('❌ Navigation error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening medicine: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Medicines'),
            Tab(text: 'Most Sold'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicineListTab(),
          _buildMostSoldTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-medicine');
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicineListTab() {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              
              // Category Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Filter by Category',
                    prefixIcon: const Icon(Icons.category, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<Category>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: (Category? value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              // Status Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontSize: 12)),
                    ..._filters.map((filter) {
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
                          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppConstants.primaryColor,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Sort Options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontSize: 12)),
                    ..._sortOptions.map((sortOption) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(sortOption, style: const TextStyle(fontSize: 12)),
                          selected: _selectedSort == sortOption,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSort = sortOption;
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Medicine List
        Expanded(
          child: Consumer<MedicineProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.medicines.isEmpty) {
                return const LoadingIndicator();
              }

              List<Medicine> filteredMedicines = _getFilteredMedicines(provider);
              filteredMedicines = _filterBySearch(filteredMedicines);
              filteredMedicines = _sortMedicines(filteredMedicines);

              if (filteredMedicines.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medicines found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
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
                onRefresh: () async {
                  await _loadInitialData();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMedicines.length + (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredMedicines.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final medicine = filteredMedicines[index];
                    
                    return MedicineCard(
                      medicine: medicine,
                      onTap: () {
                        _navigateToMedicineDetail(medicine);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMostSoldTab() {
    if (_mostSoldMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No sales data available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some sales to see most sold medicines',
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
      onRefresh: () async {
        final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
        final saleProvider = Provider.of<SaleProvider>(context, listen: false);
        await saleProvider.loadSales();
        _calculateMostSoldMedicines(saleProvider, medicineProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mostSoldMedicines.length,
        itemBuilder: (context, index) {
          final sale = _mostSoldMedicines[index];
          final rank = index + 1;
          final medicineId = sale['medicineId'] as int;
          
          Color rankColor;
          
          if (rank == 1) rankColor = Colors.amber;
          else if (rank == 2) rankColor = Colors.grey.shade600;
          else if (rank == 3) rankColor = Colors.brown;
          else rankColor = Colors.blue;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () async {
                print('🖱️ TAPPED MOST SOLD: ${sale['name']} (ID: $medicineId)');
                
                final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
                
                // Find the medicine by ID
                Medicine? medicine;
                try {
                  medicine = medicineProvider.medicines.firstWhere(
                    (m) => m.id == medicineId,
                  );
                } catch (e) {
                  print('⚠️ Medicine not found with ID: $medicineId, reloading...');
                  await medicineProvider.loadMedicines();
                  try {
                    medicine = medicineProvider.medicines.firstWhere(
                      (m) => m.id == medicineId,
                    );
                  } catch (e2) {
                    print('❌ Still cannot find medicine with ID: $medicineId');
                    medicine = null;
                  }
                }
                
                if (medicine != null) {
                  _navigateToMedicineDetail(medicine);
                } else {
                  print('❌ Could not find medicine with ID: $medicineId');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medicine not found')),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.shopping_cart, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${sale['quantity']} units sold',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.attach_money, size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'UGX ${(sale['revenue'] as double).toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
