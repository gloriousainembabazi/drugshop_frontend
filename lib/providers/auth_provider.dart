// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _verificationEmail;
  String? _verificationPhone;

  AuthProvider(this._authService, this._storageService) {
    _loadUser();
  }

  // =========================
  // GETTERS
  // =========================

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get verificationEmail => _verificationEmail;
  String? get verificationPhone => _verificationPhone;

  // =========================
  // LOAD USER
  // =========================

  Future<void> _loadUser() async {
    _setLoading(true);

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // LOGIN
  // =========================

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);

      if (response.isSuccess && response.user != null) {
        _currentUser = response.user;
        _verificationEmail = null;
        _verificationPhone = null;

        _setLoading(false);
        return true;
      }

      if (response.requiresVerification == true) {
        _verificationEmail = response.email;
        _error = response.error;

        _setLoading(false);
        return false;
      }

      _error = response.error ?? 'Login failed';

      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // REGISTER
  // =========================

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(userData);

      if (response.isSuccess) {
        _verificationEmail = userData['email'];

        _setLoading(false);
        return true;
      } else {
        _error = response.error ?? 'Registration failed';

        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // SEND EMAIL OTP
  // =========================

  Future<bool> sendVerificationOtp(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.sendOtp(
        email: email,
        otpType: 'email',
      );

      if (!response.isSuccess) {
        _error = response.error;
      }

      _setLoading(false);

      return response.isSuccess;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // SEND PHONE OTP
  // =========================

  Future<bool> sendPhoneVerificationOtp(String phone) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.sendOtp(
        phone: phone,
        otpType: 'phone',
      );

      if (!response.isSuccess) {
        _error = response.error;
      }

      _setLoading(false);

      return response.isSuccess;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // VERIFY OTP (FIXED)
  // =========================

  Future<bool> verifyOtp(
    String? email,
    String otp, {
    String? phone,
    required String otpType,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyOtp(
        email: otpType == 'email' ? email : null,
        phone: otpType == 'phone' ? phone : null,
        otp: otp,
        otpType: otpType,
      );

      if (!response.isSuccess) {
        _error = response.error;
      }

      _setLoading(false);

      return response.isSuccess;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.forgotPassword(email);

      if (response.isSuccess) {
        _verificationEmail = email;

        _setLoading(false);
        return true;
      } else {
        _error = response.error;

        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================

  Future<bool> resetPasswordWithOtp(
    String email,
    String otp,
    String newPassword,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.resetPasswordWithOtp(
        email,
        otp,
        newPassword,
      );

      if (!success) {
        _error = 'Password reset failed';
      }

      _setLoading(false);

      return success;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);
      return false;
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();

      _currentUser = null;
      _verificationEmail = null;
      _verificationPhone = null;
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // CLEAR METHODS
  // =========================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearVerificationEmail() {
    _verificationEmail = null;
    notifyListeners();
  }

  // =========================
  // PRIVATE METHODS
  // =========================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}