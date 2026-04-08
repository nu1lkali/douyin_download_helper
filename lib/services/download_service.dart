import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'floating_window_service.dart';
import 'settings_service.dart';

class DownloadService {
  final Dio _dio = Dio();

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

  /// 构建相册路径：相册名 或 相册名/作者名（按作者分组时）
  Future<String> buildAlbumPath(String albumName, String author) async {
    final groupByAuthor = await SettingsService.getGroupByAuthor();
    if (groupByAuthor && author.isNotEmpty) {
      return '$albumName/${_sanitize(author)}';
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

    await _dio.download(url, savePath, onReceiveProgress: onProgress);
    await FloatingWindowService.saveFileToGallery(savePath, fileName, albumName);

    final file = File(savePath);
    if (await file.exists()) await file.delete();
  }
}
