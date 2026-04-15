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
   
    final base = url.replaceAll(RegExp(r'/+$'), '');
    final cookie = await SettingsService.getCookie();

    await LogService.log('SelfHostedV2', 'parse: $inputText');

    final uri = Uri.parse('$base/api/hybrid/video_data').replace(
      queryParameters: {'url': inputText},
    );

    http.Response resp;
    try {
      resp = await http.get(uri, headers: {
        if (token.isNotEmpty) 'token': token,
        if (cookie.isNotEmpty) 'Cookie': cookie,
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
      // 实况：每个 image 有 video 字段
      final isLive = rawImages.isNotEmpty &&
          (rawImages[0] as Map?)?.containsKey('video') == true &&
          ((rawImages[0] as Map)['video'] as Map?)?.isNotEmpty == true;

      if (isLive) {
        // 实况：收集每个 clip 的视频 URL + 静态图 URL
        final clips = <String>[];
        for (final img in rawImages) {
          final imgMap = img as Map<String, dynamic>;
          final clipVideo = (imgMap['video'] as Map?)?.cast<String, dynamic>() ?? {};
          final clipPlayAddr = (clipVideo['play_addr'] as Map?)?.cast<String, dynamic>() ?? {};
          final clipUrls = (clipPlayAddr['url_list'] as List?) ?? [];
          if (clipUrls.isNotEmpty) clips.add(clipUrls[0] as String);
        }
        // 再收集静态图
        final staticImgs = <String>[];
        for (final img in rawImages) {
          final imgMap = img as Map<String, dynamic>;
          final imgUrls = (imgMap['url_list'] as List?) ?? [];
          if (imgUrls.isNotEmpty) staticImgs.add(imgUrls[0] as String);
        }
        final allClips = [...clips, ...staticImgs];
        images = allClips.length > 1 ? '实况:${allClips.join('\n')}' : '当前为短视频解析模式';
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
