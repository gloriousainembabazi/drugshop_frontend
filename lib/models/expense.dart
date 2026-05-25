// lib/models/expense.dart

class Expense {
  final int id;
  final String expenseId;
  final String category;
  final String? supplier;
  final String description;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String recordedBy;      // Staff name who recorded this expense
  final String receiptNumber;
  final String notes;

  Expense({
    required this.id,
    required this.expenseId,
    required this.category,
    this.supplier,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.recordedBy,
    required this.receiptNumber,
    required this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Get recorded by information
    String recordedBy = '';
    if (json['recorded_by_name'] != null) {
      recordedBy = json['recorded_by_name'].toString();
    } else if (json['recorded_by'] != null) {
      recordedBy = json['recorded_by'].toString();
    }

    return Expense(
      id: json['id'] ?? 0,
      expenseId: json['expense_id'] ?? '',
      category: json['category_name'] ?? '',
      supplier: json['supplier_name'],
      description: json['description'] ?? '',
      amount: parseAmount(json['amount']),
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : DateTime.now(),
      recordedBy: recordedBy,
      receiptNumber: json['receipt_number'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
  
  String get formattedAmount => 'UGX ${amount.toStringAsFixed(0)}';
  
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'mobile_money':
        return 'Mobile Money';
      case 'credit':
        return 'Credit';
      case 'cheque':
        return 'Cheque';
      default:
        return paymentMethod;
    }
  }
}

class ExpenseCategory {
  final int id;
  final String name;
  final String description;
  final DateTime createdAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
