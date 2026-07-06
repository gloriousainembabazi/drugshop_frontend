// lib/models/auth_response.dart
import 'user.dart';

class AuthResponse {
  final bool isSuccess;
  final String? error;
  final User? user;
  final bool? requiresVerification;
  final String? email;
  final String? phone;
  final String? token;

  AuthResponse({
    this.isSuccess = false,
    this.error,
    this.user,
    this.requiresVerification,
    this.email,
    this.phone,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      isSuccess: json['success'] ?? false,
      error: json['error'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      requiresVerification: json['requires_verification'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': isSuccess,
      'error': error,
      'user': user?.toJson(),
      'requires_verification': requiresVerification,
      'email': email,
      'phone': phone,
    };
  }
}
