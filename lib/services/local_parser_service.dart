import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';

/// 本地解析逻辑
///
/// 核心方案（来自 douyin-download-main/douyin.js）：
/// 1. 短链 → 跟随重定向 → 提取 aweme_id
/// 2. 请求 https://www.iesdouyin.com/share/video/{aweme_id}/
///    使用 iPhone UA，无需 Cookie，无需 A-Bogus
/// 3. 从 HTML 中提取 window._ROUTER_DATA JSON
/// 4. 从 loaderData['video_(id)/page'].videoInfoRes.item_list[0] 取数据
/// 5. video.play_addr.url_list[0].replace('playwm', 'play') 得到无水印URL
class LocalParserService {
  // 必须用 iPhone UA，否则 iesdouyin 不返回 _ROUTER_DATA
  static const _ua =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'EdgiOS/121.0.2277.107 Version/17.0 Mobile/15E148 Safari/604.1';

  final String? cookie;
  LocalParserService({this.cookie});

  Map<String, String> get _headers => {
        'User-Agent': _ua,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        if (cookie != null && cookie!.isNotEmpty) 'Cookie': cookie!,
      };

  Future<VideoInfo> parse(String url) async {
    final awemeId = await getAwemeId(url);
    return fetchVideoInfo(awemeId);
  }

  Future<String> getAwemeId(String url) async {
    // 先检查是否直接是数字ID
    if (RegExp(r'^\d{16,}$').hasMatch(url.trim())) return url.trim();

    String realUrl = url;
    if (url.contains('v.douyin.com')) {
      realUrl = await _followRedirect(url);
    }
    final id = _extractAwemeId(realUrl);
    if (id == null) throw Exception('无法从链接中提取视频ID');
    return id;
  }

  Future<String> _followRedirect(String url) async {
    final client = http.Client();
    try {
      String current = url;
      for (int i = 0; i < 10; i++) {
        final req = http.Request('GET', Uri.parse(current))
          ..followRedirects = false
          ..headers.addAll(_headers);
        final resp = await client.send(req);
        if (resp.statusCode >= 300 && resp.statusCode < 400) {
          final loc = resp.headers['location'];
          if (loc == null) break;
          current = loc.startsWith('http') ? loc : Uri.parse(current).resolve(loc).toString();
        } else {
          break;
        }
      }
      return current;
    } finally {
      client.close();
    }
  }

  String? _extractAwemeId(String url) {
    final patterns = [
      RegExp(r'/video/(\d+)'),
      RegExp(r'/note/(\d+)'),
      RegExp(r'modal_id=(\d+)'),
      RegExp(r'[?&]vid=(\d+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  Future<VideoInfo> fetchVideoInfo(String awemeId) async {
    final url = 'https://www.iesdouyin.com/share/video/$awemeId/';
    final resp = await http.get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) throw Exception('请求失败: ${resp.statusCode}');
    if (resp.body.isEmpty) throw Exception('响应为空');

    // 提取 window._ROUTER_DATA = {...}</script>
    final match = RegExp(
      r'window\._ROUTER_DATA\s*=\s*(.*?)</script>',
      dotAll: true,
    ).firstMatch(resp.body);

    if (match == null) throw Exception('无法从页面中提取视频数据，请检查链接是否有效');

    final jsonStr = match.group(1)!.trim();
    final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
    final loaderData = (jsonData['loaderData'] ?? jsonData) as Map<String, dynamic>;

    // 视频页或图集页
    Map<String, dynamic>? pageData =
        loaderData['video_(id)/page'] as Map<String, dynamic>? ??
        loaderData['note_(id)/page'] as Map<String, dynamic>?;

    if (pageData == null) throw Exception('无法解析页面数据');

    final videoInfoRes = pageData['videoInfoRes'] as Map<String, dynamic>?;
    final itemList = videoInfoRes?['item_list'] as List?;
    if (itemList == null || itemList.isEmpty) throw Exception('未找到视频信息');

    return _parseItem(itemList[0] as Map<String, dynamic>);
  }

  VideoInfo _parseItem(Map<String, dynamic> item) {
    final author = (item['author'] as Map<String, dynamic>?) ?? {};
    final video = (item['video'] as Map<String, dynamic>?) ?? {};
    final music = (item['music'] as Map<String, dynamic>?) ?? {};
    final statistics = (item['statistics'] as Map<String, dynamic>?) ?? {};

    // 作者头像
    final avatarLarger = (author['avatar_larger'] as Map?)?.cast<String, dynamic>() ?? {};
    final avatarList = (avatarLarger['url_list'] as List?) ?? [];
    final avatar = avatarList.isNotEmpty ? avatarList[0] as String : '';

    // 视频/图集判断
    final awemeType = item['aweme_type'] as int? ?? 0;
    final isImage = awemeType == 2 || awemeType == 68;

    // 无水印视频URL
    final playAddr = (video['play_addr'] as Map<String, dynamic>?) ?? {};
    final urlList = (playAddr['url_list'] as List?) ?? [];
    final uri = playAddr['uri'] as String? ?? '';

    String videoUrl = '';
    if (urlList.isNotEmpty) {
      videoUrl = (urlList[0] as String).replaceAll('playwm', 'play');
    }
    if (videoUrl.isEmpty && uri.isNotEmpty) {
      videoUrl = 'https://aweme.snssdk.com/aweme/v1/play/?video_id=$uri&ratio=1080p&line=0';
    }

    // 封面
    final originCover = (video['origin_cover'] as Map?)?.cast<String, dynamic>() ?? {};
    final coverFallback = (video['cover'] as Map?)?.cast<String, dynamic>() ?? {};
    final originCoverList = (originCover['url_list'] as List?) ?? [];
    final coverList = (coverFallback['url_list'] as List?) ?? [];
    final cover = originCoverList.isNotEmpty
        ? originCoverList[0] as String
        : (coverList.isNotEmpty ? coverList[0] as String : '');

    // 图集
    dynamic images;
    if (isImage) {
      final rawImages = item['images'] as List? ?? [];
      images = rawImages.map((img) {
        final imgMap = img as Map<String, dynamic>;
        final noWmList = (imgMap['url_list'] as List?) ?? [];
        return noWmList.isNotEmpty ? noWmList[0] as String : '';
      }).where((u) => u.isNotEmpty).toList();
    } else {
      images = '当前为短视频解析模式';
    }

    // 音乐
    final musicCoverLarge = (music['cover_large'] as Map?)?.cast<String, dynamic>() ?? {};
    final musicCoverList = (musicCoverLarge['url_list'] as List?) ?? [];
    final musicAvatar = musicCoverList.isNotEmpty ? musicCoverList[0] as String : '';
    final musicPlayUrl = (music['play_url'] as Map?)?.cast<String, dynamic>() ?? {};
    final musicUrlList = (musicPlayUrl['url_list'] as List?) ?? [];
    final musicUrl = musicUrlList.isNotEmpty ? musicUrlList[0] as String : '';

    return VideoInfo(
      author: author['nickname'] as String? ?? '',
      uid: (author['uid'] ?? '').toString(),
      avatar: avatar,
      like: _parseInt(statistics['digg_count']),
      time: _parseInt(item['create_time']),
      title: item['desc'] as String? ?? '',
      cover: cover,
      images: images,
      url: videoUrl,
      duration: _parseInt(video['duration']),
      music: MusicInfo(
        title: music['title'] as String? ?? '',
        author: music['author'] as String? ?? '',
        avatar: musicAvatar,
        url: musicUrl,
      ),
    );
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
