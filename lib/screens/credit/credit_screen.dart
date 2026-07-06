// lib/screens/credit/credit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/credit.dart';
import '../../models/medicine.dart';
import '../../providers/credit_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/medicine_search_dialog.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import 'add_customer_screen.dart';

// Cart item model
class CartItem {
  Medicine medicine;
  int quantity;

  CartItem({
    required this.medicine,
    required this.quantity,
  });

  double get totalPrice => quantity * medicine.retailPrice;
}

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Customer? _selectedCustomer;
  Medicine? _selectedMedicine;
  final List<CartItem> _cartItems = [];

  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentAmountController = TextEditingController();

  String _customerSearchQuery = '';
  String _creditSearchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CreditProvider>().loadCustomers();
        context.read<CreditProvider>().loadCreditSales();
        context.read<MedicineProvider>().loadMedicines();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment(CreditSale sale) async {
    final amount = double.tryParse(_paymentAmountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amount')),
      );
      return;
    }

    if (amount > sale.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Amount exceeds balance of UGX ${sale.balance.toStringAsFixed(0)}')),
      );
      return;
    }

    final success = await context.read<CreditProvider>().recordPayment(
          sale.id,
          amount,
          'cash',
          'Payment received',
        );

    if (!mounted) return;

    if (success) {
      _paymentAmountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Payment recorded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.read<CreditProvider>().error ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectMedicine() async {
    final medicines = context.read<MedicineProvider>().medicines;
    await showDialog(
      context: context,
      builder: (context) => MedicineSearchDialog(
        medicines: medicines,
        onSelect: (medicine) {
          setState(() => _selectedMedicine = medicine);
        },
      ),
    );
  }

  void _addToCart() {
    if (_selectedMedicine == null) return;

    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid quantity')),
      );
      return;
    }

    if (qty > _selectedMedicine!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Insufficient stock. Available: ${_selectedMedicine!.quantity}')),
      );
      return;
    }

    // Check if item already in cart
    final existingIndex = _cartItems
        .indexWhere((item) => item.medicine.id == _selectedMedicine!.id);

    if (existingIndex != -1) {
      // Update quantity
      setState(() {
        _cartItems[existingIndex].quantity += qty;
      });
    } else {
      // Add new item
      setState(() {
        _cartItems.add(CartItem(
          medicine: _selectedMedicine!,
          quantity: qty,
        ));
      });
    }

    _quantityController.clear();
    setState(() {
      _selectedMedicine = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to cart')),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  double _getCartTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _deleteCreditSale(CreditSale sale) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      'Delete Credit Sale',
      'Are you sure you want to delete credit sale ${sale.creditId}?\n\nThis action cannot be undone.',
    );

    if (!confirmed) return;

    final success =
        await context.read<CreditProvider>().deleteCreditSale(sale.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Credit sale deleted successfully')),
      );
      await context.read<CreditProvider>().loadCreditSales();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<CreditProvider>().error ??
              'Failed to delete credit sale'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          tabs: const [
            Tab(text: 'New Sale'),
            Tab(text: 'Customers'),
            Tab(text: 'Credit Sales'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewSaleTab(),
          _buildCustomersTab(),
          _buildCreditSalesTab(),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddCustomerScreen()),
                );
                if (result == true && mounted) {
                  context.read<CreditProvider>().loadCustomers();
                }
              },
            )
          : null,
    );
  }

  Widget _buildNewSaleTab() {
    return Consumer2<CreditProvider, MedicineProvider>(
      builder: (context, creditProvider, medicineProvider, child) {
        if (creditProvider.isLoading && creditProvider.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Customer Selection
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Select Customer'),
                    ),
                    DropdownButtonFormField<Customer>(
                      initialValue: _selectedCustomer,
                      hint: const Text('Choose a customer'),
                      isExpanded: true,
                      items: creditProvider.customers
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.fullName),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCustomer = v),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Or create new customer
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddCustomerScreen()),
                  );
                  if (result == true && mounted) {
                    await creditProvider.loadCustomers();
                  }
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Create new customer'),
              ),
              const SizedBox(height: 16),

              // Medicine Selection
              GestureDetector(
                onTap: _selectMedicine,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_shopping_cart, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedMedicine == null
                              ? 'Add Medicine to Cart'
                              : 'Selected: ${_selectedMedicine!.name}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedMedicine == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      const Icon(Icons.add),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity and Add Button
              if (_selectedMedicine != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _quantityController,
                        label: 'Quantity',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('ADD'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Cart Items
              if (_cartItems.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Items in Cart',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              'Total: UGX ${_getCartTotal().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text('${item.quantity}x'),
                            ),
                            title: Text(item.medicine.name),
                            subtitle: Text(
                                'UGX ${item.medicine.retailPrice.toStringAsFixed(0)} each'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'UGX ${item.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: _cartItems.isEmpty
                    ? 'ADD ITEMS TO CART'
                    : 'CREATE CREDIT SALE (${_cartItems.length} items)',
                isFullWidth: true,
                onPressed: _cartItems.isEmpty
                    ? null
                    : () async {
                        if (_selectedCustomer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a customer')),
                          );
                          return;
                        }

                        // Prepare items data
                        final items = _cartItems
                            .map((item) => {
                                  'medicine': item.medicine.id,
                                  'quantity': item.quantity,
                                  'unit_price': item.medicine.retailPrice,
                                })
                            .toList();

                        final totalAmount = _getCartTotal();

                        final success = await creditProvider.createCreditSale({
                          'customer': _selectedCustomer!.id,
                          'items': items,
                          'total_amount': totalAmount,
                          'due_date': DateTime.now()
                              .add(const Duration(days: 30))
                              .toIso8601String()
                              .split('T')[0],
                          'notes': _notesController.text,
                        });

                        if (!mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text(' Credit sale created successfully')),
                          );
                          _cartItems.clear();
                          _notesController.clear();
                          setState(() {
                            _selectedCustomer = null;
                          });
                          await creditProvider.loadCreditSales();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(creditProvider.error ??
                                    'Failed to create credit sale')),
                          );
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return Consumer<CreditProvider>(
      builder: (context, creditProvider, child) {
        final customers = creditProvider.searchCustomers(_customerSearchQuery);

        if (creditProvider.isLoading && customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) =>
                    setState(() => _customerSearchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(customer.initials),
                      ),
                      title: Text(customer.fullName),
                      subtitle: Text(customer.phone),
                      trailing: Text(
                        'UGX ${customer.outstandingBalance.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                          _selectedTabIndex = 0;
                          _tabController.animateTo(0);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreditSalesTab() {
    return Consumer<CreditProvider>(
      builder: (context, creditProvider, child) {
        final creditSales =
            creditProvider.searchCreditSales(_creditSearchQuery);
        final overdue = creditProvider.getOverdueCreditSales();

        if (creditProvider.isLoading && creditSales.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (overdue.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have ${overdue.length} overdue credit sale(s)',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by customer, credit ID or medicine...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) =>
                    setState(() => _creditSearchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: creditSales.length,
                itemBuilder: (context, index) {
                  final sale = creditSales[index];
                  final isFullyPaid = sale.balance <= 0;
                  final isOverdue = sale.isOverdue && !isFullyPaid;

                  return Dismissible(
                    key: Key(sale.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDeleteConfirmationDialog(
                        context,
                        'Delete Credit Sale',
                        'Are you sure you want to delete credit sale ${sale.creditId}?',
                      );
                    },
                    onDismissed: (direction) async {
                      await _deleteCreditSale(sale);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      color: isFullyPaid
                          ? Colors.green.shade50
                          : isOverdue
                              ? Colors.red.shade50
                              : null,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isFullyPaid
                              ? Colors.green
                              : isOverdue
                                  ? Colors.red
                                  : Colors.orange,
                          child: Icon(
                            isFullyPaid ? Icons.check : Icons.credit_card,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(sale.creditId),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${sale.customerName} • ${sale.items.length} item(s)'),
                            Text(
                                'Due: ${sale.dueDate.toIso8601String().split('T')[0]}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'UGX ${sale.balance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isFullyPaid
                                        ? Colors.green
                                        : isOverdue
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                ),
                                if (sale.amountPaid > 0)
                                  Text(
                                    'Paid: UGX ${sale.amountPaid.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                            if (!isFullyPaid)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteCreditSale(sale),
                              ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Credit ID', sale.creditId),
                                _buildInfoRow('Customer', sale.customerName),
                                _buildInfoRow(
                                    'Due Date',
                                    sale.dueDate
                                        .toIso8601String()
                                        .split('T')[0]),
                                _buildInfoRow(
                                    'Status', sale.status.toUpperCase()),
                                _buildInfoRow(
                                    'Issued By',
                                    sale.issuedByName.isNotEmpty
                                        ? sale.issuedByName
                                        : 'Staff #${sale.issuedBy}'),
                                const Divider(),
                                const Text(
                                  'Items',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...sale.items.map((item) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                '${item.quantity}x ${item.medicineName}'),
                                          ),
                                          Text(
                                              'UGX ${item.totalPrice.toStringAsFixed(0)}'),
                                        ],
                                      ),
                                    )),
                                const Divider(),
                                _buildInfoRow('Total Amount',
                                    'UGX ${sale.totalAmount.toStringAsFixed(0)}'),
                                _buildInfoRow('Amount Paid',
                                    'UGX ${sale.amountPaid.toStringAsFixed(0)}'),
                                _buildInfoRow('Remaining Balance',
                                    'UGX ${sale.balance.toStringAsFixed(0)}'),
                                if (!isFullyPaid) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Record Payment',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _paymentAmountController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: 'Amount',
                                            prefixText: 'UGX ',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _recordPayment(sale),
                                        child: const Text('PAY'),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('FULLY PAID'),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
