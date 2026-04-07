import 'package:flutter/material.dart';
import '../models/video_info.dart';
import '../services/history_service.dart';
import 'video_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<VideoInfo> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(int index) async {
    await _historyService.deleteHistory(index);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载历史'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('暂无历史记录'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final video = _history[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          video.cover,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(video.author),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoDetailScreen(videoInfo: video),
                          ),
                        );
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('删除记录'),
                            content: const Text('确定要删除这条记录吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteItem(index);
                                },
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
