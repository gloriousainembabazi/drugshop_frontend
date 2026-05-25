// lib/widgets/payment_dialog.dart

import 'package:flutter/material.dart';
import '../../models/credit.dart';
import '../../widgets/custom_button.dart';

class PaymentDialog extends StatefulWidget {
  final CreditSale creditSale;
  final Function(double, String, String) onConfirm;

  const PaymentDialog({
    super.key,
    required this.creditSale,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';
  double _maxAmount = 0;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash', 'icon': Icons.money},
    {'value': 'mobile_money', 'label': 'Mobile Money', 'icon': Icons.phone_android},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': Icons.account_balance},
    {'value': 'cheque', 'label': 'Cheque', 'icon': Icons.assignment},
  ];

  @override
  void initState() {
    super.initState();
    _maxAmount = widget.creditSale.balance;
    _amountController.text = _maxAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Payment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Credit ID: ${widget.creditSale.creditId}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Customer: ${widget.creditSale.customerName}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Outstanding Balance: UGX ${_maxAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'UGX ',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                if (amount > _maxAmount) {
                  _amountController.text = _maxAmount.toStringAsFixed(0);
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('Payment Method'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _paymentMethods.map((method) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(method['icon'], size: 16),
                      const SizedBox(width: 4),
                      Text(method['label']),
                    ],
                  ),
                  selected: _paymentMethod == method['value'],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _paymentMethod = method['value']);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
                  child: CustomButton(
                    text: 'RECORD PAYMENT',
                    onPressed: () {
                      final amount = double.tryParse(_amountController.text) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter valid amount')),
                        );
                        return;
                      }
                      widget.onConfirm(amount, _paymentMethod, _notesController.text);
                      Navigator.pop(context);
                    },
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
