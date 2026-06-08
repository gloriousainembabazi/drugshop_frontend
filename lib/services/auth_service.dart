import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;
  
  AuthService(this._apiService, this._storageService);

  // LOGIN METHOD - handles nested response from ApiService with verbose safety diagnostics
  Future<AuthResponse> login(String email, String password) async {
    try {
      print("🔐 LOGIN ATTEMPT: $email");
      
      final response = await _apiService.login(
        username: email,
        password: password,
      );
      
      print("📦 RAW BACKEND RESPONSE MAP: $response");

      // Check if the outer response was successful
      if (response != null && response['success'] == true) {
        // The actual data is inside response['data']
        final data = response['data'];
        print("📦 EXTRACTED INNER DATA PAYLOAD: $data");
        
        if (data is Map<String, dynamic>) {
          // Verify a valid auth token key is present in the map block
          if (data.containsKey('token') && data['token'] != null) {
            final String token = data['token'].toString(); // Safe stringify conversion
            final dynamic userData = data['user'];
            
            print("🔑 Token extracted successfully: $token");
            print("👤 User data block found: $userData");
            
            if (token.isNotEmpty) {
              await _storageService.saveToken(token);
              print("💾 Token saved to storage service successfully.");
            }
            
            if (userData != null && userData is Map<String, dynamic>) {
              try {
                print("🔄 Attempting to parse User model via User.fromJson...");
                final user = User.fromJson(userData);
                
                print("💾 Attempting to save User object to storage layer...");
                await _storageService.saveUser(user);  // Pass User object directly
                
                print("✅ All parsing succeeded! Returning success state to provider.");
                return AuthResponse(
                  isSuccess: true,
                  user: user,
                  token: token,
                );
              } catch (modelError) {
                // Catches fields parsing crashes inside lib/models/user.dart
                print("❌ CRITICAL: Your User.fromJson model initialization crashed!");
                print("The exact model breakdown error is: $modelError");
                return AuthResponse(
                  isSuccess: false,
                  error: "User model parsing failed: $modelError",
                );
              }
            }
          }
          
          // Check for verification requirement
          if (data['requires_verification'] == true) {
            print("⚠️ Account requires verification flow step.");
            return AuthResponse(
              isSuccess: false,
              error: data['error'] ?? 'Verification required',
              requiresVerification: true,
              email: data['email'],
            );
          }
          
          // Handle explicit errors inside nested response data payload
          return AuthResponse(
            isSuccess: false,
            error: data['error'] ?? 'Login failed',
          );
        }
        
        return AuthResponse(
          isSuccess: false,
          error: 'Invalid response data format layer',
        );
      } else {
        // Outer response failed (network validation error or invalid credentials structural map)
        return AuthResponse(
          isSuccess: false,
          error: response?['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      // Catches top-level framework runtime exceptions, network timeouts, or type conversion faults
      print("❌ GENERAL LOGIN FUNCTION EXCEPTION: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'System Exception: ${e.toString()}',
      );
    }
  }

  // REGISTER METHOD
  Future<AuthResponse> register(Map<String, dynamic> userData) async {
    try {
      print("📝 REGISTER ATTEMPT: ${userData['email']}");
      
      final response = await _apiService.register(userData);
      
      print("📦 REGISTER RESPONSE: $response");
      
      if (response['success'] == true) {
        final data = response['data'];
        
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            User? user;
            if (data['user'] != null) {
              user = User.fromJson(data['user']);
            }
            
            return AuthResponse(
              isSuccess: true,
              user: user,
            );
          } else {
            return AuthResponse(
              isSuccess: false,
              error: data['error'] ?? 'Registration failed',
            );
          }
        }
        
        return AuthResponse(
          isSuccess: true,
        );
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      print("❌ REGISTER ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // VERIFY OTP METHOD
  Future<AuthResponse> verifyOtp({
    String? email,
    String? phone,
    required String otp,
    required String otpType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'otp': otp,
        'otp_type': otpType,
      };
      
      if (otpType == 'email' && email != null) {
        data['email'] = email;
      } else if (otpType == 'phone' && phone != null) {
        data['phone'] = phone;
      }
      
      print("🔐 VERIFY OTP DATA: $data");
      
      final response = await _apiService.post('/api/auth/verify-otp/', data);
      
      print("📦 VERIFY OTP RESPONSE: $response");
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error: responseData['error'] ?? 'Invalid OTP',
            );
          }
        }
        
        return AuthResponse(isSuccess: true);
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      print("❌ VERIFY OTP ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // SEND OTP METHOD
  Future<AuthResponse> sendOtp({
    String? email,
    String? phone,
    required String otpType,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'otp_type': otpType,
      };
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      
      print("📧 SEND OTP DATA: $body");
      
      final response = await _apiService.post('/api/auth/send-otp/', body);
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error: responseData['error'] ?? 'Failed to send OTP',
            );
          }
        }
        
        return AuthResponse(
          isSuccess: true,
        );
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      print("❌ SEND OTP ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // FORGOT PASSWORD METHOD
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await _apiService.post('/api/auth/forgot-password/', {
        'email': email,
      });
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error: responseData['error'] ?? 'Failed to send reset instructions',
            );
          }
        }
        
        return AuthResponse(isSuccess: true);
      } else {
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Failed to send reset instructions',
        );
      }
    } catch (e) {
      print("❌ FORGOT PASSWORD ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  // RESET PASSWORD METHOD
  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    try {
      final response = await _apiService.post('/api/auth/reset-password/', {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
        'confirm_password': newPassword,
      });
      
      if (response['success'] == true) {
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic>) {
          return responseData['success'] == true;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print("❌ RESET PASSWORD ERROR: $e");
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    return await _storageService.getUser();
  }

  Future<void> logout() async {
    await _storageService.clearUser();
    await _storageService.clearToken();
  }
}