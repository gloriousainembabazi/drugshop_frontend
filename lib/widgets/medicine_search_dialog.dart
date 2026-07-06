// lib/widgets/medicine_search_dialog.dart

import 'package:flutter/material.dart';
import '../../models/medicine.dart';

class MedicineSearchDialog extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(Medicine) onSelect;

  const MedicineSearchDialog({
    super.key,
    required this.medicines,
    required this.onSelect,
  });

  @override
  State<MedicineSearchDialog> createState() => _MedicineSearchDialogState();
}

class _MedicineSearchDialogState extends State<MedicineSearchDialog> {
  String _searchQuery = '';
  List<Medicine> _filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    _filteredMedicines = widget.medicines;
  }

  void _filterMedicines(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMedicines = widget.medicines;
      } else {
        _filteredMedicines = widget.medicines
            .where((medicine) =>
                medicine.name.toLowerCase().contains(query.toLowerCase()) ||
                medicine.genericName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                medicine.batchNumber
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Medicine',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search medicine...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterMedicines,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = _filteredMedicines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Batch: ${medicine.batchNumber}'),
                          Text(
                              'Stock: ${medicine.quantity} | Price: UGX ${medicine.retailPrice.toStringAsFixed(0)}'),
                        ],
                      ),
                      trailing: medicine.isLowStock
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : medicine.isExpired
                              ? const Icon(Icons.dangerous, color: Colors.red)
                              : null,
                      onTap: () {
                        if (medicine.quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Medicine out of stock')),
                          );
                          return;
                        }
                        if (medicine.isExpired) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Medicine is expired')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        widget.onSelect(medicine);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
