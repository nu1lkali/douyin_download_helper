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
      final historyJson = prefs.getString(_key);
      if (historyJson == null) return [];
      
      final List<dynamic> history = json.decode(historyJson);
      return history.map((item) => VideoInfo.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
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
