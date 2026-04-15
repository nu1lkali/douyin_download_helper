import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';
import 'settings_service.dart';
import 'log_service.dart';

/// 自建接口解析服务 - 使用 /douyin/share_detail 合并接口
class SelfHostedApiService {
  static Future<Map<String, String>> _getConfig() async {
    final url = await SettingsService.getSelfHostedUrl();
    final token = await SettingsService.getSelfHostedToken();
    if (url.isEmpty) throw Exception('请先在设置中配置自建接口地址');
    if (token.isEmpty) throw Exception('请先在设置中配置自建接口 Token');
    return {'url': url.replaceAll(RegExp(r'/$'), ''), 'token': token};
  }

  static Map<String, String> _headers(String token) => {
        'token': token,
        'Content-Type': 'application/json',
      };

  static void _debugLog(String msg) {
    // ignore: avoid_print
    print('[SelfHosted] $msg');
    LogService.log('SelfHosted', msg);
  }

  /// 完整解析流程 - 一次请求 /douyin/share_detail
  static Future<VideoInfo> parse(String inputText) async {
    _debugLog('=== parse start ===');
    _debugLog('inputText: ${inputText.substring(0, inputText.length.clamp(0, 100))}');

    final config = await _getConfig();
    final base = config['url']!;
    final token = config['token']!;
    _debugLog('base=$base');

    final cookie = await SettingsService.getCookie();
    final reqBody = json.encode({
      'text': inputText,
      'cookie': cookie,
      'proxy': '',
      'source': false,
    });

    _debugLog('>>> POST $base/douyin/share_detail');

    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse('$base/douyin/share_detail'),
            headers: _headers(token),
            body: reqBody,
          )
          .timeout(const Duration(seconds: 60));
    } catch (e, s) {
      await LogService.logError('SelfHosted.share_detail', e, s);
      throw Exception('share_detail请求异常: $e');
    }

    _debugLog('<<< status: ${resp.statusCode}, length: ${resp.bodyBytes.length}');
    final respBody = utf8.decode(resp.bodyBytes);
    _debugLog('<<< response: $respBody');

    if (resp.statusCode != 200) {
      throw Exception('请求失败: ${resp.statusCode}\n$respBody');
    }

    final root = json.decode(respBody) as Map<String, dynamic>;
    if (!(root['message']?.toString().contains('成功') ?? false)) {
      throw Exception('${root['message']?.toString() ?? '解析失败'}\n$respBody');
    }

    try {
      final info = _mapToVideoInfo(root['data'] as Map<String, dynamic>);
      _debugLog('mapToVideoInfo ok, isVideo=${info.isVideo}, isLive=${info.isLive}');
      return info;
    } catch (e, s) {
      await LogService.logError('SelfHosted.mapToVideoInfo', e, s);
      throw Exception('数据映射失败: $e\ndata: ${root['data']}');
    }
  }

  static VideoInfo _mapToVideoInfo(Map<String, dynamic> d) {
    final type = d['type'] as String? ?? '';
    final isVideo = type == '视频';
    final isLive = type == '实况';
    final downloads = d['downloads'];

    dynamic images;
    String videoUrl = '';

    if (isVideo) {
      videoUrl = downloads as String? ?? '';
      images = '当前为短视频解析模式';
    } else if (isLive) {
      final allItems = (downloads as List?)?.map((e) => e.toString()).toList() ?? [];
      final videoClips = allItems.where((u) => u.contains('video_id=') || u.contains('/play/')).toList();
      final imageClips = allItems.where((u) => !u.contains('video_id=') && !u.contains('/play/')).toList();
      final allClips = [...videoClips, ...imageClips];
      videoUrl = videoClips.isNotEmpty ? videoClips[0] : '';
      // 无论几个片段都当作实况处理
      images = allClips.isNotEmpty
          ? '实况:${allClips.join('\n')}'
          : '当前为短视频解析模式';
    } else {
      // 图集类型
      images = (downloads as List?)?.map((e) => e.toString()).toList() ?? [];
      videoUrl = '';
    }

    String cover;
    if (!isVideo && !isLive && images is List && (images as List).isNotEmpty) {
      // 图集：用第一张图作为封面
      cover = (images as List)[0] as String;
    } else if (isLive) {
      // 实况：没有封面，留空让 UI 显示占位图
      cover = '';
    } else {
      cover = (d['static_cover'] as String?)?.isNotEmpty == true
          ? d['static_cover'] as String
          : (d['dynamic_cover'] as String? ?? '');
    }

    return VideoInfo.fromJson({
      'author': d['nickname'] ?? '',
      'uid': d['uid']?.toString() ?? '',
      'avatar': '',
      'like': d['digg_count'] ?? 0,
      'time': d['create_timestamp'] ?? 0,
      'title': d['desc'] ?? '',
      'cover': cover,
      'images': images,
      'url': videoUrl,
      'duration': _parseDuration(d['duration'] as String? ?? ''),
      'music': {
        'title': d['music_title'] ?? '',
        'author': d['music_author'] ?? '',
        'avatar': '',
        'url': d['music_url'] ?? '',
      },
    });
  }

  static int _parseDuration(String s) {
    try {
      final parts = s.split(':').map(int.parse).toList();
      if (parts.length == 3) {
        return (parts[0] * 3600 + parts[1] * 60 + parts[2]) * 1000;
      }
    } catch (_) {}
    return 0;
  }
}
