import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';
import 'settings_service.dart';
import 'log_service.dart';

/// 自建接口解析服务
/// 流程：POST /douyin/share → 提取 aweme_id → POST /douyin/detail → 装配 VideoInfo
class SelfHostedApiService {
  // url 和 token 从设置里读取，不硬编码
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

  /// 完整解析流程
  static Future<VideoInfo> parse(String inputText) async {
    _debugLog('=== parse start ===');
    _debugLog('inputText: ${inputText.substring(0, inputText.length.clamp(0, 100))}');

    final config = await _getConfig();
    final base = config['url']!;
    final token = config['token']!;
    _debugLog('base=$base, token=${token.substring(0, token.length.clamp(0, 8))}...');

    String realUrl;
    try {
      _debugLog('calling share...');
      realUrl = await _getShareUrl(inputText, base, token);
      _debugLog('share ok, realUrl=$realUrl');
    } catch (e, s) {
      await LogService.logError('SelfHosted', e, s);
      throw Exception('share接口失败: $e');
    }

    final awemeId = _extractAwemeId(realUrl);
    _debugLog('aweme_id=$awemeId');
    if (awemeId == null) {
      throw Exception('无法从链接中提取视频ID\nshare返回URL: $realUrl');
    }

    try {
      _debugLog('calling detail, aweme_id=$awemeId...');
      final result = await _getDetail(awemeId, base, token);
      _debugLog('detail ok, type=${result.isVideo ? "video" : "image/live"}');
      return result;
    } catch (e, s) {
      await LogService.logError('SelfHosted', e, s);
      final msg = e.toString();
      if (msg.contains('Exception:')) rethrow;
      throw Exception('detail接口失败: $e\n[aweme_id=$awemeId]');
    }
  }

  static void _debugLog(String msg) {
    // ignore: avoid_print
    print('[SelfHosted] $msg');
    LogService.log('SelfHosted', msg);
  }

