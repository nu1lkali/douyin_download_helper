import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/link_extractor.dart';
import '../services/api_service.dart';
import '../services/floating_window_service.dart';
import '../services/settings_service.dart';
import 'video_detail_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  DateTime? _lastBackPressed;

  static const _primary = Color(0xFF1677FF);

  @override
  void initState() {
    super.initState();
    FloatingWindowService.setClipboardHandler((text) {
      if (mounted) {
        setState(() => _controller.text = text);
        _parseVideo(replaceRoute: true);
      }
    });
    _restoreFloatingWindow();
  }

  Future<void> _restoreFloatingWindow() async {
    final enabled = await SettingsService.getFloatingWindowEnabled();
    if (enabled && await FloatingWindowService.hasOverlayPermission()) {
      final compact = await SettingsService.getFloatingCompactMode();
      FloatingWindowService.start(compactMode: compact);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次退出'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _parseVideo({bool replaceRoute = false}) async {
    final text = _controller.text.trim();
    final link = LinkExtractor.extractLink(text);
    if (link == null) {
      _showError('未找到有效的抖音视频链接');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final videoInfo = await ApiService.parseVideo(link);
      if (mounted) {
        final route = MaterialPageRoute(
          builder: (_) => VideoDetailScreen(videoInfo: videoInfo),
        );
        if (replaceRoute) {
          // 悬浮窗触发：替换当前详情页，不叠加
          Navigator.pushAndRemoveUntil(
            context, route,
            (r) => r.isFirst, // 保留首页，移除所有详情页
          );
        } else {
          Navigator.push(context, route);
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) setState(() => _controller.text = data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasText = _controller.text.trim().isNotEmpty;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF2F6FF),
          body: Column(
            children: [
              // 顶部蓝色 header 区域（延伸到状态栏）
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1677FF), Color(0xFF4096FF)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: topPadding),
                    // 顶栏
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const Text('便捷下载',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.history_rounded, color: Colors.white),
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HistoryScreen())),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_rounded, color: Colors.white),
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          ),
                        ],
                      ),
                    ),
                    // Logo + 副标题
                    const SizedBox(height: 16),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.download_rounded, color: _primary, size: 38),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '粘贴链接，一键下载无水印内容',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),

              // 主体内容
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 输入框卡片
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _controller,
                              maxLines: 5,
                              minLines: 3,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: '粘贴抖音分享链接或分享口令...',
                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            // 操作按钮行
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: _pasteFromClipboard,
                                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                                    label: const Text('粘贴'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: hasText
                                        ? () => setState(() => _controller.clear())
                                        : null,
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    label: const Text('清空'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      disabledForegroundColor: Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 解析按钮
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: hasText && !_isLoading ? _parseVideo : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            disabledBackgroundColor: Colors.grey[200],
                            disabledForegroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: hasText ? 4 : 0,
                            shadowColor: _primary.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('解析视频',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 使用说明
                      _tipCard(),

                      const SizedBox(height: 20),

                      // 版权信息
                      Center(
                        child: Text(
                          '© HACKFUN',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: _primary),
              ),
              const SizedBox(width: 8),
              const Text('使用说明',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          _tipItem('复制抖音视频分享链接或口令'),
          _tipItem('粘贴到输入框，点击解析'),
          _tipItem('支持短视频和图集无水印下载'),
        ],
      ),
    );
  }

  Widget _tipItem(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
            color: _primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    ),
  );
}
