import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyFloatingWindow = 'floating_window_enabled';
  static const _keyAlbumName = 'album_name';

  static Future<bool> getFloatingWindowEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFloatingWindow) ?? false;
  }

  static Future<void> setFloatingWindowEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFloatingWindow, value);
  }

  static Future<String> getAlbumName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAlbumName) ?? '抖音下载';
  }

  static Future<void> setAlbumName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAlbumName, value.trim().isEmpty ? '抖音下载' : value.trim());
  }
}
