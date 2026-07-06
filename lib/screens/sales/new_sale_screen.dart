// lib/screens/sales/new_sale_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';
import '../../models/sale.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  _NewSaleScreenState createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final List<CartItem> _cartItems = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Mobile Money',
    'Bank Transfer'
  ];

  double get _subtotal {
    if (_cartItems.isEmpty) return 0.0;
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _total => _subtotal;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await provider.loadMedicines();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addToCart(Medicine medicine, int quantity) {
    setState(() {
      final existingIndex =
          _cartItems.indexWhere((item) => item.medicine.id == medicine.id);

      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity += quantity;
      } else {
        _cartItems.add(CartItem(
          medicine: medicine,
          quantity: quantity,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${medicine.name} x$quantity to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateQuantity(int index, int newQuantity) {
    if (index >= _cartItems.length) return;

    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        final maxStock = _cartItems[index].medicine.quantity;
        if (newQuantity <= maxStock) {
          _cartItems[index].quantity = newQuantity;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $maxStock units available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _removeFromCart(int index) {
    if (index >= _cartItems.length) return;

    setState(() {
      _cartItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from cart'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showMedicineSelector() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                width: double.maxFinite,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add Medicine',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search medicine...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setStateDialog(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setStateDialog(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer<MedicineProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading &&
                              provider.medicines.isEmpty) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final today = DateTime.now();
                          final todayMidnight =
                              DateTime(today.year, today.month, today.day);

                          var availableMedicines = provider.medicines
                              .where((m) =>
                                  m.expiryDate.isAfter(todayMidnight) &&
                                  m.quantity > 0)
                              .toList();

                          if (searchQuery.isNotEmpty) {
                            availableMedicines = availableMedicines
                                .where((m) =>
                                    m.name
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()) ||
                                    m.genericName
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()))
                                .toList();
                          }

                          if (availableMedicines.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.medical_services_outlined,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'No available medicines'
                                        : 'No matching medicines',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: availableMedicines.length,
                            itemBuilder: (context, index) {
                              final medicine = availableMedicines[index];
                              final isLowStock =
                                  medicine.quantity <= medicine.minStockLevel;
                              final alreadyInCart = _cartItems.any(
                                  (item) => item.medicine.id == medicine.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isLowStock
                                        ? Colors.orange
                                        : Colors.green,
                                    child: Text(
                                      medicine.quantity.toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  title: Text(
                                    medicine.name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Stock: ${medicine.quantity} | UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  trailing: alreadyInCart
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    _showQuantityDialog(medicine);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuantityDialog(Medicine medicine) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Add ${medicine.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Price: UGX ${medicine.retailPrice.toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) {
                            setStateDialog(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          quantity.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (quantity < medicine.quantity) {
                            setStateDialog(() {
                              quantity++;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Only ${medicine.quantity} units available'),
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Available: ${medicine.quantity} units',
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart(medicine, quantity);
                  },
                  child: Text(
                      'Add (UGX ${(medicine.retailPrice * quantity).toStringAsFixed(0)})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medicine to cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final saleData = {
      'items': _cartItems
          .map((item) => {
                'medicine_id': item.medicine.id,
                'quantity': item.quantity,
              })
          .toList(),
      'user': authProvider.currentUser!.id,
      'customer_name': _customerNameController.text.trim(),
      'notes': _notesController.text.trim(),
      'payment_method': _selectedPaymentMethod,
    };

    final provider = Provider.of<SaleProvider>(context, listen: false);
    final success = await provider.createSale(saleData);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      await provider.loadSales(refresh: true);

      // Fixed: Handle nullable SaleGroup properly
      SaleGroup? saleGroup;
      try {
        saleGroup = provider.saleGroups.firstWhere(
          (group) => group.saleDate
              .isAfter(DateTime.now().subtract(const Duration(minutes: 1))),
        );
      } catch (e) {
        if (provider.saleGroups.isNotEmpty) {
          saleGroup = provider.saleGroups.first;
        }
      }

      if (saleGroup != null && saleGroup.saleId.isNotEmpty) {
        try {
          await PdfService.generateSaleReceipt(saleGroup);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Sale completed! Receipt generated.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          debugPrint('PDF Generation Error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(' Sale completed but PDF generation failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Sale completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to process sale'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showMedicineSelector,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add Medicine to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_cartItems.isNotEmpty) ...[
                    Text(
                      'Cart Items (${_cartItems.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.medicine.name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'UGX ${item.price.toStringAsFixed(0)} each',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => _removeFromCart(index),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 20),
                                          onPressed: () => _updateQuantity(
                                              index, item.quantity - 1),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            item.quantity.toString(),
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20),
                                          onPressed: () => _updateQuantity(
                                              index, item.quantity + 1),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'UGX ${item.subtotal.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Details',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerNameController,
                            decoration: InputDecoration(
                              labelText: 'Customer Name (Optional)',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPaymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: const Icon(Icons.payment),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes (Optional)',
                              prefixIcon: const Icon(Icons.note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'UGX ${_total.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text:
                      'COMPLETE SALE${_cartItems.isNotEmpty ? ' (${_cartItems.length} items)' : ''}',
                  onPressed: _processSale,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
