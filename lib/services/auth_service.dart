import 'package:flutter/foundation.dart';
// lib/services/auth_service.dart
import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<AuthResponse> login(String username, String password) async {
    try {
      debugPrint("🔐 LOGIN ATTEMPT: $username");

      final response = await _apiService.login(
        username: username,
        password: password,
      );

      debugPrint("📦 RAW BACKEND RESPONSE MAP: $response");

      if (response['success'] == true) {
        final data = response['data'];
        debugPrint("📦 EXTRACTED INNER DATA PAYLOAD: $data");

        if (data is Map<String, dynamic>) {
          if (data.containsKey('token') && data['token'] != null) {
            final String token = data['token'].toString();
            final dynamic userData = data['user'];

            debugPrint("🔑 Token extracted successfully: $token");
            debugPrint("👤 User data block found: $userData");

            if (token.isNotEmpty) {
              await _storageService.saveToken(token);
              debugPrint("💾 Token saved to storage service successfully.");
            }

            if (userData != null && userData is Map<String, dynamic>) {
              try {
                debugPrint(
                    "🔄 Attempting to parse User model via User.fromJson...");
                final user = User.fromJson(userData);

                debugPrint(
                    "💾 Attempting to save User object to storage layer...");
                await _storageService.saveUser(user);

                debugPrint(
                    "✅ All parsing succeeded! Returning success state to provider.");
                return AuthResponse(
                  isSuccess: true,
                  user: user,
                  token: token,
                );
              } catch (modelError) {
                debugPrint(
                    "❌ CRITICAL: User.fromJson model initialization crashed!");
                debugPrint("The exact model breakdown error is: $modelError");
                return AuthResponse(
                  isSuccess: false,
                  error: "User model parsing failed: $modelError",
                );
              }
            }
          }

          if (data['requires_verification'] == true) {
            debugPrint("⚠️ Account requires verification flow step.");
            return AuthResponse(
              isSuccess: false,
              error: data['error'] ?? 'Verification required',
              requiresVerification: true,
              email: data['email'],
            );
          }

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
        return AuthResponse(
          isSuccess: false,
          error: response['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      debugPrint("❌ GENERAL LOGIN FUNCTION EXCEPTION: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'System Exception: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> register(Map<String, dynamic> userData) async {
    try {
      debugPrint("📝 REGISTER ATTEMPT: ${userData['email']}");

      final response = await _apiService.register(userData);

      debugPrint("📦 REGISTER RESPONSE: $response");

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
      debugPrint("❌ REGISTER ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

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

      debugPrint("📧 SEND OTP DATA: $body");

      final response = await _apiService.sendOtp(
        email: email,
        phone: phone,
        otpType: otpType,
      );

      debugPrint("📦 SEND OTP RESPONSE: $response");

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
      debugPrint("❌ SEND OTP ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

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

      debugPrint("🔐 VERIFY OTP DATA: $data");

      final response = await _apiService.verifyOtp(
        email: email,
        phone: phone,
        otp: otp,
        otpType: otpType,
      );

      debugPrint("📦 VERIFY OTP RESPONSE: $response");

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
      debugPrint("❌ VERIFY OTP ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);

      if (response['success'] == true) {
        final responseData = response['data'];

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true) {
            return AuthResponse(isSuccess: true);
          } else {
            return AuthResponse(
              isSuccess: false,
              error:
                  responseData['error'] ?? 'Failed to send reset instructions',
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
      debugPrint("❌ FORGOT PASSWORD ERROR: $e");
      return AuthResponse(
        isSuccess: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<bool> resetPasswordWithOtp(
      String email, String otp, String newPassword) async {
    try {
      final response = await _apiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: newPassword,
      );

      if (response['success'] == true) {
        final responseData = response['data'];

        if (responseData is Map<String, dynamic>) {
          return responseData['success'] == true;
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ RESET PASSWORD ERROR: $e");
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
