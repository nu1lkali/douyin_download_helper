import 'package:flutter/material.dart';
import '../models/video_info.dart';
import '../services/download_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoInfo videoInfo;
  const VideoDetailScreen({super.key, required this.videoInfo});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final DownloadService _downloadService = DownloadService();
  final HistoryService _historyService = HistoryService();
  bool _isDownloading = false;
  double _progress = 0;
  String _albumName = '无水印下载';

  static const _primary = Color(0xFF1677FF);

  @override
  void initState() {
    super.initState();
    _historyService.addHistory(widget.videoInfo);
    SettingsService.getAlbumName().then((v) => setState(() => _albumName = v));
  }

  bool get isVideo => widget.videoInfo.isVideo;
  bool get isLive => widget.videoInfo.isLive;
  List<String> get imageList => widget.videoInfo.imageList;
  List<String> get liveClips => widget.videoInfo.liveClips;

  Future<void> _downloadVideo() async {
    setState(() { _isDownloading = true; _progress = 0; });
    try {
      final author = widget.videoInfo.author;
      final title = widget.videoInfo.title;
      final uid = widget.videoInfo.uid;
      final album = await _downloadService.buildAlbumPath(_albumName, author, uid);
      final fileName = _downloadService.buildFileName('video', 'mp4', author, title, uid);
      await _downloadService.downloadFile(widget.videoInfo.url, fileName, album,
        (received, total) { if (total > 0) setState(() => _progress = received / total); });
      if (mounted) _showSnack('视频已保存到相册');
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadAllImages() async {
    setState(() { _isDownloading = true; _progress = 0; });
    int success = 0, failed = 0;
    final total = imageList.length;
    try {
      final author = widget.videoInfo.author;
      final title = widget.videoInfo.title;
      final uid = widget.videoInfo.uid;
      final album = await _downloadService.buildAlbumPath(_albumName, author, uid);
      for (int i = 0; i < total; i++) {
        try {
          final url = imageList[i];
          final isVideoUrl = url.contains('video_id=') || url.contains('/play/');
          final ext = isVideoUrl ? 'mp4' : 'jpg';
          final prefix = isVideoUrl ? 'clip_$i' : 'img_$i';
          final fileName = _downloadService.buildFileName(prefix, ext, author, title, uid);
          await _downloadService.downloadFile(url, fileName, album,
            (received, fileTotal) {
              if (fileTotal > 0) {
                // 总进度 = 已完成文件占比 + 当前文件内进度
                final done = i / total;
                final current = (received / fileTotal) / total;
                setState(() => _progress = done + current);
              }
            });
          success++;
        } catch (_) {
          failed++;
        }
        // 每完成一个，进度跳到该文件对应的整数位置
        setState(() => _progress = (i + 1) / total);
      }
      if (mounted) {
        _showSnack(failed == 0
            ? '$total 个文件已保存到相册'
            : '下载完成：$success 个成功，$failed 个失败');
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadSingleImage(String url, int index) async {
    try {
      final author = widget.videoInfo.author;
      final title = widget.videoInfo.title;
      final uid = widget.videoInfo.uid;
      final album = await _downloadService.buildAlbumPath(_albumName, author, uid);
      final isVideoUrl = url.contains('video_id=') || url.contains('/play/');
      final ext = isVideoUrl ? 'mp4' : 'jpg';
      final prefix = isVideoUrl ? 'clip_$index' : 'img_$index';
      final fileName = _downloadService.buildFileName(prefix, ext, author, title, uid);
      await _downloadService.downloadFile(url, fileName, album, null);
      if (mounted) _showSnack(isVideoUrl ? '视频片段已保存到相册' : '图片已保存到相册');
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }
  }

  Future<void> _downloadLiveClips() async {
    setState(() { _isDownloading = true; _progress = 0; });
    int success = 0, failed = 0;
    final clips = liveClips;
    final total = clips.length;
    try {
      final author = widget.videoInfo.author;
      final title = widget.videoInfo.title;
      final uid = widget.videoInfo.uid;
      final album = await _downloadService.buildAlbumPath(_albumName, author, uid);
      for (int i = 0; i < total; i++) {
        try {
          final url = clips[i];
          final isVideoClip = url.contains('video_id=') || url.contains('/play/');
          final ext = isVideoClip ? 'mp4' : 'jpg';
          final prefix = isVideoClip ? 'clip_$i' : 'img_$i';
          final fileName = _downloadService.buildFileName(prefix, ext, author, title, uid);
          await _downloadService.downloadFile(url, fileName, album,
            (received, fileTotal) {
              if (fileTotal > 0) {
                final done = i / total;
                final current = (received / fileTotal) / total;
                setState(() => _progress = done + current);
              }
            });
          success++;
        } catch (_) {
          failed++;
        }
        setState(() => _progress = (i + 1) / total);
      }
      if (mounted) {
        _showSnack(failed == 0
            ? '$total 个片段已保存到相册'
            : '下载完成：$success 个成功，$failed 个失败');
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadCover() async {
    try {
      final author = widget.videoInfo.author;
      final title = widget.videoInfo.title;
      final uid = widget.videoInfo.uid;
      final album = await _downloadService.buildAlbumPath(_albumName, author, uid);
      final fileName = _downloadService.buildFileName('cover', 'jpg', author, title, uid);
      await _downloadService.downloadFile(widget.videoInfo.cover, fileName, album, null);
      if (mounted) _showSnack('封面已保存到相册');
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }
  }

  void _showSnack(String msg) {
    final clean = msg.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(clean),
        behavior: SnackBarBehavior.floating,
        backgroundColor: clean.contains('成功') || clean.contains('已保存')
            ? Colors.green[700]
            : null,
      ),
    );
  }

  void _openImageViewer(int initialIndex) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ImageViewerScreen(
        images: imageList,
        initialIndex: initialIndex,
        onSave: _downloadSingleImage,
      ),
    ));
  }

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isLive ? '实况详情' : (isVideo ? '视频详情' : '图集详情'),
          style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面/图集
            if (isVideo)
              _buildVideoCover()
            else
              _buildImageGrid(),

            const SizedBox(height: 12),

            // 信息卡片
            _card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.videoInfo.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(widget.videoInfo.avatar),
                          radius: 18,
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('@${widget.videoInfo.author}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statChip(Icons.favorite_rounded, '${widget.videoInfo.like}', Colors.redAccent),
                        const SizedBox(width: 8),
                        if (isLive)
                          _statChip(Icons.video_collection_rounded, '${liveClips.length} 个片段', Colors.orange)
                        else if (isVideo)
                          _statChip(Icons.access_time_rounded, _formatDuration(widget.videoInfo.duration), Colors.grey)
                        else
                          _statChip(Icons.photo_library_rounded, '${imageList.length} 张', _primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.videoInfo.music.title} - ${widget.videoInfo.music.author}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 下载区域
            _card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isDownloading) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation(_primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(_progress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isVideo) ...[
                      // 实况：只显示下载片段按钮
                      if (isLive) ...[
                        _dlButton(
                          icon: Icons.video_collection_rounded,
                          label: '下载全部片段（${liveClips.length}个）',
                          onTap: _isDownloading ? null : _downloadLiveClips,
                          full: true,
                        ),
                      ] else ...[
                        // 普通视频：两个并排按钮
                        Row(
                          children: [
                            Expanded(child: _dlButton(
                              icon: Icons.videocam_rounded,
                              label: '下载视频',
                              onTap: _isDownloading ? null : _downloadVideo,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _dlButton(
                              icon: Icons.image_rounded,
                              label: '下载封面',
                              onTap: _isDownloading ? null : _downloadCover,
                              outlined: true,
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _dlButton(
                          icon: Icons.download_for_offline_rounded,
                          label: '一键下载（视频+封面）',
                          onTap: _isDownloading ? null : () async {
                            await _downloadVideo();
                            await _downloadCover();
                          },
                          full: true,
                        ),
                      ],
                    ] else if (isLive) ...[
                      // 实况：下载所有片段
                      _dlButton(
                        icon: Icons.video_collection_rounded,
                        label: '下载全部片段（${liveClips.length}个）',
                        onTap: _isDownloading ? null : _downloadLiveClips,
                        full: true,
                      ),
                    ] else ...[
                      // 图集：只有一个按钮
                      _dlButton(
                        icon: Icons.download_for_offline_rounded,
                        label: '下载全部图片（${imageList.length}张）',
                        onTap: _isDownloading ? null : _downloadAllImages,
                        full: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCover() {
    // 实况没有封面，显示占位
    if (isLive) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[850]!, Colors.grey[900]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_collection_rounded, color: Colors.white70, size: 40),
            ),
            const SizedBox(height: 12),
            Text('实况 · ${liveClips.length} 个片段',
              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Live 实况暂无封面预览',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    final cover = widget.videoInfo.cover;
    if (cover.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        cover,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(index),
            onLongPress: () => _downloadSingleImage(imageList[index], index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageList[index], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    )),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
        blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _statChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _dlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool outlined = false,
    bool full = false,
  }) {
    final btn = outlined
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[200],
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          );
    return full ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// 图片全屏查看器
class _ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Future<void> Function(String url, int index) onSave;

  const _ImageViewerScreen({
    required this.images,
    required this.initialIndex,
    required this.onSave,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: '保存此图',
            onPressed: () async {
              await widget.onSave(widget.images[_currentIndex], _currentIndex);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('图片已保存到相册'),
                    behavior: SnackBarBehavior.floating),
                );
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onLongPress: () async {
          await widget.onSave(widget.images[_currentIndex], _currentIndex);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片已保存到相册'),
                behavior: SnackBarBehavior.floating),
            );
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) => InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
