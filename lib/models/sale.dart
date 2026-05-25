import 'medicine.dart';

class Sale {
  final int id;
  final String saleId;
  final int medicineId;
  final String medicineName;
  final int userId;
  final String staffName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime saleDate;
  final String? customerName;  // Keep as nullable
  final String? notes;         // Keep as nullable
  final String? paymentMethod; // Keep as nullable
  final String saleType;
  final List<dynamic> items;   // Change to List<dynamic> to handle empty lists

  Sale({
    required this.id,
    required this.saleId,
    required this.medicineId,
    required this.medicineName,
    required this.userId,
    required this.staffName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.saleDate,
    this.customerName,
    this.notes,
    this.paymentMethod,
    this.saleType = 'retail',
    this.items = const [],
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] ?? 0,
      saleId: json['sale_id'] ?? '',
      medicineId: json['medicine'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      userId: json['user'] ?? 0,
      staffName: json['staff_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: _parseDouble(json['unit_price']),
      totalPrice: _parseDouble(json['total_price']),
      saleDate: json['sale_date'] != null 
          ? DateTime.parse(json['sale_date']) 
          : DateTime.now(),
      customerName: json['customer_name'],  // Can be null
      notes: json['notes'],                 // Can be null
      paymentMethod: json['payment_method'] ?? 'Cash',
      saleType: json['sale_type'] ?? 'retail',
      items: json['items'] != null && json['items'] is List 
          ? json['items'] 
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'medicine': medicineId,
      'user': userId,
      'quantity': quantity,
      'notes': notes,
      'customer_name': customerName,
      'payment_method': paymentMethod,
      'sale_type': saleType,
    };
  }
}

// Cart item for temporary storage during sale creation
class CartItem {
  final Medicine medicine;
  int quantity;
  String saleType;

  CartItem({
    required this.medicine,
    required this.quantity,
    this.saleType = 'retail',
  });

  double get price => saleType == 'wholesale' ? medicine.wholesalePrice : medicine.retailPrice;
  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicine.id,
      'quantity': quantity,
      'price': price,
    };
  }
}

// Sale group for displaying grouped sales
class SaleGroup {
  final String saleId;
  final List<Sale> items;
  final DateTime saleDate;
  final String? customerName;
  final String staffName;
  final String? paymentMethod;

  SaleGroup({
    required this.saleId,
    required this.items,
    required this.saleDate,
    this.customerName,
    required this.staffName,
    this.paymentMethod,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get medicineCount => items.length;
}
