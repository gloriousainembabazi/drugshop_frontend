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
  final String? customerName;
  final String? notes;
  final String? paymentMethod;
  final String saleType;
  final List<dynamic> items;

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

  // COMPLETELY AGGRESSIVE cleaning method
  static String _cleanString(String input, {DateTime? fallbackDate}) {
    if (input.isEmpty) {
      return 'SALE-${fallbackDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    }
    
    // These are COMPLETE GARBAGE patterns - if ANY match, replace entirely
    final garbagePatterns = [
      'FIGHT', 'COVERED', 'FIXTELS', 'PAIRS', 'INVOICE', 'OFFERED', 'BY',
      'ILLIOTT', 'OVERFORD', 'PRICE',
      'fight', 'covered', 'fixtels', 'pairs', 'invoice', 'offered', 'by',
      'illiott', 'overford', 'price',
      'SALE-000', 'SALE-', 'sale-'
    ];
    
    // Check if this is completely garbage data
    String upperInput = input.toUpperCase();
    bool isCompleteGarbage = false;
    
    for (var pattern in garbagePatterns) {
      String upperPattern = pattern.toUpperCase();
      if (upperInput.contains(upperPattern)) {
        isCompleteGarbage = true;
        break;
      }
    }
    
    // If it contains garbage words
    if (upperInput.contains('FIGHT') || 
        upperInput.contains('COVERED') || 
        upperInput.contains('FIXTELS') ||
        upperInput.contains('PAIRS') ||
        upperInput.contains('INVOICE') ||
        upperInput.contains('ILLIOTT') ||
        upperInput.contains('OVERFORD') ||
        upperInput.contains('PRICE')) {
      isCompleteGarbage = true;
    }
    
    // If it's garbage, generate a completely new ID
    if (isCompleteGarbage) {
      return 'SALE-${fallbackDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Return the original if it looks like a valid ID
    if (input.startsWith('SALE-') && input.length > 5) {
      // Extract just the SALE-XXX part, remove any trailing numbers
      final match = RegExp(r'SALE-\d+').firstMatch(input);
      if (match != null) {
        return match.group(0)!;
      }
      return input;
    }
    
    // Last resort - generate new ID
    return 'SALE-${fallbackDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Get the sale date first (used for fallback ID)
    DateTime saleDate = json['sale_date'] != null 
        ? DateTime.parse(json['sale_date']) 
        : DateTime.now();
    
    // AGGRESSIVELY clean the sale ID
    String rawSaleId = json['sale_id']?.toString() ?? '';
    String cleanSaleId = _cleanString(rawSaleId, fallbackDate: saleDate);
    
    // Clean customer name - if it contains garbage, set to null
    String? cleanCustomerName;
    if (json['customer_name'] != null) {
      String rawCustomerName = json['customer_name'].toString();
      String upperName = rawCustomerName.toUpperCase();
      if (upperName.contains('FIGHT') || 
          upperName.contains('COVERED') || 
          upperName.contains('FIXTELS') ||
          upperName.contains('PAIRS') ||
          upperName.contains('INVOICE') ||
          upperName.contains('ILLIOTT') ||
          upperName.contains('OVERFORD') ||
          upperName.contains('PRICE')) {
        cleanCustomerName = null;
      } else {
        cleanCustomerName = rawCustomerName;
      }
    }
    
    // Clean payment method - if it contains garbage, set to 'Cash'
    String cleanPaymentMethod = 'Cash';
    if (json['payment_method'] != null) {
      String rawPaymentMethod = json['payment_method'].toString();
      String upperMethod = rawPaymentMethod.toUpperCase();
      if (!(upperMethod.contains('FIGHT') || 
             upperMethod.contains('COVERED') || 
             upperMethod.contains('FIXTELS') ||
             upperMethod.contains('PAIRS') ||
             upperMethod.contains('INVOICE') ||
             upperMethod.contains('ILLIOTT') ||
             upperMethod.contains('OVERFORD') ||
             upperMethod.contains('PRICE'))) {
        cleanPaymentMethod = rawPaymentMethod;
      }
    }
    
    return Sale(
      id: json['id'] ?? 0,
      saleId: cleanSaleId,
      medicineId: json['medicine'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      userId: json['user'] ?? 0,
      staffName: json['staff_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: _parseDouble(json['unit_price']),
      totalPrice: _parseDouble(json['total_price']),
      saleDate: saleDate,
      customerName: cleanCustomerName,
      notes: json['notes'],
      paymentMethod: cleanPaymentMethod,
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
  final String _originalSaleId;
  final List<Sale> items;
  final DateTime saleDate;
  final String? _originalCustomerName;
  final String staffName;
  final String? _originalPaymentMethod;

  SaleGroup({
    required String saleId,
    required this.items,
    required this.saleDate,
    required String? customerName,
    required this.staffName,
    required String? paymentMethod,
  }) : _originalSaleId = saleId,
       _originalCustomerName = customerName,
       _originalPaymentMethod = paymentMethod;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get medicineCount => items.length;

  // COMPLETELY CLEAN SALE ID - removes any extra numbers
  String get cleanSaleId {
    String rawId = _originalSaleId;
    
    // Remove any newline characters and extra spaces
    rawId = rawId.replaceAll('\n', ' ').trim();
    
    // List of garbage patterns
    final garbagePatterns = [
      'FIGHT', 'COVERED', 'FIXTELS', 'PAIRS', 'INVOICE', 'OFFERED', 
      'ILLIOTT', 'OVERFORD', 'PRICE', 'BY',
      'fight', 'covered', 'fixtels', 'pairs', 'invoice', 'offered',
      'illiott', 'overford', 'price', 'by'
    ];
    
    // Check for garbage
    for (var pattern in garbagePatterns) {
      if (rawId.contains(pattern)) {
        return 'SALE-${saleDate.millisecondsSinceEpoch}';
      }
    }
    
    // Extract just the SALE-XXX part (remove trailing numbers like "924250")
    final match = RegExp(r'SALE-\d+').firstMatch(rawId);
    if (match != null) {
      return match.group(0)!;
    }
    
    // If it starts with SALE- but has extra, try to clean it
    if (rawId.startsWith('SALE-')) {
      // Keep only the first part until a space or newline
      final parts = rawId.split(RegExp(r'[\s\n]'));
      if (parts.isNotEmpty && parts[0].startsWith('SALE-')) {
        return parts[0];
      }
    }
    
    // If too short or invalid, generate new
    if (rawId.length < 5) {
      return 'SALE-${saleDate.millisecondsSinceEpoch}';
    }
    
    return rawId;
  }

  // Regular getter for backwards compatibility
  String get saleId => cleanSaleId;

  // Clean customer name
  String get cleanCustomerName {
    if (_originalCustomerName == null) return 'Walk-in Customer';
    
    String rawName = _originalCustomerName!;
    
    final garbagePatterns = [
      'FIGHT', 'COVERED', 'FIXTELS', 'PAIRS', 'INVOICE', 'OFFERED',
      'ILLIOTT', 'OVERFORD', 'PRICE', 'BY',
      'fight', 'covered', 'fixtels', 'pairs', 'invoice', 'offered',
      'illiott', 'overford', 'price', 'by'
    ];
    
    for (var pattern in garbagePatterns) {
      if (rawName.contains(pattern)) {
        return 'Walk-in Customer';
      }
    }
    
    if (rawName.length < 2) {
      return 'Walk-in Customer';
    }
    
    return rawName;
  }

  String get customerName => cleanCustomerName;

  // Clean payment method
  String get cleanPaymentMethod {
    if (_originalPaymentMethod == null) return 'Cash';
    
    String rawMethod = _originalPaymentMethod!;
    
    final garbagePatterns = [
      'FIGHT', 'COVERED', 'FIXTELS', 'PAIRS', 'INVOICE', 'OFFERED',
      'ILLIOTT', 'OVERFORD', 'PRICE', 'BY',
      'fight', 'covered', 'fixtels', 'pairs', 'invoice', 'offered',
      'illiott', 'overford', 'price', 'by'
    ];
    
    for (var pattern in garbagePatterns) {
      if (rawMethod.contains(pattern)) {
        return 'Cash';
      }
    }
    
    if (rawMethod.length < 2) {
      return 'Cash';
    }
    
    return rawMethod;
  }

  String get paymentMethod => cleanPaymentMethod;
}