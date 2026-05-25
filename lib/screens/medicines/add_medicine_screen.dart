import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../models/supplier.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _unitsPerPackController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _expiryDate;
  Category? _selectedCategory;
  Supplier? _selectedSupplier;
  String _unitType = 'tablet';
  
  bool _isLoading = false;
  String? _expiryError;

  final List<String> _unitTypes = [
    'tablet', 'capsule', 'bottle', 'strip', 'box', 'pack', 'ml', 'g'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await Future.wait([
      provider.loadCategories(),
      provider.loadSuppliers(),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _unitCostController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _unitsPerPackController.dispose();
    _batchNumberController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expiryError = null;
      });
    }
  }

  String? _validateExpiryDate() {
    if (_expiryDate == null) {
      return 'Please select expiry date';
    }
    
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    if (_expiryDate!.isBefore(todayMidnight)) {
      return 'Expiry date cannot be in the past';
    }
    
    return null;
  }

  double _calculateProfitMargin() {
    final unitCost = double.tryParse(_unitCostController.text) ?? 0;
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0;
    if (unitCost == 0) return 0;
    return ((retailPrice - unitCost) / unitCost * 100).roundToDouble();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _expiryError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final expiryValidation = _validateExpiryDate();
    if (expiryValidation != null) {
      setState(() {
        _expiryError = expiryValidation;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $expiryValidation'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final medicineData = {
      'name': _nameController.text.trim(),
      'generic_name': _genericNameController.text.trim(),
      'category': _selectedCategory!.id,
      'supplier': _selectedSupplier!.id,
      'unit_cost': double.parse(_unitCostController.text),
      'wholesale_price': double.parse(_wholesalePriceController.text),
      'retail_price': double.parse(_retailPriceController.text),
      'discount_percentage': double.parse(_discountController.text.isEmpty ? '0' : _discountController.text),
      'quantity': int.parse(_quantityController.text),
      'min_stock_level': int.parse(_minStockController.text),
      'unit_type': _unitType,
      'units_per_pack': int.parse(_unitsPerPackController.text.isEmpty ? '1' : _unitsPerPackController.text),
      'barcode': _barcodeController.text.trim(),
      'expiry_date': _expiryDate!.toIso8601String().split('T')[0],
      'batch_number': _batchNumberController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final provider = Provider.of<MedicineProvider>(context, listen: false);
    final success = await provider.addMedicine(medicineData);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Medicine added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to add medicine'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canAdd = authProvider.currentUser?.isAdmin ?? false;

    if (!canAdd) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Medicine'),
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
                'You do not have permission to add medicines',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Basic Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _nameController,
                            label: 'Medicine Name *',
                            prefixIcon: Icons.medical_services,
                            validator: Validators.required,
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _genericNameController,
                            label: 'Generic Name',
                            prefixIcon: Icons.science,
                          ),
                          const SizedBox(height: 16),
                          
                          // Searchable Category Dropdown
                          SearchableDropdown<Category>(
                            items: provider.categories,
                            selectedItem: _selectedCategory,
                            label: 'Category',
                            hint: 'Search for a category...',
                            prefixIcon: Icons.category,
                            displayName: (category) => category.name,
                            validator: (value) => value == null ? 'Please select a category' : null,
                            onChanged: (category) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            isLoading: provider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Searchable Supplier Dropdown
                          SearchableDropdown<Supplier>(
                            items: provider.suppliers,
                            selectedItem: _selectedSupplier,
                            label: 'Supplier',
                            hint: 'Search for a supplier...',
                            prefixIcon: Icons.business,
                            displayName: (supplier) => supplier.name,
                            validator: (value) => value == null ? 'Please select a supplier' : null,
                            onChanged: (supplier) {
                              setState(() {
                                _selectedSupplier = supplier;
                              });
                            },
                            isLoading: provider.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pricing & Stock Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing & Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _unitCostController,
                            label: 'Unit Cost (UGX) *',
                            prefixIcon: Icons.shopping_cart,
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                          ),
                          const SizedBox(height: 12),

                          CustomTextField(
                            controller: _wholesalePriceController,
                            label: 'Wholesale Price (UGX) *',
                            prefixIcon: Icons.business,
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                          ),
                          const SizedBox(height: 12),

                          CustomTextField(
                            controller: _retailPriceController,
                            label: 'Retail Price (UGX) *',
                            prefixIcon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: Validators.positiveNumber,
                          ),
                          const SizedBox(height: 12),

                          CustomTextField(
                            controller: _discountController,
                            label: 'Default Discount (%)',
                            prefixIcon: Icons.percent,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          // FIXED: Wrapped Row in SingleChildScrollView to prevent overflow
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.42,
                                  child: CustomTextField(
                                    controller: _quantityController,
                                    label: 'Quantity *',
                                    prefixIcon: Icons.inventory,
                                    keyboardType: TextInputType.number,
                                    validator: Validators.integer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.42,
                                  child: DropdownButtonFormField<String>(
                                    value: _unitType,
                                    decoration: InputDecoration(
                                      labelText: 'Unit Type',
                                      prefixIcon: const Icon(Icons.science),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: _unitTypes.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type[0].toUpperCase() + type.substring(1),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _unitType = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          CustomTextField(
                            controller: _unitsPerPackController,
                            label: 'Units per Pack/Strip',
                            prefixIcon: Icons.inventory_2,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          CustomTextField(
                            controller: _minStockController,
                            label: 'Minimum Stock Level *',
                            prefixIcon: Icons.warning,
                            keyboardType: TextInputType.number,
                            validator: Validators.integer,
                          ),

                          // Profit Margin Preview
                          if (_unitCostController.text.isNotEmpty && 
                              _retailPriceController.text.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.veryLightGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Profit Margin:',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${_calculateProfitMargin()}%',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: _calculateProfitMargin() > 20 
                                          ? Colors.green 
                                          : _calculateProfitMargin() > 10 
                                              ? Colors.orange 
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Expiry and Batch Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry & Batch',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Expiry Date *',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                errorText: _expiryError,
                              ),
                              child: Text(
                                _expiryDate == null
                                    ? 'Select Date'
                                    : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                style: GoogleFonts.poppins(
                                  color: _expiryError != null ? Colors.red : null,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _batchNumberController,
                            label: 'Batch Number',
                            prefixIcon: Icons.qr_code,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _barcodeController,
                                  label: 'Barcode/QR Code',
                                  prefixIcon: Icons.qr_code,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(context, '/qr-scanner');
                                  if (result != null && result is String) {
                                    setState(() {
                                      _barcodeController.text = result;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.qr_code_scanner),
                                color: AppColors.primaryGreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            prefixIcon: Icons.description,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  CustomButton(
                    text: 'ADD MEDICINE',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
