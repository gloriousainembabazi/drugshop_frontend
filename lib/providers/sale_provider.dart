import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class SaleProvider extends ChangeNotifier {
  final ApiService _apiService;

  final List<Sale> _sales = [];
  List<Sale> _dailySales = [];
  Map<String, SaleGroup> _saleGroups = {};

  double _dailyTotal = 0;
  int _dailyTransactions = 0;

  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  bool _hasMorePages = true;

  SaleProvider(this._apiService);

  List<Sale> get sales => _sales;
  List<Sale> get dailySales => _dailySales;
  List<SaleGroup> get saleGroups => _saleGroups.values.toList();
  double get dailyTotal => _dailyTotal;
  int get dailyTransactions => _dailyTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _groupSales() {
    final Map<String, List<Sale>> grouped = {};
    for (var sale in _sales) {
      if (!grouped.containsKey(sale.saleId)) {
        grouped[sale.saleId] = [];
      }
      grouped[sale.saleId]!.add(sale);
    }
    
    _saleGroups.clear();
    for (var entry in grouped.entries) {
      final firstSale = entry.value.first;
      _saleGroups[entry.key] = SaleGroup(
        saleId: entry.key,
        items: entry.value,
        saleDate: firstSale.saleDate,
        customerName: firstSale.customerName,
        staffName: firstSale.staffName,
        paymentMethod: firstSale.paymentMethod,
      );
    }
  }

  Future<void> loadSales({bool refresh = false}) async {
    if (refresh) {
      _sales.clear();
      _saleGroups.clear();
      _currentPage = 1;
      _hasMorePages = true;
    }

    if (_isLoading || !_hasMorePages) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getSales(params: {'page': _currentPage});

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> salesData = [];

        if (data is Map && data['results'] != null) {
          salesData = data['results'] is List ? data['results'] : [];
          _hasMorePages = data['next'] != null;
        } else if (data is List) {
          salesData = data;
          _hasMorePages = false;
        }

        final newSales = salesData.map((json) => Sale.fromJson(json)).toList();
        _sales.addAll(newSales);
        _groupSales();

        if (newSales.isNotEmpty) _currentPage++;
        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load sales: $e';
      print('Sales Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDailySales() async {
    try {
      final response = await _apiService.getDailySales();

      if (response['success'] == true) {
        final data = response['data'];

        if (data is Map) {
          _dailyTotal = _parseDouble(data['total_sales']) ?? 0;
          _dailyTransactions = _parseInt(data['total_transactions']) ?? 0;

          final List<dynamic> salesData = data['sales'] is List ? data['sales'] : [];
          _dailySales = salesData.map((json) => Sale.fromJson(json)).toList();
          _groupSales();

          notifyListeners();
        }
      }
    } catch (e) {
      print('Daily Sales Error: $e');
    }
  }

  Future<SaleGroup?> getSaleGroupById(String saleId) async {
    if (_sales.isEmpty) {
      await loadSales();
    }
    
    final groupItems = _sales.where((sale) => sale.saleId == saleId).toList();
    
    if (groupItems.isNotEmpty) {
      final firstItem = groupItems.first;
      return SaleGroup(
        saleId: saleId,
        items: groupItems,
        saleDate: firstItem.saleDate,
        customerName: firstItem.customerName,
        staffName: firstItem.staffName,
        paymentMethod: firstItem.paymentMethod,
      );
    }
    
    return null;
  }

  Future<Sale?> getSaleById(int id) async {
    try {
      final response = await _apiService.getSale(id);
      if (response['success'] == true) {
        return Sale.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Get Sale Error: $e');
      return null;
    }
  }

  Future<bool> createSale(Map<String, dynamic> saleData) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('📦 MULTI-ITEM SALE DATA: $saleData');

      final response = await _apiService.createSale(saleData);

      print('📦 SALE RESPONSE: $response');

      if (response['success'] == true) {
        final data = response['data'];
        print('✅ SALE CREATED: ${data['sale_id']} - UGX ${data['total_amount']} with ${data['items_count']} items');
        
        await loadSales(refresh: true);
        await loadDailySales();

        _error = null;
        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        _error = response['error'] ?? 'Failed to create sale';
        print('❌ SALE ERROR: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ SALE EXCEPTION: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _apiService.getSalesByDateRange(
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] is List ? response['data'] : [];
        return data.map((json) => Sale.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Date Range Error: $e');
      return [];
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadSales(refresh: true),
      loadDailySales(),
    ]);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
