import 'package:flutter/services.dart';

class FloatingWindowService {
  static const _channel = MethodChannel('com.example.douyin_downloader/floating');

  static Future<bool> hasOverlayPermission() async {
    return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<void> start() async {
    await _channel.invokeMethod('startFloatingWindow');
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
      }
    });
  }
}
