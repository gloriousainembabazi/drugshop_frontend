// lib/providers/report_provider.dart

import 'dart:convert';
// import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService _apiService;

  ReportProvider(this._apiService);

  // =========================================================
  // STATE
  // =========================================================

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _dashboardSummary;
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _inventoryReport;
  Map<String, dynamic>? _staffReport;

  List<dynamic> _dailySalesReport = [];
  List<dynamic> _lowStockReport = [];
  List<dynamic> _expiredReport = [];

  // =========================================================
  // GETTERS
  // =========================================================

  bool get isLoading => _isLoading;

  String? get error => _error;

  Map<String, dynamic>? get dashboardSummary => _dashboardSummary;

  Map<String, dynamic>? get salesReport => _salesReport;

  Map<String, dynamic>? get inventoryReport => _inventoryReport;

  Map<String, dynamic>? get staffReport => _staffReport;

  List<dynamic> get dailySalesReport => _dailySalesReport;

  List<dynamic> get lowStockReport => _lowStockReport;

  List<dynamic> get expiredReport => _expiredReport;

  // =========================================================
  // HELPERS
  // =========================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool _hasError(Map<String, dynamic> response) {
    return response['success'] == false;
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  Future<void> loadDashboardSummary() async {
    try {
      _setLoading(true);

      final response = await _apiService.getDashboardSummary();

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load dashboard summary');
        return;
      }

      _dashboardSummary = Map<String, dynamic>.from(response['data']);

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // SALES REPORT
  // =========================================================

  Future<void> loadSalesReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      _setLoading(true);

      final response = await _apiService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load sales report');
        return;
      }

      _salesReport = Map<String, dynamic>.from(response['data']);

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // INVENTORY REPORT
  // =========================================================

  Future<void> loadInventoryReport() async {
    try {
      _setLoading(true);

      final response = await _apiService.getInventoryReport();

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load inventory report');
        return;
      }

      _inventoryReport = Map<String, dynamic>.from(response['data']);

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // STAFF REPORT
  // =========================================================

  Future<void> loadStaffReport() async {
    try {
      _setLoading(true);

      final response = await _apiService.getStaffReport();

      debugPrint('📊 STAFF REPORT API RESPONSE: ${response['success']}');
      debugPrint('📊 STAFF REPORT DATA: ${response['data']}');

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load staff report');
        return;
      }

      _staffReport = Map<String, dynamic>.from(response['data']);

      // debugPrint staff summary details
      final staffSummary = _staffReport?['staff_summary'] ?? [];
      debugPrint('📊 NUMBER OF STAFF MEMBERS: ${staffSummary.length}');
      for (var staff in staffSummary) {
        debugPrint(
            '📊 STAFF: ${staff['name']} - Role: ${staff['role']} - Sales: ${staff['total_sales']}');
      }

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  // =========================================================
  // DAILY SALES REPORT
  // =========================================================

  Future<void> loadDailySalesReport() async {
    try {
      _setLoading(true);

      final response = await _apiService.getDailySalesReport();

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load daily sales report');
        return;
      }

      final data = response['data'];
      if (data is List) {
        _dailySalesReport = data;
      } else {
        _dailySalesReport = [];
      }

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // LOW STOCK REPORT
  // =========================================================

  Future<void> loadLowStockReport() async {
    try {
      _setLoading(true);

      final response = await _apiService.getLowStockReport();

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load low stock report');
        return;
      }

      final data = response['data'];
      if (data is List) {
        _lowStockReport = data;
      } else {
        _lowStockReport = [];
      }

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // EXPIRED REPORT
  // =========================================================

  Future<void> loadExpiredReport() async {
    try {
      _setLoading(true);

      final response = await _apiService.getExpiredReport();

      if (_hasError(response)) {
        _setError(response['error'] ?? 'Failed to load expired report');
        return;
      }

      final data = response['data'];
      if (data is List) {
        _expiredReport = data;
      } else {
        _expiredReport = [];
      }

      clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // DOWNLOAD REPORTS
  // =========================================================

  Future<void> downloadSalesReport() async {
    if (_salesReport == null) return;

    final content = const JsonEncoder.withIndent('  ').convert(_salesReport);

    _downloadFile(content, 'sales_report.json');
  }

  Future<void> downloadInventoryReport() async {
    if (_inventoryReport == null) return;

    final content =
        const JsonEncoder.withIndent('  ').convert(_inventoryReport);

    _downloadFile(content, 'inventory_report.json');
  }

  Future<void> downloadStaffReport() async {
    if (_staffReport == null) return;

    final content = const JsonEncoder.withIndent('  ').convert(_staffReport);

    _downloadFile(content, 'staff_report.json');
  }

  Future<void> downloadDashboardSummary() async {
    if (_dashboardSummary == null) return;

    final content =
        const JsonEncoder.withIndent('  ').convert(_dashboardSummary);

    _downloadFile(content, 'dashboard_summary.json');
  }

  // =========================================================
  // =========================================================
  // DOWNLOAD HELPER
  // =========================================================

  void _downloadFile(String content, String fileName) {
    final bytes = utf8.encode(content);

    // Web-only download functionality disabled for Android builds.
    debugPrint('Download disabled on Android: $fileName');
    debugPrint('Content size: ${bytes.length} bytes');
  }
}
