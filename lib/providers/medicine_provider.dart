// lib/providers/medicine_provider.dart

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/category.dart';
import '../models/supplier.dart';

import '../services/api_service.dart';

class MedicineProvider extends ChangeNotifier {
  final ApiService _apiService;

  final List<Medicine> _medicines = [];
  List<Medicine> _lowStockMedicines = [];
  List<Medicine> _expiringMedicines = [];
  List<Medicine> _expiredMedicines = [];

  List<Category> _categories = [];
  List<Supplier> _suppliers = [];

  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  bool _hasMorePages = true;

  MedicineProvider(this._apiService);

  // GETTERS

  List<Medicine> get medicines => _medicines;

  List<Medicine> get lowStockMedicines => _lowStockMedicines;

  List<Medicine> get expiringMedicines => _expiringMedicines;

  List<Medicine> get expiredMedicines => _expiredMedicines;

  List<Category> get categories => _categories;

  List<Supplier> get suppliers => _suppliers;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // LOAD MEDICINES

  Future<void> loadMedicines({
    bool refresh = false,
  }) async {
    if (refresh) {
      _medicines.clear();
      _currentPage = 1;
      _hasMorePages = true;
    }

    if (_isLoading || !_hasMorePages) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getMedicines(
        params: {
          'page': _currentPage,
        },
      );

      if (response['success'] == true) {
        final data = response['data'];

        List<dynamic> medicinesData = [];

        // PAGINATED RESPONSE
        if (data is Map && data['results'] != null) {
          medicinesData = data['results'] is List ? data['results'] : [];
          _hasMorePages = data['next'] != null;
        }
        // NORMAL ARRAY RESPONSE
        else if (data is List) {
          medicinesData = data;
          _hasMorePages = false;
        }

        final newMedicines = medicinesData
            .map(
              (json) => Medicine.fromJson(json),
            )
            .toList();

        _medicines.addAll(newMedicines);

        if (newMedicines.isNotEmpty) {
          _currentPage++;
        }

        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load medicines: $e';
      print('Medicine Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // LOW STOCK

  Future<void> loadLowStockMedicines() async {
    try {
      final response = await _apiService.getLowStockMedicines();

      if (response['success'] == true) {
        final data = response['data'];

        List<dynamic> medicinesData = [];

        if (data is List) {
          medicinesData = data;
        } else if (data is Map && data['medicines'] != null) {
          medicinesData = data['medicines'] is List ? data['medicines'] : [];
        }

        _lowStockMedicines = medicinesData
            .map(
              (json) => Medicine.fromJson(json),
            )
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('Low Stock Error: $e');
    }
  }

  // EXPIRING

  Future<void> loadExpiringMedicines() async {
    try {
      final response = await _apiService.getExpiringMedicines();

      if (response['success'] == true) {
        final data = response['data'];

        List<dynamic> medicinesData = [];

        if (data is List) {
          medicinesData = data;
        } else if (data is Map && data['medicines'] != null) {
          medicinesData = data['medicines'] is List ? data['medicines'] : [];
        }

        _expiringMedicines = medicinesData
            .map(
              (json) => Medicine.fromJson(json),
            )
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('Expiring Error: $e');
    }
  }

  // EXPIRED

  Future<void> loadExpiredMedicines() async {
    try {
      final response = await _apiService.getExpiredMedicines();

      if (response['success'] == true) {
        final data = response['data'];

        List<dynamic> medicinesData = [];

        if (data is List) {
          medicinesData = data;
        } else if (data is Map && data['medicines'] != null) {
          medicinesData = data['medicines'] is List ? data['medicines'] : [];
        }

        _expiredMedicines = medicinesData
            .map(
              (json) => Medicine.fromJson(json),
            )
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('Expired Error: $e');
    }
  }

  // CATEGORIES

  Future<void> loadCategories() async {
    try {
      final response = await _apiService.getCategories();

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] is List ? response['data'] : [];

        _categories = data
            .map(
              (json) => Category.fromJson(json),
            )
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('Category Error: $e');
    }
  }

  // SUPPLIERS

  Future<void> loadSuppliers() async {
    try {
      final response = await _apiService.getSuppliers();

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] is List ? response['data'] : [];

        _suppliers = data
            .map(
              (json) => Supplier.fromJson(json),
            )
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('Supplier Error: $e');
    }
  }

  // GET SINGLE MEDICINE

  Future<Medicine?> getMedicineById(int id) async {
    try {
      final response = await _apiService.getMedicine(id);

      if (response['success'] == true) {
        return Medicine.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('Get Medicine Error: $e');
      return null;
    }
  }

  // CREATE

  Future<bool> addMedicine(Map<String, dynamic> medicineData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.createMedicine(medicineData);

      if (response['success'] == true) {
        final medicine = Medicine.fromJson(response['data']);

        _medicines.insert(0, medicine);

        _error = null;

        _isLoading = false;
        notifyListeners();

        return true;
      }

      _error = response['error'];
    } catch (e) {
      _error = 'Failed to add medicine: $e';
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  // UPDATE

  Future<bool> updateMedicine(int id, Map<String, dynamic> medicineData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.updateMedicine(id, medicineData);

      if (response['success'] == true) {
        final updatedMedicine = Medicine.fromJson(response['data']);

        final index = _medicines.indexWhere((m) => m.id == id);

        if (index != -1) {
          _medicines[index] = updatedMedicine;
        }

        _error = null;

        _isLoading = false;
        notifyListeners();

        return true;
      }

      _error = response['error'];
    } catch (e) {
      _error = 'Failed to update medicine: $e';
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  // DELETE

  Future<bool> deleteMedicine(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.deleteMedicine(id);

      if (response['success'] == true) {
        _medicines.removeWhere((m) => m.id == id);
        _lowStockMedicines.removeWhere((m) => m.id == id);
        _expiredMedicines.removeWhere((m) => m.id == id);
        _expiringMedicines.removeWhere((m) => m.id == id);

        _error = null;

        _isLoading = false;
        notifyListeners();

        return true;
      }

      _error = response['error'];
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  // REFRESH ALL

  Future<void> refreshAll() async {
    await Future.wait([
      loadMedicines(refresh: true),
      loadLowStockMedicines(),
      loadExpiringMedicines(),
      loadExpiredMedicines(),
      loadCategories(),
      loadSuppliers(),
    ]);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
