// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  // Ensure prefs is initialized before use
  Future<SharedPreferences> get _ensurePrefs async {
    if (!_isInitialized) {
      await init();
    }
    return _prefs;
  }

  Future<void> saveUser(User user) async {
    final prefs = await _ensurePrefs;
    await prefs.setString('user', user.toJsonString());
  }

  Future<User?> getUser() async {
    final prefs = await _ensurePrefs;
    final data = prefs.getString('user');
    if (data == null) return null;
    return User.fromJsonString(data);
  }

  Future<void> saveToken(String token) async {
    final prefs = await _ensurePrefs;
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await _ensurePrefs;
    return prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    final prefs = await _ensurePrefs;
    await prefs.remove('auth_token');
  }

  Future<void> clearUser() async {
    final prefs = await _ensurePrefs;
    await prefs.remove('user');
  }

  Future<void> clearAll() async {
    final prefs = await _ensurePrefs;
    await prefs.clear();
  }

  Future<void> saveThemeMode(String themeIndex) async {
    final prefs = await _ensurePrefs;
    await prefs.setString('theme_mode', themeIndex);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _ensurePrefs;
    return prefs.getString('theme_mode');
  }

  // Language methods
  Future<void> saveLanguage(String language) async {
    final prefs = await _ensurePrefs;
    await prefs.setString('language', language);
  }

  Future<String?> getLanguage() async {
    final prefs = await _ensurePrefs;
    return prefs.getString('language');
  }

  // Auto backup methods
  Future<void> saveAutoBackup(bool value) async {
    final prefs = await _ensurePrefs;
    await prefs.setBool('auto_backup', value);
  }

  Future<bool?> getAutoBackup() async {
    final prefs = await _ensurePrefs;
    return prefs.getBool('auto_backup');
  }
}
