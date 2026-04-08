import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';
import 'settings_service.dart';
import 'local_parser_service.dart';

class ApiService {
  static const _hk0Url = 'https://api.hk0.cc/api/douyin';
  static const _xinyewUrl = 'https://api.xinyew.cn/api/douyinjx';

  static Future<VideoInfo> parseVideo(String url) async {
    final mode = await SettingsService.getParseMode();
    if (mode == ParseMode.local) return _parseLocal(url);

    final api = await SettingsService.getRemoteApi();
    return api == RemoteApi.xinyew
        ? _parseXinyew(url)
        : _parseHk0(url);
  }

  /// hk0 接口：返回完整字段
  static Future<VideoInfo> _parseHk0(String url) async {
    try {
      final uri = Uri.parse(_hk0Url).replace(queryParameters: {'url': url});
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

  /// xinyew 接口
  static Future<VideoInfo> _parseXinyew(String url) async {
    try {
      // 不用 Uri.replace 避免双重编码，直接拼接
      final fullUrl = '$_xinyewUrl?url=${Uri.encodeComponent(url)}';
      final response = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw Exception('请求失败: ${response.statusCode}');

      final body = response.body;
      final jsonStart = body.indexOf('{');
      if (jsonStart == -1) throw Exception('响应格式错误');
      final data = json.decode(body.substring(jsonStart)) as Map<String, dynamic>;

      // code 可能是 int 或 String
      final code = data['code'];
      final codeInt = code is int ? code : int.tryParse(code.toString()) ?? 0;
      if (codeInt != 200) throw Exception(data['msg']?.toString() ?? '解析失败');

      final d = data['data'] as Map<String, dynamic>;
      final additionalList = d['additional_data'] as List?;
      final additional = (additionalList != null && additionalList.isNotEmpty)
          ? additionalList[0] as Map<String, dynamic>
          : <String, dynamic>{};

      final avatar = additional['url'] as String? ?? '';
      // 优先用 video_url（直链），fallback 到 play_url
      final videoUrl = (() {
        final v = d['video_url'] as String? ?? '';
        if (v.isNotEmpty) return v;
        return d['play_url'] as String? ?? '';
      })();

      return VideoInfo.fromJson({
        'author': additional['nickname'] ?? '',
        'uid': '',
        'avatar': avatar,
        'like': 0,
        'time': 0,
        'title': additional['desc'] ?? '',
        'cover': avatar,
        'images': '当前为短视频解析模式',
        'url': videoUrl,
        'duration': 0,
        'music': {
          'title': '',
          'author': '',
          'avatar': '',
          'url': '',
        },
      });
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('请求超时，请检查网络连接');
      }
      rethrow;
    }
  }

  static Future<VideoInfo> _parseLocal(String url) async {
    final cookie = await SettingsService.getCookie();
    final parser = LocalParserService(cookie: cookie.isEmpty ? null : cookie);
    return parser.parse(url);
  }
}
