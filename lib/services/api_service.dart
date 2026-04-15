import '../models/video_info.dart';
import 'settings_service.dart';
import 'local_parser_service.dart';
import 'self_hosted_api_service.dart';
import 'self_hosted_v2_api_service.dart';
import 'log_service.dart';

class ApiService {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const _cacheDuration = Duration(minutes: 30);

  static Future<VideoInfo> parseVideo(String url) async {
    final cached = _cache[url];
    if (cached != null && (cached['expire'] as DateTime).isAfter(DateTime.now())) {
      await LogService.log('ApiService', 'cache hit: $url');
      return cached['data'] as VideoInfo;
    }

    final mode = await SettingsService.getParseMode();
    await LogService.log('ApiService', 'parseVideo mode=$mode url=$url');

    try {
      final VideoInfo result;
      switch (mode) {
        case ParseMode.local:
          result = await _parseLocal(url);
        case ParseMode.selfHostedV2:
          result = await SelfHostedV2ApiService.parse(url);
        default:
          result = await SelfHostedApiService.parse(url);
      }
      _cache[url] = {'data': result, 'expire': DateTime.now().add(_cacheDuration)};
      return result;
    } catch (e, s) {
      await LogService.logError('ApiService', e, s);
      rethrow;
    }
  }

  static void clearCache() => _cache.clear();

  static Future<VideoInfo> _parseLocal(String url) async {
    final cookie = await SettingsService.getCookie();
    final parser = LocalParserService(cookie: cookie.isEmpty ? null : cookie);
    return parser.parse(url);
  }
}
