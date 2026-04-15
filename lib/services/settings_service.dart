import 'package:shared_preferences/shared_preferences.dart';

enum ParseMode { selfHosted, selfHostedV2, local }

class SettingsService {
  static const _keyFloatingWindow = 'floating_window_enabled';
  static const _keyAlbumName = 'album_name';
  static const _keyParseMode = 'parse_mode';
  static const _keyCookie = 'douyin_cookie';
  static const _keyFloatingCompact = 'floating_compact_mode';
  static const _keyGroupByAuthor = 'group_by_author';
  static const _keyCompactAutoClose = 'compact_auto_close';
  static const _keyCompactAutoCloseDelay = 'compact_auto_close_delay';
  static const _keySelfHostedUrl = 'self_hosted_url';
  static const _keySelfHostedToken = 'self_hosted_token';
  static const _keySelfHostedV2Url = 'self_hosted_v2_url';
  static const _keySelfHostedV2Token = 'self_hosted_v2_token';

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
    final val = prefs.getString(_keyParseMode) ?? 'self';
    switch (val) {
      case 'local': return ParseMode.local;
      case 'self_v2': return ParseMode.selfHostedV2;
      default: return ParseMode.selfHosted;
    }
  }

  static Future<void> setParseMode(ParseMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final val = switch (mode) {
      ParseMode.local => 'local',
      ParseMode.selfHostedV2 => 'self_v2',
      _ => 'self',
    };
    await prefs.setString(_keyParseMode, val);
  }

  static Future<String> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCookie) ?? '';
  }

  static Future<void> setCookie(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookie, value.trim());
  }

  static Future<bool> getFloatingCompactMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFloatingCompact) ?? false;
  }

  static Future<void> setFloatingCompactMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFloatingCompact, value);
  }

  static Future<bool> getGroupByAuthor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGroupByAuthor) ?? false;
  }

  static Future<void> setGroupByAuthor(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGroupByAuthor, value);
  }

  static Future<bool> getCompactAutoClose() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCompactAutoClose) ?? true;
  }

  static Future<void> setCompactAutoClose(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompactAutoClose, value);
  }

  /// 自动关闭延迟：0=立即, 3=3秒, 5=5秒, -1=不关闭
  static Future<int> getCompactAutoCloseDelay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompactAutoCloseDelay) ?? 3;
  }

  static Future<void> setCompactAutoCloseDelay(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCompactAutoCloseDelay, seconds);
    // 同步更新 compact_auto_close 开关
    await prefs.setBool(_keyCompactAutoClose, seconds >= 0);
  }


  static Future<String> getSelfHostedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelfHostedUrl) ?? '';
  }

  static Future<void> setSelfHostedUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelfHostedUrl, value.trim());
  }

  static Future<String> getSelfHostedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelfHostedToken) ?? '';
  }

  static Future<void> setSelfHostedToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelfHostedToken, value.trim());
  }

  static Future<String> getSelfHostedV2Url() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelfHostedV2Url) ?? '';
  }

  static Future<void> setSelfHostedV2Url(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelfHostedV2Url, value.trim());
  }

  static Future<String> getSelfHostedV2Token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelfHostedV2Token) ?? '';
  }

  static Future<void> setSelfHostedV2Token(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelfHostedV2Token, value.trim());
  }
}
