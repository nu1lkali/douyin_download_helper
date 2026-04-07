import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    if (sdkInt >= 33) {
      return await Permission.photos.isGranted && await Permission.videos.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  static Future<bool> requestStoragePermission() async {
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
}
