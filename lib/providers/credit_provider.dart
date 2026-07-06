import 'package:flutter/foundation.dart';
// lib/providers/credit_provider.dart

import 'package:flutter/material.dart';
import '../models/credit.dart'; // Add this import
import '../services/api_service.dart';

class CreditProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Customer> _customers = [];
  List<CreditSale> _creditSales = [];

  bool _isLoading = false;
  String? _error;

  CreditProvider(this._apiService);

  List<Customer> get customers => _customers;
  List<CreditSale> get creditSales => _creditSales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getCustomers();

      if (response['success'] == true) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [];

        _customers = data.map((e) => Customer.fromJson(e)).toList();

        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load customers: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCustomer(int id, Map<String, dynamic> customerData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response =
          await _apiService.put('/api/credit/customers/$id/', customerData);

      if (response['success'] == true) {
        final index = _customers.indexWhere((c) => c.id == id);
        if (index != -1) {
          _customers[index] = Customer.fromJson(response['data']);
        }
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

  // Record payment for credit sale
  Future<bool> recordPayment(
      int creditId, double amount, String paymentMethod, String notes) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.post(
        '/api/credit/sales/$creditId/payments/',
        {
          'amount': amount.toString(),
          'payment_method': paymentMethod,
          'notes': notes,
        },
      );

      if (response['success'] == true) {
        await loadCreditSales();
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

  // Get credit summary
  Future<Map<String, dynamic>?> getCreditSummary() async {
    try {
      final response = await _apiService.get('/api/credit/summary/');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting credit summary: $e');
      return null;
    }
  }

  // Search customers
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    return _customers
        .where((customer) =>
            customer.fullName.toLowerCase().contains(query.toLowerCase()) ||
            customer.phone.contains(query) ||
            customer.email.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Search credit sales
  List<CreditSale> searchCreditSales(String query) {
    if (query.isEmpty) return _creditSales;
    return _creditSales.where((sale) {
      // Check if any medicine name matches
      bool medicineMatches = sale.items.any((item) =>
          item.medicineName.toLowerCase().contains(query.toLowerCase()));

      return sale.customerName.toLowerCase().contains(query.toLowerCase()) ||
          sale.creditId.toLowerCase().contains(query.toLowerCase()) ||
          medicineMatches;
    }).toList();
  }

  // Get credit sales by customer
  List<CreditSale> getCreditSalesByCustomer(int customerId) {
    return _creditSales.where((sale) => sale.customerId == customerId).toList();
  }

  // Get overdue credit sales
  List<CreditSale> getOverdueCreditSales() {
    return _creditSales
        .where((sale) => sale.isOverdue && sale.balance > 0)
        .toList();
  }

  Future<void> loadCreditSales() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getCreditSales();

      debugPrint(
          '📦 CREDIT SALES API RESPONSE SUCCESS: ${response['success']}');
      debugPrint('📦 CREDIT SALES RAW RESPONSE: ${response['data']}');

      if (response['success'] == true) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [];
        debugPrint('📦 CREDIT SALES COUNT FROM API: ${data.length}');

        _creditSales = data.map((e) => CreditSale.fromJson(e)).toList();

        for (var credit in _creditSales) {
          debugPrint(
              '📦 CREDIT SALE: ${credit.creditId} - Items: ${credit.items.length} - UGX ${credit.totalAmount}');
        }

        _error = null;
      } else {
        _error = response['error'];
        debugPrint('❌ CREDIT SALES API ERROR: $_error');
      }
    } catch (e) {
      _error = 'Failed to load credit sales: $e';
      debugPrint('❌ CREDIT SALES EXCEPTION: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCustomer(Map<String, dynamic> customerData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.createCustomer(customerData);

      if (response['success'] == true) {
        _customers.add(Customer.fromJson(response['data']));
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

  Future<bool> createCreditSale(Map<String, dynamic> creditData) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('📤 CREATING CREDIT SALE WITH DATA:');
      debugPrint(creditData.toString());

      final response = await _apiService.createCreditSale(creditData);
      debugPrint('📥 RESPONSE: $response');

      if (response['success'] == true) {
        _creditSales.add(CreditSale.fromJson(response['data']));
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'];
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('❌ ERROR IN createCreditSale: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteCreditSale(int creditId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response =
          await _apiService.delete('/api/credit/sales/$creditId/delete/');

      if (response['success'] == true) {
        _creditSales.removeWhere((sale) => sale.id == creditId);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'];
    } catch (e) {
      _error = 'Error deleting credit sale: $e';
      debugPrint('❌ Error in deleteCreditSale: $e');
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
