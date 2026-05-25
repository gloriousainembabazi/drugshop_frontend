class StockCount {
  final int id;
  final String countId;
  final DateTime countDate;
  final String countedBy;
  final String? verifiedBy;
  final String status;
  final String notes;
  final List<StockCountItem> items;

  StockCount({
    required this.id,
    required this.countId,
    required this.countDate,
    required this.countedBy,
    this.verifiedBy,
    required this.status,
    required this.notes,
    required this.items,
  });

  factory StockCount.fromJson(Map<String, dynamic> json) {
    return StockCount(
      id: json['id'] ?? 0,
      countId: json['count_id'] ?? '',
      countDate: DateTime.parse(json['count_date']),
      countedBy: json['counted_by'] ?? '',
      verifiedBy: json['verified_by'],
      status: json['status'] ?? 'draft',
      notes: json['notes'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => StockCountItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class StockCountItem {
  final int id;
  final String medicineName;
  final int systemQuantity;
  final int physicalQuantity;
  final String notes;

  StockCountItem({
    required this.id,
    required this.medicineName,
    required this.systemQuantity,
    required this.physicalQuantity,
    required this.notes,
  });

  factory StockCountItem.fromJson(Map<String, dynamic> json) {
    return StockCountItem(
      id: json['medicine'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      systemQuantity: json['system_quantity'] ?? 0,
      physicalQuantity: json['physical_quantity'] ?? 0,
      notes: json['notes'] ?? '',
    );
  }

  int get variance => physicalQuantity - systemQuantity;
}
