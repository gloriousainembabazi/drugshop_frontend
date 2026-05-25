// lib/providers/stock_provider.dart

import 'package:flutter/material.dart';
import '../models/stock_count.dart';
import '../services/api_service.dart';

class StockProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<StockCount> _stockCounts = [];

  StockCount? _currentStockCount;

  bool _isLoading = false;
  String? _error;

  StockProvider(this._apiService);

  List<StockCount> get stockCounts => _stockCounts;

  StockCount? get currentStockCount => _currentStockCount;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStockCounts() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getStockCounts();

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] is List ? response['data'] : [];

        _stockCounts = data.map((e) => StockCount.fromJson(e)).toList();

        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load stock counts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createStockCount(Map<String, dynamic> countData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.createStockCount(countData);

      if (response['success'] == true) {
        _stockCounts.insert(0, StockCount.fromJson(response['data']));

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

  Future<bool> submitStockCount(int id, Map<String, dynamic> submitData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.submitStockCount(id, submitData);

      if (response['success'] == true) {
        await loadStockCounts();

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

  void startNewStockCount() {
    _currentStockCount = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
