import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'floating_window_service.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      return photos.isGranted && videos.isGranted;
    } else {
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
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

    // 通过原生MethodChannel保存到相册
    await FloatingWindowService.saveFileToGallery(savePath, fileName, albumName);

    // 删除临时文件
    final file = File(savePath);
    if (await file.exists()) await file.delete();
  }
}
