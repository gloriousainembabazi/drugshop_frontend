import 'package:flutter/material.dart';
import '../models/theme_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;

  AppTheme _currentTheme = AppTheme.system;
  String _language = 'English'; 
  bool _autoBackup = true;
  bool _isLoading = false;
  String? _error;

  // Account profile state
  String _username = 'nawamwenaphicratte192';
  String _email = 'nawamwenaphicratte192@gmail.com';
  String _phone = '0706615389';

  SettingsProvider(this._storageService, this._apiService) {
    _loadSettings();
  }

  // Getters
  AppTheme get currentTheme => _currentTheme;
  String get language => _language;
  bool get autoBackup => _autoBackup;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String get username => _username;
  String get email => _email;
  String get phone => _phone;

  final List<String> availableLanguages = ['English', 'French', 'Spanish', 'Arabic', 'Swahili'];

  String getLanguageDisplayName(String code) {
    switch (code) {
      case 'Arabic': return 'Arabic';
      case 'French': return 'French';
      case 'Spanish': return 'Spanish';
      case 'Swahili': return 'Swahili';
      case 'English':
      default: return 'English';
    }
  }

  // --- ACCOUNT UPDATE METHODS ---

  Future<bool> updateAccountUsername(String newUsername) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.updateUsername(newUsername);
      if (response['success'] == true) {
        _username = newUsername;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to update username';
    } catch (e) { _error = e.toString(); }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateAccountEmail(String newEmail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.updateEmail(newEmail);
      if (response['success'] == true) {
        _email = newEmail;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to update email';
    } catch (e) { _error = e.toString(); }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateAccountPhone(String newPhone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.updatePhone(newPhone);
      if (response['success'] == true) {
        _phone = newPhone;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = response['error'] ?? 'Failed to update phone';
    } catch (e) { _error = e.toString(); }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateAccountPassword(String oldPass, String newPass) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // API call to change password
      final response = await _apiService.updatePassword(oldPass, newPass);
      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true; // Use this boolean in UI to trigger logout/re-login flow
      }
      _error = response['error'] ?? 'Failed to update password';
    } catch (e) { _error = e.toString(); }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- ORIGINAL METHODS ---

  Future<void> _loadSettings() async {
    await Future.microtask(() {
      _isLoading = true;
      notifyListeners();
    });

    try {
      final themeIndex = await _storageService.getThemeMode();
      if (themeIndex != null) {
        final index = int.tryParse(themeIndex) ?? 0;
        if (index >= 0 && index < AppTheme.values.length) {
          _currentTheme = AppTheme.values[index];
        }
      }

      try {
        final response = await _apiService.getUserLanguage();
        if (response['success'] == true && response['data'] != null) {
          dynamic rawLangData = response['data'];
          String backendLanguage = rawLangData is Map 
              ? (rawLangData['language_code'] ?? rawLangData['language'] ?? 'en') 
              : rawLangData.toString();

          if (availableLanguages.contains(backendLanguage)) {
            _language = backendLanguage;
            await _storageService.saveLanguage(backendLanguage);
          }
        }
      } catch (e) {
        final savedLanguage = await _storageService.getLanguage();
        if (savedLanguage != null && availableLanguages.contains(savedLanguage)) {
          _language = savedLanguage;
        }
      }

      final savedAutoBackup = await _storageService.getAutoBackup();
      if (savedAutoBackup != null) {
        _autoBackup = savedAutoBackup;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _storageService.saveThemeMode(theme.index.toString());
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.updateUserLanguage(lang);
      if (response['success'] == true) {
        _language = lang;
        await _storageService.saveLanguage(lang);
        _error = null;
      } else {
        _error = response['error'] ?? 'Failed to update language on server';
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleAutoBackup() async {
    _autoBackup = !_autoBackup;
    await _storageService.saveAutoBackup(_autoBackup);
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    switch (_currentTheme) {
      case AppTheme.light: return ThemeMode.light;
      case AppTheme.dark: return ThemeMode.dark;
      case AppTheme.system: return ThemeMode.system;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}