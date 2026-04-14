import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';

class FloatingWindowService {
  static const _channel = MethodChannel('com.example.douyin_downloader/floating');

  static Future<bool> hasOverlayPermission() async {
    return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<void> start({bool compactMode = false}) async {
    await _channel.invokeMethod('startFloatingWindow', {'compact_mode': compactMode});
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopFloatingWindow');
  }

  static Future<void> saveFileToGallery(String filePath, String fileName, String albumName) async {
    await _channel.invokeMethod('saveFileToGallery', {
      'filePath': filePath,
      'fileName': fileName,
      'albumName': albumName,
    });
  }

  static void setClipboardHandler(Function(String) onText) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onClipboardText') {
        onText(call.arguments as String);
      } else if (call.method == 'onCompactParse') {
        final text = call.arguments as String;
        _handleCompactParse(text);
      } else if (call.method == 'onCompactDownload') {
        final args = call.arguments as Map;
        _handleCompactDownload(
          args['url'] as String,
          args['album'] as String,
          args['isImages'] as bool,
        );
      } else if (call.method == 'addHistory') {
        // 简洁模式解析完成后，Kotlin 侧通知 Flutter 写入历史记录
        try {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final videoInfo = VideoInfo.fromJson(args);
          await HistoryService().addHistory(videoInfo);
        } catch (_) {}
      } else if (call.method == 'addHistoryBatch') {
        // app 启动时冲刷积压的历史记录（app 不在前台时缓存的）
        try {
          final jsonStr = call.arguments as String;
          final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
          final svc = HistoryService();
          for (final item in list) {
            await svc.addHistory(VideoInfo.fromJson(item));
          }
        } catch (_) {}
      }
    });
  }

  static Future<void> _handleCompactParse(String text) async {
    try {
      final videoInfo = await ApiService.parseVideo(text);
      final albumName = await SettingsService.getAlbumName();
      // 添加到历史记录
      final historyService = HistoryService();
      await historyService.addHistory(videoInfo);
      print('简洁模式解析结果已保存到历史记录: ${videoInfo.title}');
      // 通知 Kotlin 侧解析结果
      await _channel.invokeMethod('compactParseResult', {
        'success': true,
        'title': videoInfo.title,
        'author': videoInfo.author,
        'isVideo': videoInfo.isVideo,
        'videoUrl': videoInfo.url,
        'imageCount': videoInfo.imageList.length,
        'imageUrls': videoInfo.imageList,
        'albumName': albumName,
      });
    } catch (e) {
      print('简洁模式解析失败: $e');
      await _channel.invokeMethod('compactParseResult', {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      });
    }
  }

  static Future<void> _handleCompactDownload(String url, String albumName, bool isImages) async {
    try {
      final ds = DownloadService();
      if (!isImages) {
        final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        await ds.downloadFile(url, fileName, albumName, null);
      }
      await _channel.invokeMethod('compactDownloadDone', {'success': true});
    } catch (e) {
      await _channel.invokeMethod('compactDownloadDone', {'success': false, 'error': e.toString()});
    }
  }
}
