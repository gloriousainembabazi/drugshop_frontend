import 'package:flutter/material.dart';
import '../models/theme_model.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  AppTheme _currentTheme = AppTheme.system;
  String _language = 'English';
  bool _autoBackup = true;

  bool _isLoading = false;
  String? _error;

  SettingsProvider(this._storageService) {
    _loadSettings();
  }

  AppTheme get currentTheme => _currentTheme;
  String get language => _language;
  bool get autoBackup => _autoBackup;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final List<String> availableLanguages = [
    'English',
    'French',
    'Spanish',
    'Arabic',
    'Swahili'
  ];

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final themeIndex = await _storageService.getThemeMode();

      if (themeIndex != null) {
        final index = int.tryParse(themeIndex) ?? 0;

        if (index >= 0 && index < AppTheme.values.length) {
          _currentTheme = AppTheme.values[index];
        }
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

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleAutoBackup() {
    _autoBackup = !_autoBackup;
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
