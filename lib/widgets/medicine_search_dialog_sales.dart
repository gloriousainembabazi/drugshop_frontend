// lib/widgets/medicine_search_dialog_sales.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class MedicineSearchDialogSales extends StatefulWidget {
  final Function(Medicine) onSelect;

  const MedicineSearchDialogSales({super.key, required this.onSelect});

  @override
  State<MedicineSearchDialogSales> createState() =>
      _MedicineSearchDialogSalesState();
}

class _MedicineSearchDialogSalesState extends State<MedicineSearchDialogSales> {
  String _searchQuery = '';
  List<Medicine> _filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MedicineProvider>().loadMedicines();
      }
    });
  }

  void _filterMedicines(List<Medicine> medicines, String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMedicines = medicines;
      } else {
        _filteredMedicines = medicines
            .where((m) =>
                m.name.toLowerCase().contains(query.toLowerCase()) ||
                m.genericName.toLowerCase().contains(query.toLowerCase()) ||
                m.batchNumber.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);

        // Filter out expired medicines
        final availableMedicines = provider.medicines
            .where(
                (m) => !m.expiryDate.isBefore(todayMidnight) && m.quantity > 0)
            .toList();

        if (_filteredMedicines.isEmpty && availableMedicines.isNotEmpty) {
          _filteredMedicines = availableMedicines;
        }

        if (availableMedicines.isEmpty && provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (availableMedicines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 64, color: Colors.orange.shade300),
                const SizedBox(height: 16),
                Text(
                  'No available medicines',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'All medicines may be expired or out of stock',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search medicine by name, generic, or batch...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            _filterMedicines(availableMedicines, ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _filterMedicines(availableMedicines, value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = _filteredMedicines[index];
                  final isLowStock =
                      medicine.quantity <= medicine.minStockLevel;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isLowStock ? Colors.orange.shade50 : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isLowStock ? Colors.orange : Colors.green,
                        child: Text(
                          medicine.quantity.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        medicine.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock: ${medicine.quantity} | Price: UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Expires: ${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  medicine.isExpired ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: isLowStock
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(medicine);
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
}
