// lib/providers/expense_provider.dart

import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];

  bool _isLoading = false;
  String? _error;

  ExpenseProvider(this._apiService);

  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.getExpenses();

      if (response['success'] == true) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [];

        _expenses = data.map((e) => Expense.fromJson(e)).toList();

        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load expenses: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final response = await _apiService.getExpenseCategories();

      if (response['success'] == true) {
        final List<dynamic> data =
            response['data'] is List ? response['data'] : [];

        _categories = data.map((e) => ExpenseCategory.fromJson(e)).toList();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<bool> createExpense(Map<String, dynamic> expenseData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.createExpense(expenseData);

      if (response['success'] == true) {
        _expenses.insert(0, Expense.fromJson(response['data']));

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

  Future<bool> deleteExpense(int expenseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.delete('/api/expenses/$expenseId/');

      if (response['success'] == true) {
        // Remove the expense from the local list
        _expenses.removeWhere((expense) => expense.id == expenseId);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to delete expense';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error deleting expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(
      int expenseId, Map<String, dynamic> expenseData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response =
          await _apiService.put('/api/expenses/$expenseId/', expenseData);

      if (response['success'] == true) {
        // Update the expense in the local list
        final updatedExpense = Expense.fromJson(response['data']);
        final index = _expenses.indexWhere((e) => e.id == expenseId);
        if (index != -1) {
          _expenses[index] = updatedExpense;
        }
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to update expense';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
