import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_info.dart';

class ApiService {
  static const String baseUrl = 'https://api.hk0.cc/api/douyin';

  static Future<VideoInfo> parseVideo(String url) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {'url': url});
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          return VideoInfo.fromJson(data['data']);
        } else {
          throw Exception(data['msg'] ?? '解析失败');
        }
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('请求超时，请检查网络连接');
      }
      rethrow;
    }
  }
}
