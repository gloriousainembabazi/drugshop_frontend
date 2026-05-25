// lib/models/credit.dart

class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String address;
  final String idNumber;
  final double totalCredit;
  final double outstandingBalance;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.address,
    required this.idNumber,
    required this.totalCredit,
    required this.outstandingBalance,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return Customer(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      idNumber: json['id_number'] ?? '',
      totalCredit: parseDouble(json['total_credit']),
      outstandingBalance: parseDouble(json['outstanding_balance']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
}

class CreditSaleItem {
  final int id;
  final int medicineId;
  final String medicineName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  CreditSaleItem({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CreditSaleItem.fromJson(Map<String, dynamic> json) {
    return CreditSaleItem(
      id: json['id'] ?? 0,
      medicineId: json['medicine'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: double.parse(json['unit_price']?.toString() ?? '0'),
      totalPrice: double.parse(json['total_price']?.toString() ?? '0'),
    );
  }
}

class CreditSale {
  final int id;
  final String creditId;
  final int customerId;
  final String customerName;
  final List<CreditSaleItem> items;
  final double totalAmount;
  final double amountPaid;
  final DateTime dueDate;
  final String status;
  final String notes;
  final int issuedBy;
  final String issuedByName;
  final DateTime createdAt;

  CreditSale({
    required this.id,
    required this.creditId,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.issuedBy,
    required this.issuedByName,
    required this.createdAt,
  });

  factory CreditSale.fromJson(Map<String, dynamic> json) {
    List<CreditSaleItem> items = [];
    
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => CreditSaleItem.fromJson(item))
          .toList();
    }

    return CreditSale(
      id: json['id'] ?? 0,
      creditId: json['credit_id'] ?? '',
      customerId: json['customer'] ?? 0,
      customerName: json['customer_name'] ?? '',
      items: items,
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0'),
      amountPaid: double.parse(json['amount_paid']?.toString() ?? '0'),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      notes: json['notes'] ?? '',
      issuedBy: json['issued_by'] ?? 0,
      issuedByName: json['issued_by_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  double get balance => totalAmount - amountPaid;
  bool get isOverdue => DateTime.now().isAfter(dueDate) && balance > 0;
}
