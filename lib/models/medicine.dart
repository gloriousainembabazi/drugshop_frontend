import 'package:flutter/material.dart';

class Medicine {
  final int id;
  final String name;
  final String genericName;
  final int categoryId;
  final String categoryName;
  final int supplierId;
  final String supplierName;

  // New pricing fields
  final double unitCost;
  final double wholesalePrice;
  final double retailPrice;
  final double discountPercentage;

  // Stock fields
  final int quantity;
  final int minStockLevel;
  final String unitType;
  final int unitsPerPack;
  final String barcode;

  // Expiry fields
  final DateTime expiryDate;
  final String batchNumber;
  final String description;
  final bool isLowStock;
  final bool isExpired;
  final bool isNearingExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.categoryId,
    required this.categoryName,
    required this.supplierId,
    required this.supplierName,
    required this.unitCost,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.discountPercentage,
    required this.quantity,
    required this.minStockLevel,
    required this.unitType,
    required this.unitsPerPack,
    required this.barcode,
    required this.expiryDate,
    required this.batchNumber,
    required this.description,
    required this.isLowStock,
    required this.isExpired,
    required this.isNearingExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    // Helper function to parse price values
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.parse(value);
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    // Helper function to parse int values
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is String) return int.parse(value);
      if (value is int) return value;
      if (value is double) return value.toInt();
      return 0;
    }

    return Medicine(
      id: parseInt(json['id']),
      name: json['name'] ?? '',
      genericName: json['generic_name'] ?? '',
      categoryId: parseInt(json['category']),
      categoryName: json['category_name'] ?? '',
      supplierId: parseInt(json['supplier']),
      supplierName: json['supplier_name'] ?? '',
      unitCost: parsePrice(json['unit_cost']),
      wholesalePrice: parsePrice(json['wholesale_price']),
      retailPrice: parsePrice(json['retail_price']),
      discountPercentage: parsePrice(json['discount_percentage']),
      quantity: parseInt(json['quantity']),
      minStockLevel: parseInt(json['min_stock_level']),
      unitType: json['unit_type'] ?? 'tablet',
      unitsPerPack: parseInt(json['units_per_pack']),
      barcode: json['barcode'] ?? '',
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : DateTime.now(),
      batchNumber: json['batch_number'] ?? '',
      description: json['description'] ?? '',
      isLowStock: json['is_low_stock'] ?? false,
      isExpired: json['is_expired'] ?? false,
      isNearingExpiry: json['is_nearing_expiry'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'generic_name': genericName,
      'category': categoryId,
      'supplier': supplierId,
      'unit_cost': unitCost,
      'wholesale_price': wholesalePrice,
      'retail_price': retailPrice,
      'discount_percentage': discountPercentage,
      'quantity': quantity,
      'min_stock_level': minStockLevel,
      'unit_type': unitType,
      'units_per_pack': unitsPerPack,
      'barcode': barcode,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'batch_number': batchNumber,
      'description': description,
    };
  }

  // Computed properties for backward compatibility
  double get price => retailPrice; // Use retail price as default price

  String get stockStatus {
    if (quantity <= 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Color get stockStatusColor {
    if (quantity <= 0) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  String get expiryStatus {
    if (isExpired) return 'Expired';
    if (isNearingExpiry) return 'Expiring Soon';
    return 'Valid';
  }

  Color get expiryStatusColor {
    if (isExpired) return Colors.red;
    if (isNearingExpiry) return Colors.orange;
    return Colors.green;
  }

  int get daysUntilExpiry {
    final today = DateTime.now();
    return expiryDate.difference(today).inDays;
  }

  // New computed properties
  double get totalCost => quantity * unitCost;
  double get totalRetailValue => quantity * retailPrice;
  double get totalWholesaleValue => quantity * wholesalePrice;
  double get profitMargin =>
      unitCost > 0 ? ((retailPrice - unitCost) / unitCost) * 100 : 0;
  double get profitPerUnit => retailPrice - unitCost;
}
