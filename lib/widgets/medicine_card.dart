import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if medicine is expired and should be disabled
    final bool isExpired = medicine.isExpired;
    
    return Opacity(
      opacity: isExpired ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isExpired 
              ? BorderSide(color: Colors.red.shade300, width: 1)
              : BorderSide.none,
        ),
        color: isExpired ? Colors.grey.shade100 : null,
        child: InkWell(
          onTap: onTap, // CHANGE THIS LINE - Always allow tap, even for expired medicines
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Medicine Icon with Status
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isExpired 
                        ? Colors.red.withOpacity(0.1)
                        : medicine.stockStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isExpired
                        ? Icons.dangerous
                        : medicine.isLowStock
                            ? Icons.warning
                            : Icons.medical_services,
                    color: isExpired ? Colors.red : medicine.stockStatusColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),

                // Medicine Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isExpired ? TextDecoration.lineThrough : null,
                          color: isExpired ? Colors.grey : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'EXPIRED',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: medicine.stockStatusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                medicine.stockStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: medicine.stockStatusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: medicine.expiryStatusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                medicine.expiryStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: medicine.expiryStatusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch: ${medicine.batchNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price and Stock
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'UGX ${medicine.retailPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.grey : AppColors.primaryGreen,
                        decoration: isExpired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${medicine.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isExpired ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      medicine.unitType,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
