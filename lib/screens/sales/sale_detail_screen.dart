// lib/screens/sales/sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sale.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  _SaleDetailScreenState createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  SaleGroup? _saleGroup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    setState(() => _isLoading = true);
    
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final saleGroup = await saleProvider.getSaleGroupById(widget.saleId);
    
    setState(() {
      _saleGroup = saleGroup;
      _isLoading = false;
    });
  }

  Future<void> _printReceipt() async {
    if (_saleGroup == null) return;
    
    try {
      await PdfService.generateSaleReceipt(_saleGroup!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to clean sale ID and remove extra numbers
  String _getCleanSaleId() {
    String rawId = _saleGroup!.saleId;
    
    // Remove any newline characters and take only the first line
    if (rawId.contains('\n')) {
      rawId = rawId.split('\n').first;
    }
    
    // Remove any extra numbers after space
    if (rawId.contains(' ')) {
      rawId = rawId.split(' ').first;
    }
    
    // Extract just the SALE-XXX pattern
    final match = RegExp(r'SALE-\d+').firstMatch(rawId);
    if (match != null) {
      return match.group(0)!;
    }
    
    // Clean from garbage
    if (rawId.contains('FIGHT') || 
        rawId.contains('COVERED') || 
        rawId.contains('FIXTELS') ||
        rawId.contains('INVOICE') ||
        rawId.contains('ILLIOTT') ||
        rawId.contains('OVERFORD') ||
        rawId.contains('PRICE') ||
        rawId.contains('924250')) {
      return 'SALE-${_saleGroup!.saleDate.millisecondsSinceEpoch}';
    }
    
    return rawId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReceipt,
            tooltip: 'Print Receipt',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSaleDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _saleGroup == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sale not found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // FIX: Wrapped in Expanded to stop horizontal layout overflow
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'His Grace Drugshop',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.primaryColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sale Receipt',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12), // Keeps space between title and chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getCleanSaleId(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),

                              _buildInfoRow(
                                'Date:',
                                '${_saleGroup!.saleDate.day}/${_saleGroup!.saleDate.month}/${_saleGroup!.saleDate.year} ${_saleGroup!.saleDate.hour}:${_saleGroup!.saleDate.minute.toString().padLeft(2, '0')}',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Staff:',
                                _saleGroup!.staffName,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Customer:',
                                _saleGroup!.cleanCustomerName,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Payment:',
                                _saleGroup!.cleanPaymentMethod,
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Medicine',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Qty',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Price',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Total',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              ..._saleGroup!.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.medicineName,
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'UGX ${item.unitPrice.toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'UGX ${item.totalPrice.toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL AMOUNT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'UGX ${_saleGroup!.totalAmount.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Items:',
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        Text(
                                          '${_saleGroup!.totalItems} units',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Medicine Types:',
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        Text(
                                          '${_saleGroup!.medicineCount} different',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),
                              
                              Text(
                                'Thank you for your purchase!',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}