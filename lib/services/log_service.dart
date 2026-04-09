import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class LogService {
  static File? _logFile;
  static const _maxSize = 20 * 1024 * 1024; // 20MB

  static Future<File> _getFile() async {
    if (_logFile != null) return _logFile!;
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/app_debug.log');
    return _logFile!;
  }

  static Future<void> log(String tag, String message) async {
    try {
      final file = await _getFile();
      final now = DateTime.now().toIso8601String();
      final line = '[$now][$tag] $message\n';

      // 超过2MB清空重写
      if (await file.exists() && await file.length() > _maxSize) {
        await file.writeAsString(line);
      } else {
        await file.writeAsString(line, mode: FileMode.append);
      }
    } catch (_) {}
  }

  static Future<void> logError(String tag, dynamic error, [StackTrace? stack]) async {
    await log(tag, 'ERROR: $error');
    if (stack != null) await log(tag, 'STACK: $stack');
  }

  static Future<String> readLogs() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return '暂无日志';
      // 用 allowMalformed 容错非UTF-8字符
      final bytes = await file.readAsBytes();
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    } catch (e) {
      return '读取日志失败: $e';
    }
  }

  static Future<String> getLogPath() async {
    final file = await _getFile();
    return file.path;
  }

  static Future<void> clearLogs() async {
    try {
      final file = await _getFile();
      if (await file.exists()) await file.writeAsString('');
    } catch (_) {}
  }
}
