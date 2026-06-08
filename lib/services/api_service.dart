import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';  
import 'dart:io';

class ApiService {
  final StorageService _storageService;

  // FOR FLUTTER WEB + DJANGO
  static const String baseUrl = 'http://127.0.0.1:8000';

  ApiService(this._storageService);

  // =====================================================
  // CORE REQUEST METHODS
  // =====================================================

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _storageService.getToken();

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
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _storageService.getToken();

      final response = await http.post(
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

  // 🌟 Added PATCH support for partial updates expected by Django REST Framework
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
  // RESPONSE HANDLER - FIXES DOUBLE NESTING
  // =====================================================

  Map<String, dynamic> _handleResponse(http.Response response) {
    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE BODY: ${response.body}');

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

    // Handle successful response (2xx status codes)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // If the backend already structures structural response keys ('success' and 'data'),
      // return it as-is to bypass unwanted local dictionary re-wrapping.
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

    // Handle normalization of errors
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
    return {
      'success': false,
      'data': null,
      'error': 'Network error: $e',
      'statusCode': null,
    };
  }

  // =====================================================
  // AUTH
  // =====================================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return await post(
      '/api/auth/login/',
      {
        'username': username,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/auth/register/', data);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await get('/api/auth/current-user/');
  }

  // =====================================================
  // PROFILE MANAGEMENT
  // =====================================================

  Future<Map<String, dynamic>> updateUsername(String username) async {
    return await put(
      '/api/user/update-username/',
      {'username': username},
    );
  }

  Future<Map<String, dynamic>> updateEmail(String email) async {
    return await put(
      '/api/user/update-email/',
      {'email': email},
    );
  }

  Future<Map<String, dynamic>> updatePhone(String phone) async {
    return await put(
      '/api/user/update-phone/',
      {'phone': phone},
    );
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
    return await put('/api/user/update-profile/', data);
  }

  Future<Map<String, dynamic>> updateProfilePicture(String imagePath) async {
    try {
      final token = await _storageService.getToken();
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/api/user/update-profile-picture/')
      );
      
      request.headers['Authorization'] = 'Token $token';
      request.files.add(await http.MultipartFile.fromPath('profile_picture', imagePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await get('/api/user/profile/');
  }

  Future<Map<String, dynamic>> verifyEmailOTP(String email, String otp) async {
    return await post(
      '/api/user/verify-email/',
      {'email': email, 'otp': otp},
    );
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    return await post(
      '/api/user/resend-verification/',
      {'email': email},
    );
  }

  // =====================================================
  // LANGUAGE PREFERENCES - FIXING FOR DRF 405 ROUTING
  // =====================================================

  Future<Map<String, dynamic>> updateUserLanguage(String language) async {
    // 🌟 ROUTING FIX: Changed to use patch() method to correctly communicate partial adjustments
    return await patch(
      '/api/user/language/',
      {'language': language},
    );
  }

  Future<Map<String, dynamic>> getUserLanguage() async {
    return await get('/api/user/language/');
  }

  // =====================================================
  // MEDICINES
  // =====================================================

  Future<Map<String, dynamic>> getMedicines({
    Map<String, dynamic>? params,
  }) async {
    String endpoint = '/api/medicines/';

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
    return await get('/api/medicines/$id/');
  }

  Future<Map<String, dynamic>> createMedicine(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/medicines/', data);
  }

  Future<Map<String, dynamic>> updateMedicine(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await put('/api/medicines/$id/', data);
  }

  Future<Map<String, dynamic>> deleteMedicine(int id) async {
    return await delete('/api/medicines/$id/');
  }

  Future<Map<String, dynamic>> getLowStockMedicines() async {
    return await get('/api/medicines/low-stock/');
  }

  Future<Map<String, dynamic>> getExpiringMedicines() async {
    return await get('/api/medicines/expiring/');
  }

  Future<Map<String, dynamic>> getExpiredMedicines() async {
    return await get('/api/medicines/expired/');
  }

  Future<Map<String, dynamic>> getCategories() async {
    return await get('/api/medicines/categories/');
  }

  Future<Map<String, dynamic>> getSuppliers() async {
    return await get('/api/medicines/suppliers/');
  }

  // =====================================================
  // SALES
  // =====================================================

  Future<Map<String, dynamic>> getSales({
    Map<String, dynamic>? params,
  }) async {
    String endpoint = '/api/sales/';

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
    return await get('/api/sales/$id/');
  }

  Future<Map<String, dynamic>> createSale(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/sales/', data);
  }

  Future<Map<String, dynamic>> getDailySales() async {
    return await get('/api/sales/daily/');
  }

  Future<Map<String, dynamic>> getSalesByDateRange(
    String startDate,
    String endDate,
  ) async {
    return await get(
      '/api/reports/sales/?start=$startDate&end=$endDate',
    );
  }
  
  Future<Map<String, dynamic>> getSaleItems(String saleId) async {
    try {
      final token = await _storageService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales/items/$saleId/'),
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
      print('Get Sale Items Error: $e');
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
    return await get('/api/reports/dashboard/');
  }

  Future<Map<String, dynamic>> getSalesReport({
    String? startDate,
    String? endDate,
  }) async {
    return await get(
      '/api/reports/sales/?start=${startDate ?? ""}&end=${endDate ?? ""}',
    );
  }

  Future<Map<String, dynamic>> getInventoryReport() async {
    return await get('/api/reports/inventory/');
  }

  Future<Map<String, dynamic>> getStaffReport() async {
    return await get('/api/reports/staff/');
  }

  Future<Map<String, dynamic>> getDailySalesReport() async {
    return await get('/api/reports/daily-sales/');
  }

  Future<Map<String, dynamic>> getLowStockReport() async {
    return await get('/api/reports/low-stock/');
  }

  Future<Map<String, dynamic>> getExpiredReport() async {
    return await get('/api/reports/expired/');
  }

  // =====================================================
  // EXPENSES
  // =====================================================

  Future<Map<String, dynamic>> getExpenses() async {
    return await get('/api/expenses/');
  }

  Future<Map<String, dynamic>> getExpenseCategories() async {
    return await get('/api/expenses/categories/');
  }

  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/expenses/', data);
  }

  // =====================================================
  // CREDIT
  // =====================================================

  Future<Map<String, dynamic>> getCustomers() async {
    return await get('/api/credit/customers/');
  }

  Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/credit/customers/', data);
  }

  Future<Map<String, dynamic>> getCreditSales() async {
    return await get('/api/credit/sales/');
  }

  Future<Map<String, dynamic>> createCreditSale(
    Map<String, dynamic> data,
  ) async {
    print('📤 API SERVICE - SENDING TO /api/credit/sales/');
    print('📤 REQUEST BODY: $data');
    print('📤 TOTAL_AMOUNT: ${data['total_amount']}');
    
    final response = await post('/api/credit/sales/', data);
    
    print('📥 API SERVICE - RESPONSE STATUS: ${response['statusCode']}');
    print('📥 API SERVICE - RESPONSE BODY: ${response['data']}');
    
    return response;
  }
  
  // =====================================================
  // PRESCRIPTIONS
  // =====================================================

  Future<Map<String, dynamic>> getPrescriptions() async {
    return await get('/api/prescriptions/');
  }

  Future<Map<String, dynamic>> createPrescription(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/prescriptions/', data);
  }

  Future<Map<String, dynamic>> postFile(String endpoint, String filePath) async {
    try {
      final token = await _storageService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
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
    String imageFieldName
  ) async {
    try {
      final token = await _storageService.getToken();
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
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
      
      print('📸 IMAGE UPLOAD RESPONSE: ${response.statusCode}');
      print('📸 IMAGE UPLOAD BODY: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('📸 IMAGE UPLOAD ERROR: $e');
      return _networkError(e);
    }
  }

  // =====================================================
  // STOCK
  // =====================================================

  Future<Map<String, dynamic>> getStockCounts() async {
    return await get('/api/stock/counts/');
  }

  Future<Map<String, dynamic>> createStockCount(
    Map<String, dynamic> data,
  ) async {
    return await post('/api/stock/counts/', data);
  }

  Future<Map<String, dynamic>> submitStockCount(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await post(
      '/api/stock/counts/$id/submit/',
      data,
    );
  }
  Future<Map<String, dynamic>> updatePassword(String oldPassword, String newPassword) async {
    return await put(
      '/api/user/update-password/',
      {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }
}
