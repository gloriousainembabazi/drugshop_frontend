import 'package:flutter/foundation.dart';
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

class ApiService {
  final StorageService _storageService;

  // ✅ CORRECTED: Removed /auth from base URL
  static const String baseUrl = 'https://drugshop-backend-1.onrender.com/api';

  ApiService(this._storageService);

  // =====================================================
  // CORE REQUEST METHODS
  // =====================================================

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _storageService.getToken();

      debugPrint('🔍 GET Request: $baseUrl$endpoint');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Token $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _storageService.getToken();

      final fullUrl = '$baseUrl$endpoint';
      debugPrint('📤 POST Request: $fullUrl');
      debugPrint('📤 Data: $data');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Token $token',
        },
        body: jsonEncode(data),
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _storageService.getToken();

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Token $token',
        },
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _storageService.getToken();

      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Token $token',
        },
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await _storageService.getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Token $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  // =====================================================
  // RESPONSE HANDLER
  // =====================================================

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('🔍 STATUS CODE: ${response.statusCode}');
    debugPrint('🔍 RESPONSE BODY: ${response.body}');

    if (response.body.isEmpty) {
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      return {
        'success': isSuccess,
        'data': null,
        if (!isSuccess) 'error': 'Empty response from server',
        'statusCode': response.statusCode,
      };
    }

    dynamic decodedJson;
    try {
      decodedJson = jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Invalid JSON response: $e',
        'statusCode': response.statusCode,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey('success') &&
          decodedJson.containsKey('data')) {
        if (!decodedJson.containsKey('statusCode')) {
          decodedJson['statusCode'] = response.statusCode;
        }
        return decodedJson;
      }

      return {
        'success': true,
        'data': decodedJson,
        'statusCode': response.statusCode,
      };
    }

    String errorMessage = 'Something went wrong';

    if (decodedJson is Map<String, dynamic>) {
      if (decodedJson.containsKey('detail')) {
        errorMessage = decodedJson['detail'].toString();
      } else if (decodedJson.containsKey('error')) {
        errorMessage = decodedJson['error'].toString();
      } else if (decodedJson.containsKey('message')) {
        errorMessage = decodedJson['message'].toString();
      } else if (decodedJson.containsKey('non_field_errors')) {
        errorMessage = decodedJson['non_field_errors'].toString();
      } else {
        final firstKey = decodedJson.keys.firstWhere(
          (k) => decodedJson[k] is List && decodedJson[k].isNotEmpty,
          orElse: () => '',
        );
        if (firstKey.isNotEmpty) {
          errorMessage = '$firstKey: ${decodedJson[firstKey][0]}';
        } else {
          errorMessage = decodedJson.toString();
        }
      }
    } else if (decodedJson is String) {
      errorMessage = decodedJson;
    }

    return {
      'success': false,
      'data': decodedJson,
      'error': errorMessage,
      'statusCode': response.statusCode,
    };
  }

  Map<String, dynamic> _networkError(Object e) {
    debugPrint('❌ NETWORK ERROR: $e');
    return {
      'success': false,
      'data': null,
      'error': 'Network error: $e',
      'statusCode': null,
    };
  }

  // =====================================================
  // AUTH - ALL METHODS
  // =====================================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return await post(
      '/auth/login/',
      {
        'username': username.trim(),
        'password': password.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    return await post('/auth/register/', data);
  }

  Future<Map<String, dynamic>> sendOtp({
    String? email,
    String? phone,
    required String otpType,
  }) async {
    final Map<String, dynamic> body = {
      'otp_type': otpType,
    };
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    return await post('/auth/send-otp/', body);
  }

  Future<Map<String, dynamic>> verifyOtp({
    String? email,
    String? phone,
    required String otp,
    required String otpType,
  }) async {
    final Map<String, dynamic> body = {
      'otp': otp,
      'otp_type': otpType,
    };
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    return await post('/auth/verify-otp/', body);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await post('/auth/forgot-password/', {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await post('/auth/reset-password/', {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await get('/auth/current-user/');
  }

  // =====================================================
  // PROFILE MANAGEMENT
  // =====================================================

  Future<Map<String, dynamic>> updateUsername(String username) async {
    return await put('/user/update-username/', {'username': username});
  }

  Future<Map<String, dynamic>> updateEmail(String email) async {
    return await put('/user/update-email/', {'email': email});
  }

  Future<Map<String, dynamic>> updatePhone(String phone) async {
    return await put('/user/update-phone/', {'phone': phone});
  }

  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
    String? phone,
  }) async {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    return await put('/user/update-profile/', data);
  }

  Future<Map<String, dynamic>> updateProfilePicture(String imagePath) async {
    try {
      final token = await _storageService.getToken();
      final request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/user/update-profile-picture/'));

      request.headers['Authorization'] = 'Token $token';
      request.files
          .add(await http.MultipartFile.fromPath('profile_picture', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await get('/user/profile/');
  }

  Future<Map<String, dynamic>> verifyEmailOTP(String email, String otp) async {
    return await post(
      '/user/verify-email/',
      {'email': email, 'otp': otp},
    );
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    return await post(
      '/user/resend-verification/',
      {'email': email},
    );
  }

  // =====================================================
  // LANGUAGE PREFERENCES
  // =====================================================

  Future<Map<String, dynamic>> updateUserLanguage(String language) async {
    return await patch(
      '/user/language/',
      {'language': language},
    );
  }

  Future<Map<String, dynamic>> getUserLanguage() async {
    return await get('/user/language/');
  }

  // =====================================================
  // MEDICINES
  // =====================================================

  Future<Map<String, dynamic>> getMedicines({
    Map<String, dynamic>? params,
  }) async {
    String endpoint = '/medicines/';

    if (params != null && params.isNotEmpty) {
      final queryString = Uri(
        queryParameters: params.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ).query;

      endpoint = '$endpoint?$queryString';
    }

    return await get(endpoint);
  }

  Future<Map<String, dynamic>> getMedicine(int id) async {
    return await get('/medicines/$id/');
  }

  Future<Map<String, dynamic>> createMedicine(
    Map<String, dynamic> data,
  ) async {
    return await post('/medicines/', data);
  }

  Future<Map<String, dynamic>> updateMedicine(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await put('/medicines/$id/', data);
  }

  Future<Map<String, dynamic>> deleteMedicine(int id) async {
    return await delete('/medicines/$id/');
  }

  Future<Map<String, dynamic>> getLowStockMedicines() async {
    return await get('/medicines/low-stock/');
  }

  Future<Map<String, dynamic>> getExpiringMedicines() async {
    return await get('/medicines/expiring/');
  }

  Future<Map<String, dynamic>> getExpiredMedicines() async {
    return await get('/medicines/expired/');
  }

  Future<Map<String, dynamic>> getCategories() async {
    return await get('/medicines/categories/');
  }

  Future<Map<String, dynamic>> getSuppliers() async {
    return await get('/medicines/suppliers/');
  }

  // =====================================================
  // SALES
  // =====================================================

  Future<Map<String, dynamic>> getSales({
    Map<String, dynamic>? params,
  }) async {
    String endpoint = '/sales/';

    if (params != null && params.isNotEmpty) {
      final queryString = Uri(
        queryParameters: params.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      ).query;

      endpoint = '$endpoint?$queryString';
    }

    return await get(endpoint);
  }

  Future<Map<String, dynamic>> getSale(int id) async {
    return await get('/sales/$id/');
  }

  Future<Map<String, dynamic>> createSale(
    Map<String, dynamic> data,
  ) async {
    return await post('/sales/', data);
  }

  Future<Map<String, dynamic>> getDailySales() async {
    return await get('/sales/daily/');
  }

  Future<Map<String, dynamic>> getSalesByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await get(
      '/reports/sales/?start=$startDate&end=$endDate',
    );
  }

  Future<Map<String, dynamic>> getSaleItems(String saleId) async {
    try {
      final token = await _storageService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/sales/items/$saleId/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get sale items: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Get Sale Items Error: $e');
      return {
        'success': false,
        'error': 'Failed to get sale items: $e',
      };
    }
  }

  // =====================================================
  // REPORTS
  // =====================================================

  Future<Map<String, dynamic>> getDashboardSummary() async {
    return await get('/reports/dashboard/');
  }

  Future<Map<String, dynamic>> getSalesReport({
    String? startDate,
    String? endDate,
  }) async {
    return await get(
      '/reports/sales/?start=${startDate ?? ""}&end=${endDate ?? ""}',
    );
  }

  Future<Map<String, dynamic>> getInventoryReport() async {
    return await get('/reports/inventory/');
  }

  Future<Map<String, dynamic>> getStaffReport() async {
    return await get('/reports/staff/');
  }

  Future<Map<String, dynamic>> getDailySalesReport() async {
    return await get('/reports/daily-sales/');
  }

  Future<Map<String, dynamic>> getLowStockReport() async {
    return await get('/reports/low-stock/');
  }

  Future<Map<String, dynamic>> getExpiredReport() async {
    return await get('/reports/expired/');
  }

  // =====================================================
  // EXPENSES
  // =====================================================

  Future<Map<String, dynamic>> getExpenses() async {
    return await get('/expenses/');
  }

  Future<Map<String, dynamic>> getExpenseCategories() async {
    return await get('/expenses/categories/');
  }

  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> data,
  ) async {
    return await post('/expenses/', data);
  }

  // =====================================================
  // CREDIT
  // =====================================================

  Future<Map<String, dynamic>> getCustomers() async {
    return await get('/credit/customers/');
  }

  Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> data,
  ) async {
    return await post('/credit/customers/', data);
  }

  Future<Map<String, dynamic>> getCreditSales() async {
    return await get('/credit/sales/');
  }

  Future<Map<String, dynamic>> createCreditSale(
    Map<String, dynamic> data,
  ) async {
    debugPrint('📤 API SERVICE - SENDING TO /credit/sales/');
    debugPrint('📤 REQUEST BODY: $data');
    debugPrint('📤 TOTAL_AMOUNT: ${data['total_amount']}');

    final response = await post('/credit/sales/', data);

    debugPrint('📥 API SERVICE - RESPONSE STATUS: ${response['statusCode']}');
    debugPrint('📥 API SERVICE - RESPONSE BODY: ${response['data']}');

    return response;
  }

  // =====================================================
  // PRESCRIPTIONS
  // =====================================================

  Future<Map<String, dynamic>> getPrescriptions() async {
    return await get('/prescriptions/');
  }

  Future<Map<String, dynamic>> createPrescription(
    Map<String, dynamic> data,
  ) async {
    return await post('/prescriptions/', data);
  }

  Future<Map<String, dynamic>> postFile(
      String endpoint, String filePath) async {
    try {
      final token = await _storageService.getToken();
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

      request.headers['Authorization'] = 'Token $token';
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> postWithImage(
      String endpoint,
      Map<String, dynamic> data,
      Uint8List imageBytes,
      String imageFieldName) async {
    try {
      final token = await _storageService.getToken();

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

      request.headers['Authorization'] = 'Token $token';

      data.forEach((key, value) {
        if (value != null) {
          if (key == 'items') {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      request.files.add(http.MultipartFile.fromBytes(
        imageFieldName,
        imageBytes,
        filename: 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📸 IMAGE UPLOAD RESPONSE: ${response.statusCode}');
      debugPrint('📸 IMAGE UPLOAD BODY: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('📸 IMAGE UPLOAD ERROR: $e');
      return _networkError(e);
    }
  }

  // =====================================================
  // STOCK
  // =====================================================

  Future<Map<String, dynamic>> getStockCounts() async {
    return await get('/stock/counts/');
  }

  Future<Map<String, dynamic>> createStockCount(
    Map<String, dynamic> data,
  ) async {
    return await post('/stock/counts/', data);
  }

  Future<Map<String, dynamic>> submitStockCount(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await post(
      '/stock/counts/$id/submit/',
      data,
    );
  }

  Future<Map<String, dynamic>> updatePassword(
      String oldPassword, String newPassword) async {
    return await put(
      '/user/update-password/',
      {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }
}