  /// POST /douyin/share
  static Future<String> _getShareUrl(String text, String base, String token) async {
    final body = json.encode({'text': text, 'proxy': ''});
    _debugLog('>>> POST $base/douyin/share');
    _debugLog('>>> body: $body');

    final resp = await http
        .post(Uri.parse('$base/douyin/share'), headers: _headers(token), body: body)
        .timeout(const Duration(seconds: 30));

    _debugLog('<<< share status: ${resp.statusCode}');
    final shareBody = utf8.decode(resp.bodyBytes);
    _debugLog('<<< share response: $shareBody');

    if (resp.statusCode != 200) throw Exception('share 请求失败: ${resp.statusCode}\n$shareBody');
    final data = json.decode(shareBody) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception(data['message']?.toString() ?? '获取链接失败');
    }
    return url;
  }

  /// 从 URL 提取 aweme_id
  static String? _extractAwemeId(String url) {
    for (final pattern in [
      RegExp(r'/video/(\d+)'),
      RegExp(r'/note/(\d+)'),
      RegExp(r'modal_id=(\d+)'),
    ]) {
      final m = pattern.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// POST /douyin/detail
  static Future<VideoInfo> _getDetail(String awemeId, String base, String token) async {
    final cookie = await SettingsService.getCookie();
    final reqBody = json.encode({
      'cookie': cookie.isNotEmpty ? '${cookie.substring(0, cookie.length.clamp(0, 30))}...(len=${cookie.length})' : '',
      'proxy': '',
      'source': false,
      'detail_id': awemeId,
    });
    final actualBody = json.encode({
      'cookie': cookie,
      'proxy': '',
      'source': false,
      'detail_id': awemeId,
    });

    _debugLog('>>> POST $base/douyin/detail');
    _debugLog('>>> body (cookie masked): $reqBody');

    http.Response resp;
    try {
      resp = await http
          .post(Uri.parse('$base/douyin/detail'), headers: _headers(token), body: actualBody)
          .timeout(const Duration(seconds: 60));
    } catch (e, s) {
      await LogService.logError('SelfHosted.detail', e, s);
      throw Exception('detail请求异常: $e\naweme_id=$awemeId');
    }

    _debugLog('<<< detail status: ${resp.statusCode}, length: ${resp.body.length}');
    // 强制 UTF-8 解码，http 包默认 latin-1 会导致中文乱码
    final respBody = utf8.decode(resp.bodyBytes);
    _debugLog('<<< detail response: $respBody');

    if (resp.statusCode != 200) {
      throw Exception('detail请求失败: ${resp.statusCode}\n响应: $respBody');
    }

    final root = json.decode(respBody) as Map<String, dynamic>;
    _debugLog('message=${root['message']}, data.type=${(root['data'] as Map?)?['type']}');

    if (!(root['message']?.toString().contains('成功') ?? false)) {
      throw Exception('${root['message']?.toString() ?? '获取详情失败'}\naweme_id=$awemeId\n响应: $respBody');
    }

    try {
      final info = _mapToVideoInfo(root['data'] as Map<String, dynamic>);
      _debugLog('mapToVideoInfo ok, isVideo=${info.isVideo}, imageList.len=${info.imageList.length}, url=${info.url}');
      return info;
    } catch (e, s) {
      final data = root['data'] as Map<String, dynamic>?;
      _debugLog('mapToVideoInfo FAILED: $e');
      _debugLog('data.type=${data?['type']}, data.downloads type=${data?['downloads']?.runtimeType}');
      await LogService.logError('SelfHosted.mapToVideoInfo', e, s);
      throw Exception('数据映射失败: $e\ntype=${data?['type']}\ndownloads.runtimeType=${data?['downloads']?.runtimeType}');
    }
  }

  static VideoInfo _mapToVideoInfo(Map<String, dynamic> d) {
    final type = d['type'] as String? ?? '';
    final isVideo = type == '视频';
    final isLive = type == '实况'; // 实况：downloads 是视频数组
    final downloads = d['downloads'];

    dynamic images;
    String videoUrl = '';

    if (isVideo) {
      // 单视频：downloads 是字符串
      videoUrl = downloads as String? ?? '';
      images = '当前为短视频解析模式';
    } else if (isLive) {
      // 实况：downloads 是混合数组，视频URL含 video_id= 或 /play/，图片URL含 douyinpic
      final allItems = (downloads as List?)?.map((e) => e.toString()).toList() ?? [];
      final videoClips = allItems.where((u) => u.contains('video_id=') || u.contains('/play/')).toList();
      final imageClips = allItems.where((u) => !u.contains('video_id=') && !u.contains('/play/')).toList();
      // 视频片段在前，图片在后
      final allClips = [...videoClips, ...imageClips];
      videoUrl = videoClips.isNotEmpty ? videoClips[0] : '';
      images = allClips.length > 1
          ? '实况:${allClips.join('\n')}'
          : '当前为短视频解析模式';
    } else {
      // 图集：downloads 是图片URL数组
      images = (downloads as List?)?.map((e) => e.toString()).toList() ?? [];
      videoUrl = '';
    }

    // 封面：优先 static_cover，fallback dynamic_cover
    final cover = (d['static_cover'] as String?)?.isNotEmpty == true
        ? d['static_cover'] as String
        : (d['dynamic_cover'] as String? ?? '');

    // 时长转毫秒：格式 "00:00:18"
    final duration = _parseDuration(d['duration'] as String? ?? '');

    return VideoInfo.fromJson({
      'author': d['nickname'] ?? '',
      'uid': d['uid']?.toString() ?? '',
      'avatar': '', // 接口没有头像字段
      'like': d['digg_count'] ?? 0,
      'time': d['create_timestamp'] ?? 0,
      'title': d['desc'] ?? '',
      'cover': cover,
      'images': images,
      'url': videoUrl,
      'duration': duration,
      'music': {
        'title': d['music_title'] ?? '',
        'author': d['music_author'] ?? '',
        'avatar': '',
        'url': d['music_url'] ?? '',
      },
    });
  }

  /// "00:00:18" → 毫秒
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
