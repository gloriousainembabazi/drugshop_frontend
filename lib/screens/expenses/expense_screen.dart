// lib/screens/expense_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/constants.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.loadExpenses();
      provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryGreen,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Expenses List'),
              Tab(text: 'Add Expense'),
              Tab(text: 'Categories'),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            ExpenseListTab(),
            AddExpenseTab(),
            ExpenseCategoriesTab(),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

class ExpenseListTab extends StatelessWidget {
  const ExpenseListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add an expense',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final totalAmount =
            provider.expenses.fold(0.0, (sum, e) => sum + e.amount);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                        Text(
                          'UGX ${totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadExpenses(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = provider.expenses[index];

                    return Dismissible(
                      key: Key(expense.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: Text(
                                'Are you sure you want to delete "${expense.description}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('DELETE'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        final success =
                            await provider.deleteExpense(expense.id);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Expense deleted successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.error ??
                                    'Failed to delete expense'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            // Reload to fix any state issues
                            await provider.loadExpenses();
                          }
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            expense.description,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.category,
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(expense.paymentDate),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'UGX ${expense.amount.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              if (expense.paymentMethod.isNotEmpty)
                                Text(
                                  expense.paymentMethodDisplay,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: Colors.grey),
                                ),
                            ],
                          ),
                          onTap: () {
                            _showExpenseDetails(context, expense, provider);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseDetails(
      BuildContext context, Expense expense, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expense Details',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            Navigator.pop(context);
                            final confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Expense'),
                                content:
                                    Text('Delete "${expense.description}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final success =
                                  await provider.deleteExpense(expense.id);
                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Expense deleted successfully')),
                                  );
                                  await provider.loadExpenses();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.error ??
                                          'Failed to delete expense'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('ID', expense.expenseId),
                const SizedBox(height: 8),
                _buildDetailRow('Category', expense.category),
                const SizedBox(height: 8),
                _buildDetailRow('Description', expense.description),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Amount', 'UGX ${expense.amount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildDetailRow('Date',
                    DateFormat('dd/MM/yyyy').format(expense.paymentDate)),
                const SizedBox(height: 8),
                _buildDetailRow('Payment Method', expense.paymentMethodDisplay),
                if (expense.supplier != null &&
                    expense.supplier!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Supplier', expense.supplier!),
                ],
                if (expense.receiptNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Receipt Number', expense.receiptNumber),
                ],
                if (expense.recordedBy.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Recorded By', expense.recordedBy),
                ],
                if (expense.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Notes', expense.notes),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  text: 'CLOSE',
                  onPressed: () => Navigator.pop(context),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class AddExpenseTab extends StatefulWidget {
  const AddExpenseTab({super.key});

  @override
  _AddExpenseTabState createState() => _AddExpenseTabState();
}

class _AddExpenseTabState extends State<AddExpenseTab> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedCategoryId;
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.categories.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                          validator: (v) =>
                              v == null ? 'Select category' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (UGX) *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty == true) return 'Required';
                            if (double.tryParse(v!) == null)
                              return 'Invalid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(
                                value: 'bank_transfer',
                                child: Text('Bank Transfer')),
                            DropdownMenuItem(
                                value: 'mobile_money',
                                child: Text('Mobile Money')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedPaymentMethod = v!),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null)
                              setState(() => _selectedDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'SAVE EXPENSE',
                  onPressed: () async {
                    // Check if category selected
                    if (_selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Please select a category'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Validate form
                    if (_formKey.currentState!.validate()) {
                      // Show loading message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saving expense...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      final success = await provider.createExpense({
                        'category': _selectedCategoryId,
                        'description': _descriptionController.text.trim(),
                        'amount': double.parse(_amountController.text.trim()),
                        'payment_method': _selectedPaymentMethod,
                        'payment_date':
                            _selectedDate.toIso8601String().split('T')[0],
                        'notes': _notesController.text.trim(),
                      });

                      if (success && mounted) {
                        // Clear fields
                        _descriptionController.clear();
                        _amountController.clear();
                        _notesController.clear();

                        setState(() {
                          _selectedCategoryId = null;
                          _selectedDate = DateTime.now();
                          _selectedPaymentMethod = 'cash';
                        });

                        // Reload list
                        await provider.loadExpenses();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Expense added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                provider.error ?? '❌ Failed to save expense'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExpenseCategoriesTab extends StatelessWidget {
  const ExpenseCategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No categories yet',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Categories will appear here',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.categories.length,
          itemBuilder: (context, index) {
            final category = provider.categories[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.category, color: AppColors.primaryGreen),
                ),
                title: Text(
                  category.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  category.description.isNotEmpty
                      ? category.description
                      : 'No description',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
