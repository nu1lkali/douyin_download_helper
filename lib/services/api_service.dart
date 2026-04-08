import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';
import 'settings_service.dart';
import 'local_parser_service.dart';

class ApiService {
  static const String _remoteUrl = 'https://api.hk0.cc/api/douyin';

  static Future<VideoInfo> parseVideo(String url) async {
    final mode = await SettingsService.getParseMode();
    if (mode == ParseMode.local) {
      return _parseLocal(url);
    } else {
      return _parseRemote(url);
    }
  }

  /// 远程API解析
  static Future<VideoInfo> _parseRemote(String url) async {
    try {
      final uri = Uri.parse(_remoteUrl).replace(queryParameters: {'url': url});
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = response.body;
        final jsonStart = body.indexOf('{');
        if (jsonStart == -1) throw Exception('响应格式错误');
        final data = json.decode(body.substring(jsonStart));
        if (data['code'] == 200) {
          return VideoInfo.fromJson(data['data']);
        } else {
          throw Exception(data['msg'] ?? '解析失败');
        }
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('请求超时，请检查网络连接');
      }
      rethrow;
    }
  }

  /// 本地解析（直接请求抖音接口）
  static Future<VideoInfo> _parseLocal(String url) async {
    final cookie = await SettingsService.getCookie();
    final parser = LocalParserService(cookie: cookie.isEmpty ? null : cookie);
    return parser.parse(url);
  }
}
