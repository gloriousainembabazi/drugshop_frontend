// lib/providers/prescription_provider.dart

import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../services/api_service.dart';
import 'dart:typed_data';

class PrescriptionProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Prescription> _prescriptions = [];
  List<Prescription> _pendingPrescriptions = [];

  bool _isLoading = false;
  String? _error;

  PrescriptionProvider(this._apiService);

  List<Prescription> get prescriptions => _prescriptions;
  List<Prescription> get pendingPrescriptions => _pendingPrescriptions;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPrescriptions() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getPrescriptions();

      if (response['success'] == true) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [];

        _prescriptions = data.map((e) => Prescription.fromJson(e)).toList();

        _pendingPrescriptions = _prescriptions
            .where(
                (p) => p.status == 'pending' || p.status == 'partially_filled')
            .toList();

        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load prescriptions: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // lib/providers/prescription_provider.dart

  Future<bool> createPrescription(Map<String, dynamic> prescriptionData,
      {Uint8List? imageBytes}) async {
    try {
      _isLoading = true;
      notifyListeners();

      Map<String, dynamic> response;

      // If there's an image, use multipart upload
      if (imageBytes != null && imageBytes.isNotEmpty) {
        response = await _apiService.postWithImage(
          '/api/prescriptions/',
          prescriptionData,
          imageBytes,
          'prescription_image',
        );
      } else {
        response = await _apiService.createPrescription(prescriptionData);
      }

      debugPrint('📝 CREATE PRESCRIPTION RESPONSE: $response');

      if (response['success'] == true) {
        final prescription = Prescription.fromJson(response['data']);
        _prescriptions.insert(0, prescription);

        if (prescription.status == 'pending' ||
            prescription.status == 'partially_filled') {
          _pendingPrescriptions.insert(0, prescription);
        }

        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to create prescription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ CREATE PRESCRIPTION ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePrescription(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.delete('/api/prescriptions/$id/');

      if (response['success'] == true) {
        // Remove from local lists
        _prescriptions.removeWhere((p) => p.id == id);
        _pendingPrescriptions.removeWhere((p) => p.id == id);

        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NEW: Fill prescription
  Future<Map<String, dynamic>?> fillPrescription(
      int prescriptionId, List<Map<String, dynamic>> items) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔄 FILLING PRESCRIPTION: $prescriptionId');
      debugPrint('📦 ITEMS TO FILL: $items');

      final response = await _apiService.post(
        '/api/prescriptions/$prescriptionId/fill/',
        {'items': items},
      );

      debugPrint('📦 FILL RESPONSE: $response');

      if (response['success'] == true) {
        // Refresh prescriptions to get updated data
        await loadPrescriptions();
        _error = null;
        _isLoading = false;
        notifyListeners();
        return response['data'];
      } else {
        _error = response['error'] ?? 'Failed to fill prescription';
        debugPrint('❌ FILL ERROR: $_error');
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ FILL EXCEPTION: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // NEW: Download prescription as PDF
  Future<String?> downloadPrescription(int prescriptionId) async {
    try {
      final response =
          await _apiService.get('/api/prescriptions/$prescriptionId/download/');

      if (response['success'] == true) {
        return response['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  // NEW: Upload prescription image
  Future<bool> uploadPrescriptionImage(
      int prescriptionId, String imagePath) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Note: This requires multipart form data - you may need to update ApiService
      final response = await _apiService.postFile(
        '/api/prescriptions/$prescriptionId/upload-image/',
        imagePath,
      );

      if (response['success'] == true) {
        await loadPrescriptions();
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'];
    } catch (e) {
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
