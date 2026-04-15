import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'floating_window_service.dart';
import 'settings_service.dart';

class DownloadService {
    final Dio _dio = Dio(BaseOptions(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36',
        'Referer': 'https://www.douyin.com/',
        'Accept-Language': 'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
      },
    ));

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdkInt >= 33) {
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      return photos.isGranted && videos.isGranted;
    } else {
      return (await Permission.storage.request()).isGranted;
    }
  }

  /// 清理文件名中的非法字符，并截断长度
  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|\n\r]'), '_').trim();

  String _truncate(String s, int max) =>
      s.length > max ? s.substring(0, max) : s;

  /// 过滤 #话题标签，清理非法字符，截断长度
  String _cleanTitle(String title) {
    // 去掉 #xxx 标签（含中英文话题）
    final noHash = title.replaceAll(RegExp(r'#\S+'), '').trim();
    return _truncate(_sanitize(noHash), 20);
  }

  /// 构建文件名：日期时间_标题_作者名_uid
  String buildFileName(String prefix, String ext, String author, String title, String uid) {
    final now = DateTime.now();
    final ts = '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final parts = <String>[prefix, ts];
    if (title.isNotEmpty) parts.add(_cleanTitle(title));
    if (author.isNotEmpty) parts.add(_sanitize(author));
    if (uid.isNotEmpty) parts.add(_sanitize(uid));
    return '${parts.join('_')}.$ext';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// 构建相册路径：相册名 或 相册名/发布者名称(ID)（按作者分组时）
  Future<String> buildAlbumPath(String albumName, String author, String uid) async {
    final groupByAuthor = await SettingsService.getGroupByAuthor();
    if (groupByAuthor && author.isNotEmpty) {
      final folderName = uid.isNotEmpty
          ? '${_sanitize(author)}($uid)'
          : _sanitize(author);
      return '$albumName/$folderName';
    }
    return albumName;
  }

  Future<void> downloadFile(
    String url,
    String fileName,
    String albumName,
    Function(int, int)? onProgress,
  ) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('需要存储权限才能下载文件，请在设置中授予权限');
    }

    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$fileName';
    final tmpFile = File(savePath);

    try {
      // 1080p 下载失败时自动降级到 720p
      try {
        await _dio.download(url, savePath, onReceiveProgress: onProgress);
      } on DioException catch (e) {
        if (url.contains('ratio=1080p') &&
            (e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.receiveTimeout ||
             e.type == DioExceptionType.badResponse)) {
          final fallbackUrl = url.replaceAll('ratio=1080p', 'ratio=720p');
          await _dio.download(fallbackUrl, savePath, onReceiveProgress: onProgress);
        } else {
          rethrow;
        }
      }

      await FloatingWindowService.saveFileToGallery(savePath, fileName, albumName);
    } on DioException catch (e) {
      throw Exception(_friendlyDioError(e));
    } catch (e) {
      throw Exception('下载失败: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      // 无论成功失败都清理临时文件
      if (await tmpFile.exists()) await tmpFile.delete();
    }
  }

  String _friendlyDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络超时，请检查网络连接后重试';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 403) return '视频链接已过期，请重新解析';
        if (code == 404) return '视频资源不存在';
        return '服务器错误 ($code)，请稍后重试';
      case DioExceptionType.cancel:
        return '下载已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络';
      default:
        return '下载失败: ${e.message}';
    }
  }
}
