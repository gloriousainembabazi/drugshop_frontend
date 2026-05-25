// lib/screens/medicines/medicine_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/delete_confirmation_dialog.dart';

class MedicineDetailScreen extends StatefulWidget {
  final int medicineId;

  const MedicineDetailScreen({
    super.key,
    required this.medicineId,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Future<Medicine?> _medicineFuture;
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _genericNameController;
  late TextEditingController _retailPriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _unitCostController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _quantityController;
  late TextEditingController _minStockController;
  late TextEditingController _batchNumberController;
  late TextEditingController _expiryDateController;
  late TextEditingController _barcodeController;
  late TextEditingController _unitTypeController;
  late TextEditingController _unitsPerPackController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _medicineFuture = _loadMedicine();
    _initializeControllers();
  }

  Future<Medicine?> _loadMedicine() async {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    await medicineProvider.loadMedicines();
    return medicineProvider.getMedicineById(widget.medicineId);
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _genericNameController = TextEditingController();
    _retailPriceController = TextEditingController();
    _wholesalePriceController = TextEditingController();
    _unitCostController = TextEditingController();
    _discountPercentageController = TextEditingController();
    _quantityController = TextEditingController();
    _minStockController = TextEditingController();
    _batchNumberController = TextEditingController();
    _expiryDateController = TextEditingController();
    _barcodeController = TextEditingController();
    _unitTypeController = TextEditingController();
    _unitsPerPackController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _populateControllers(Medicine medicine) {
    _nameController.text = medicine.name;
    _genericNameController.text = medicine.genericName;
    _retailPriceController.text = medicine.retailPrice.toString();
    _wholesalePriceController.text = medicine.wholesalePrice.toString();
    _unitCostController.text = medicine.unitCost.toString();
    _discountPercentageController.text = medicine.discountPercentage.toString();
    _quantityController.text = medicine.quantity.toString();
    _minStockController.text = medicine.minStockLevel.toString();
    _batchNumberController.text = medicine.batchNumber;
    _expiryDateController.text = DateFormat('yyyy-MM-dd').format(medicine.expiryDate);
    _barcodeController.text = medicine.barcode;
    _unitTypeController.text = medicine.unitType;
    _unitsPerPackController.text = medicine.unitsPerPack.toString();
    _descriptionController.text = medicine.description;
  }

  Future<void> _saveMedicine(Medicine originalMedicine) async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    // Create updated medicine object with all fields
    final updatedMedicine = Medicine(
      id: originalMedicine.id,
      name: _nameController.text,
      genericName: _genericNameController.text,
      categoryId: originalMedicine.categoryId,
      categoryName: originalMedicine.categoryName,
      supplierId: originalMedicine.supplierId,
      supplierName: originalMedicine.supplierName,
      unitCost: double.parse(_unitCostController.text),
      wholesalePrice: double.parse(_wholesalePriceController.text),
      retailPrice: double.parse(_retailPriceController.text),
      discountPercentage: double.parse(_discountPercentageController.text),
      quantity: int.parse(_quantityController.text),
      minStockLevel: int.parse(_minStockController.text),
      unitType: _unitTypeController.text,
      unitsPerPack: int.parse(_unitsPerPackController.text),
      barcode: _barcodeController.text,
      expiryDate: DateFormat('yyyy-MM-dd').parse(_expiryDateController.text),
      batchNumber: _batchNumberController.text,
      description: _descriptionController.text,
      isLowStock: int.parse(_quantityController.text) <= int.parse(_minStockController.text),
      isExpired: DateFormat('yyyy-MM-dd').parse(_expiryDateController.text).isBefore(DateTime.now()),
      isNearingExpiry: _isNearingExpiry(DateFormat('yyyy-MM-dd').parse(_expiryDateController.text)),
      createdAt: originalMedicine.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await context.read<MedicineProvider>().updateMedicine(
      originalMedicine.id,
      updatedMedicine.toJson(),
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Medicine updated successfully')),
      );
      setState(() {
        _isEditing = false;
        _medicineFuture = _loadMedicine();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<MedicineProvider>().error ?? 'Failed to update medicine'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isNearingExpiry(DateTime expiryDate) {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty) {
      _showError('Please enter medicine name');
      return false;
    }
    if (_genericNameController.text.isEmpty) {
      _showError('Please enter generic name');
      return false;
    }
    if (_retailPriceController.text.isEmpty) {
      _showError('Please enter retail price');
      return false;
    }
    if (_quantityController.text.isEmpty) {
      _showError('Please enter quantity');
      return false;
    }
    if (_minStockController.text.isEmpty) {
      _showError('Please enter minimum stock level');
      return false;
    }
    if (_expiryDateController.text.isEmpty) {
      _showError('Please enter expiry date');
      return false;
    }
    
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      'Delete Medicine',
      'Are you sure you want to delete "${medicine.name}"?\n\n'
      '⚠️ WARNING: This action cannot be undone!\n'
      'The medicine will be permanently removed from the database.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await context.read<MedicineProvider>().deleteMedicine(medicine.id);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Medicine deleted successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<MedicineProvider>().error ?? 'Failed to delete medicine'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Medicine',
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final medicine = await _medicineFuture;
                if (medicine != null) {
                  _deleteMedicine(medicine);
                }
              },
              tooltip: 'Delete Medicine',
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : () => setState(() => _isEditing = false),
              child: const Text('Cancel'),
            ),
          if (_isEditing)
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                final medicine = await _medicineFuture;
                if (medicine != null) {
                  _saveMedicine(medicine);
                }
              },
              child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: FutureBuilder<Medicine?>(
        future: _medicineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error loading medicine: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _medicineFuture = _loadMedicine();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final medicine = snapshot.data;
          if (medicine == null) {
            return const Center(
              child: Text('Medicine not found'),
            );
          }
          
          if (!_isEditing) {
            _populateControllers(medicine);
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(medicine),
                const SizedBox(height: 16),
                
                // Basic Information
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
                          ),
                        ),
                        const Divider(),
                        _buildEditableField(
                          'Medicine Name',
                          _nameController,
                          Icons.medical_services,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Generic Name',
                          _genericNameController,
                          Icons.science,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Category', medicine.categoryName),
                        const SizedBox(height: 12),
                        _buildInfoRow('Supplier', medicine.supplierName),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Batch Number',
                          _batchNumberController,
                          Icons.numbers,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Barcode',
                          _barcodeController,
                          Icons.qr_code,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pricing Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pricing Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(),
                        _buildEditableField(
                          'Unit Cost (UGX)',
                          _unitCostController,
                          Icons.shopping_cart,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Wholesale Price (UGX)',
                          _wholesalePriceController,
                          Icons.inventory,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Retail Price (UGX)',
                          _retailPriceController,
                          Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Discount (%)',
                          _discountPercentageController,
                          Icons.local_offer,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stock Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(),
                        _buildEditableField(
                          'Current Stock',
                          _quantityController,
                          Icons.inventory,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Minimum Stock Level',
                          _minStockController,
                          Icons.warning,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Unit Type',
                          _unitTypeController,
                          Icons.category,
                        ),
                        const SizedBox(height: 12),
                        _buildEditableField(
                          'Units Per Pack',
                          _unitsPerPackController,
                          Icons.production_quantity_limits,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isEditing ? _selectExpiryDate : null,
                          child: AbsorbPointer(
                            absorbing: !_isEditing,
                            child: _buildEditableField(
                              'Expiry Date',
                              _expiryDateController,
                              Icons.calendar_today,
                              suffixIcon: _isEditing ? Icons.date_range : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                if (_descriptionController.text.isNotEmpty || _isEditing)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(),
                          _buildEditableField(
                            'Description',
                            _descriptionController,
                            Icons.description,
                            maxLines: 3,
                          ),
                        ],
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

  Widget _buildStatusCard(Medicine medicine) {
  // Determine status and colors
  Color statusColor;
  IconData statusIcon;
  String statusText;
  String statusDetails;
  
  if (medicine.isExpired) {
    statusColor = Colors.red;
    statusIcon = Icons.dangerous;
    statusText = 'EXPIRED';
    statusDetails = 'This medicine expired on ${DateFormat('yyyy-MM-dd').format(medicine.expiryDate)}';
  } else if (medicine.isLowStock) {
    statusColor = Colors.orange;
    statusIcon = Icons.warning;
    statusText = 'LOW STOCK';
    statusDetails = 'Current stock: ${medicine.quantity} (Min: ${medicine.minStockLevel})';
  } else if (medicine.isNearingExpiry) {
    statusColor = Colors.blue;
    statusIcon = Icons.event;
    statusText = 'EXPIRING SOON';
    statusDetails = 'Expires in ${medicine.daysUntilExpiry} days';
  } else {
    statusColor = Colors.green;
    statusIcon = Icons.check_circle;
    statusText = 'GOOD';
    statusDetails = 'Stock: ${medicine.quantity} units';
  }
  
  return Card(
    color: statusColor.withOpacity(0.1),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusDetails,
                  style: const TextStyle(fontSize: 12),
                ),
                if (medicine.isExpired)
                  Text(
                    '⚠️ This medicine should be removed from active inventory',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            suffixIcon: suffixIcon != null 
                ? Icon(suffixIcon, size: 20, color: Colors.grey.shade500)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
