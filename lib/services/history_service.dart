import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_info.dart';

class HistoryService {
  static const String _key = 'download_history';

  Future<void> addHistory(VideoInfo video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_key);
      List<dynamic> history = historyJson != null ? json.decode(historyJson) : [];
      
      // 去重：移除相同的记录
      history = history.where((item) {
        final existing = VideoInfo.fromJson(item as Map<String, dynamic>);
        // 视频：通过 videoUrl 去重
        if (video.isVideo) {
          return existing.url != video.url;
        }
        // 图集：通过第一张图片 URL 去重
        else {
          final existingImages = existing.imageList;
          final videoImages = video.imageList;
          if (existingImages.isEmpty || videoImages.isEmpty) {
            return true;
          }
          return existingImages[0] != videoImages[0];
        }
      }).toList();
      
      history.insert(0, video.toJson());
      
      if (history.length > 100) {
        history = history.sublist(0, 100);
      }
      
      await prefs.setString(_key, json.encode(history));
    } catch (e) {
      // 优雅处理错误
    }
  }

  Future<List<VideoInfo>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // 强制从磁盘重新加载，确保能读到 Kotlin 侧写入的数据
      final historyJson = prefs.getString(_key);
      if (historyJson == null) return [];
      
      final List<dynamic> history = json.decode(historyJson);
      return history.map((item) => VideoInfo.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {}
  }

  Future<void> deleteHistory(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_key);
      if (historyJson == null) return;
      
      List<dynamic> history = json.decode(historyJson);
      history.removeAt(index);
      
      await prefs.setString(_key, json.encode(history));
    } catch (e) {
      // 优雅处理错误
    }
  }
}
