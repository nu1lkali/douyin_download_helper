import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';
import 'settings_service.dart';
import 'log_service.dart';

/// 自建接口 V2 解析服务
/// 接口：GET /api/hybrid/video_data?url=...
/// 返回原始抖音数据，字段结构与本地解析完全一致
class SelfHostedV2ApiService {
  static Future<VideoInfo> parse(String inputText) async {
    final url = await SettingsService.getSelfHostedV2Url();
    final token = await SettingsService.getSelfHostedV2Token();
    if (url.isEmpty) throw Exception('请先在设置中配置自建接口 V2 地址');
    
    final cookie = await SettingsService.getCookie();

    await LogService.log('SelfHostedV2', 'parse raw input: $inputText');

    // 1. 从输入文本中正则提取真正的 http/https 链接（防止传入带有空格、中文或换行符的口令导致 400）
    final regExp = RegExp(r'https?://[^\s]+');
    final match = regExp.firstMatch(inputText);
    final cleanUrl = match != null ? match.group(0)! : inputText.trim();

    // 2. 规范化构建 URI，Dart 会自动对 queryParameters 进行安全的 URL 编码
    final parsedBase = Uri.parse(url.trim());
    final basePath = parsedBase.path.replaceAll(RegExp(r'/+$'), '');
    final uri = parsedBase.replace(
      path: '$basePath/api/hybrid/video_data',
      queryParameters: {'url': cleanUrl},
    );

    await LogService.log('SelfHostedV2', 'request uri: ${uri.toString()}');

    // 3. 清理 Token 和 Cookie 中的换行符与多余空格（非法字符会导致 Header 解析抛出 400）
    final cleanToken = token.replaceAll(RegExp(r'[\r\n]'), '').trim();
    final cleanCookie = cookie.replaceAll(RegExp(r'[\r\n]'), '').trim();

    http.Response resp;
    try {
      resp = await http.get(uri, headers: {
        if (cleanToken.isNotEmpty) 'token': cleanToken,
        if (cleanCookie.isNotEmpty) 'Cookie': cleanCookie,
      }).timeout(const Duration(seconds: 60));
    } catch (e, s) {
      await LogService.logError('SelfHostedV2', e, s);
      throw Exception('V2 请求异常: $e');
    }

    await LogService.log('SelfHostedV2', 'status: ${resp.statusCode}');
    if (resp.statusCode != 200) {
      throw Exception('请求失败: ${resp.statusCode}\n${resp.body}');
    }

    final root = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if ((root['code'] as int? ?? 0) != 200) {
      throw Exception('接口返回错误: ${root['message'] ?? root['msg'] ?? '未知错误'}');
    }

    final item = root['data'] as Map<String, dynamic>;
    return _parseItem(item);
  }

  static VideoInfo _parseItem(Map<String, dynamic> item) {
    final author = (item['author'] as Map<String, dynamic>?) ?? {};
    final video = (item['video'] as Map<String, dynamic>?) ?? {};
    final music = (item['music'] as Map<String, dynamic>?) ?? {};
    final statistics = (item['statistics'] as Map<String, dynamic>?) ?? {};

    // 头像
    final avatarThumb = (author['avatar_thumb'] as Map?)?.cast<String, dynamic>() ?? {};
    final avatarList = (avatarThumb['url_list'] as List?) ?? [];
    final avatar = avatarList.isNotEmpty ? avatarList[0] as String : '';

    // 类型判断：aweme_type 0=视频, 2/68=图集/实况
    final awemeType = item['aweme_type'] as int? ?? 0;
    final isImage = awemeType == 2 || awemeType == 68;

    // 视频 URL
    final playAddr = (video['play_addr'] as Map<String, dynamic>?) ?? {};
    final urlList = (playAddr['url_list'] as List?) ?? [];
    final uri = playAddr['uri'] as String? ?? '';
    String videoUrl = '';
    if (urlList.isNotEmpty) {
      videoUrl = (urlList[0] as String)
          .replaceAll('playwm', 'play')
          .replaceAll('ratio=720p', 'ratio=1080p')
          .replaceAll('ratio=540p', 'ratio=1080p')
          .replaceAll('ratio=480p', 'ratio=1080p');
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

    // 图集 / 实况
    dynamic images;
    if (isImage) {
      final rawImages = item['images'] as List? ?? [];
      // 实况：每个 image 有 video 字段且 play_addr.url_list 有内容
      final isLive = rawImages.isNotEmpty && (() {
        final firstImg = rawImages[0] as Map<String, dynamic>;
        final v = (firstImg['video'] as Map?)?.cast<String, dynamic>() ?? {};
        final pa = (v['play_addr'] as Map?)?.cast<String, dynamic>() ?? {};
        final ul = (pa['url_list'] as List?) ?? [];
        return ul.isNotEmpty;
      })();

      if (isLive) {
        // 混合实况：每个 image 单独判断，有 video 取视频片段，没有取静图
        final clips = <String>[];
        final staticImgs = <String>[];
        for (final img in rawImages) {
          final imgMap = img as Map<String, dynamic>;
          final clipVideo = (imgMap['video'] as Map?)?.cast<String, dynamic>() ?? {};
          final clipPlayAddr = (clipVideo['play_addr'] as Map?)?.cast<String, dynamic>() ?? {};
          final clipUrls = (clipPlayAddr['url_list'] as List?) ?? [];
          if (clipUrls.isNotEmpty) {
            // 有视频片段
            clips.add(clipUrls[0] as String);
          } else {
            // 普通静图
            final imgUrls = (imgMap['url_list'] as List?) ?? [];
            if (imgUrls.isNotEmpty) staticImgs.add(imgUrls[0] as String);
          }
        }
        final allClips = [...clips, ...staticImgs];
        images = allClips.isNotEmpty ? '实况:${allClips.join('\n')}' : '当前为短视频解析模式';
        videoUrl = clips.isNotEmpty ? clips[0] : '';
      } else {
        // 普通图集
        images = rawImages.map((img) {
          final imgMap = img as Map<String, dynamic>;
          final noWmList = (imgMap['url_list'] as List?) ?? [];
          return noWmList.isNotEmpty ? noWmList[0] as String : '';
        }).where((u) => u.isNotEmpty).toList();
      }
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
      uid: _notEmpty([author['short_id'], author['unique_id'], author['uid']]),
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

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _notEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty && s != '0') return s;
    }
    return '';
  }
}