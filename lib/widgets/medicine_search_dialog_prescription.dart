// lib/widgets/medicine_search_dialog_prescription.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class MedicineSearchDialogPrescription extends StatelessWidget {
  final Function(Medicine) onSelect;

  const MedicineSearchDialogPrescription({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        final medicines = provider.medicines.where((m) => 
          !m.isExpired && m.quantity > 0
        ).toList();

        if (medicines.isEmpty && provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search medicine by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                // Filtering handled by consumer rebuild
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  final isLowStock = medicine.quantity <= medicine.minStockLevel;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isLowStock ? Colors.orange.shade50 : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLowStock ? Colors.orange : Colors.green,
                        child: Text(
                          medicine.quantity.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(
                        medicine.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Stock: ${medicine.quantity} | Price: UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isLowStock ? const Icon(Icons.warning, color: Colors.orange) : null,
                      onTap: () {
                        onSelect(medicine);
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
