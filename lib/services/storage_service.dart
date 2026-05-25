import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveUser(User user) async {
    await _prefs.setString('user', user.toJsonString());
  }

  Future<User?> getUser() async {
    final data = _prefs.getString('user');
    if (data == null) return null;
    return User.fromJsonString(data);
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    await _prefs.remove('auth_token');
  }

  Future<void> clearUser() async {
    await _prefs.remove('user');
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
  Future<void> saveThemeMode(String themeIndex) async {
  await _prefs.setString('theme_mode', themeIndex);
}

Future<String?> getThemeMode() async {
  return _prefs.getString('theme_mode');
}
}
