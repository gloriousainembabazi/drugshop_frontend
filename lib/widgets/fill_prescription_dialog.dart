// lib/widgets/fill_prescription_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prescription.dart';
import '../providers/prescription_provider.dart';

class FillPrescriptionDialog extends StatefulWidget {
  final Prescription prescription;

  const FillPrescriptionDialog({super.key, required this.prescription});

  @override
  State<FillPrescriptionDialog> createState() => _FillPrescriptionDialogState();
}

class _FillPrescriptionDialogState extends State<FillPrescriptionDialog> {
  final Map<int, TextEditingController> _quantityControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var item in widget.prescription.items) {
      if (item.remainingQuantity > 0) {
        _quantityControllers[item.id] =
            TextEditingController(text: item.remainingQuantity.toString());
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitFill() async {
    final itemsToFill = <Map<String, dynamic>>[];

    for (var item in widget.prescription.items) {
      if (item.remainingQuantity > 0) {
        final controller = _quantityControllers[item.id];
        final quantity = int.tryParse(controller?.text ?? '0') ?? 0;

        if (quantity > 0) {
          itemsToFill.add({
            'item_id': item.id,
            'quantity_filled': quantity,
          });
        }
      }
    }

    if (itemsToFill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to fill')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await context.read<PrescriptionProvider>().fillPrescription(
          widget.prescription.id,
          itemsToFill,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Prescription filled successfully! Status: ${result['status']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<PrescriptionProvider>().error ??
              'Failed to fill prescription'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fill Prescription',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'RX: ${widget.prescription.prescriptionId}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Patient: ${widget.prescription.patientName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.prescription.items.length,
                itemBuilder: (context, index) {
                  final item = widget.prescription.items[index];
                  final remaining = item.remainingQuantity;

                  if (remaining <= 0) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.green.shade50,
                      child: ListTile(
                        leading:
                            const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(item.medicineName),
                        subtitle: const Text('Fully filled'),
                        trailing: Text(
                            '${item.filledQuantity}/${item.prescribedQuantity}'),
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.medicineName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Prescribed: ${item.prescribedQuantity} | Already filled: ${item.filledQuantity}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quantityControllers[item.id],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity to fill',
                                    hintText: 'Max: $remaining',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  _quantityControllers[item.id]?.text =
                                      remaining.toString();
                                  setState(() {});
                                },
                                child: const Text('MAX'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFill,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('FILL NOW'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
