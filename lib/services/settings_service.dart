import 'package:shared_preferences/shared_preferences.dart';

enum ParseMode { remote, local }

class SettingsService {
  static const _keyFloatingWindow = 'floating_window_enabled';
  static const _keyAlbumName = 'album_name';
  static const _keyParseMode = 'parse_mode';
  static const _keyCookie = 'douyin_cookie';

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
    return prefs.getString(_keyAlbumName) ?? '便捷下载';
  }

  static Future<void> setAlbumName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAlbumName, value.trim().isEmpty ? '便捷下载' : value.trim());
  }

  static Future<ParseMode> getParseMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyParseMode) ?? 'remote';
    return val == 'local' ? ParseMode.local : ParseMode.remote;
  }

  static Future<void> setParseMode(ParseMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParseMode, mode == ParseMode.local ? 'local' : 'remote');
  }

  static Future<String> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCookie) ?? '';
  }

  static Future<void> setCookie(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookie, value.trim());
  }
}
