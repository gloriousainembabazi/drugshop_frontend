// lib/models/prescription.dart

import 'package:flutter/material.dart';

class Prescription {
  final int id;
  final String prescriptionId;
  final String patientName;
  final int? patientAge;
  final String patientPhone;
  final String doctorName;
  final String doctorLicense;
  final String hospital;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String diagnosis;
  final String status;
  final String notes;
  final String? prescriptionImage;
  final String createdBy; // Staff name who created this prescription
  final DateTime createdAt;
  final List<PrescriptionItem> items;

  Prescription({
    required this.id,
    required this.prescriptionId,
    required this.patientName,
    this.patientAge,
    required this.patientPhone,
    required this.doctorName,
    required this.doctorLicense,
    required this.hospital,
    required this.issueDate,
    required this.expiryDate,
    required this.diagnosis,
    required this.status,
    required this.notes,
    this.prescriptionImage,
    required this.createdBy,
    required this.createdAt,
    required this.items,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    List<PrescriptionItem> parsedItems = [];

    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => PrescriptionItem.fromJson(item))
          .toList();
    }

    // Get created by information
    String createdBy = '';
    if (json['created_by_name'] != null) {
      createdBy = json['created_by_name'].toString();
    } else if (json['created_by'] != null) {
      createdBy = json['created_by'].toString();
    }

    return Prescription(
      id: json['id'] ?? 0,
      prescriptionId: json['prescription_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientAge: json['patient_age'] is String
          ? int.tryParse(json['patient_age'])
          : json['patient_age'],
      patientPhone: json['patient_phone'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorLicense: json['doctor_license'] ?? '',
      hospital: json['hospital'] ?? '',
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'])
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : DateTime.now(),
      diagnosis: json['diagnosis'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'] ?? '',
      prescriptionImage: json['prescription_image'],
      createdBy: createdBy,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      items: parsedItems,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'filled':
        return 'Filled';
      case 'partially_filled':
        return 'Partially Filled';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'filled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'partially_filled':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class PrescriptionItem {
  final int id;
  final int medicineId;
  final String medicineName;
  final int prescribedQuantity;
  final int filledQuantity;
  final String dosageInstructions;
  final String duration;

  PrescriptionItem({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.prescribedQuantity,
    required this.filledQuantity,
    required this.dosageInstructions,
    required this.duration,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] ?? 0,
      medicineId: json['medicine'] ?? json['medicine_id'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      prescribedQuantity: json['prescribed_quantity'] ?? 0,
      filledQuantity: json['filled_quantity'] ?? 0,
      dosageInstructions: json['dosage_instructions'] ?? '',
      duration: json['duration'] ?? '',
    );
  }

  int get remainingQuantity => prescribedQuantity - filledQuantity;
  bool get isFullyFilled => filledQuantity >= prescribedQuantity;
}
