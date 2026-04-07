import 'package:flutter/material.dart';
import '../services/floating_window_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _floatingEnabled = false;
  bool _hasOverlayPermission = false;
  final _albumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _albumController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _load() async {
    final enabled = await SettingsService.getFloatingWindowEnabled();
    final albumName = await SettingsService.getAlbumName();
    await _checkPermission();
    setState(() {
      _floatingEnabled = enabled;
      _albumController.text = albumName;
    });
  }

  Future<void> _checkPermission() async {
    final has = await FloatingWindowService.hasOverlayPermission();
    if (mounted) setState(() => _hasOverlayPermission = has);
  }

  Future<void> _toggleFloating(bool value) async {
    if (value && !_hasOverlayPermission) {
      await FloatingWindowService.requestOverlayPermission();
      return;
    }
    await SettingsService.setFloatingWindowEnabled(value);
    if (value) {
      await FloatingWindowService.start();
    } else {
      await FloatingWindowService.stop();
    }
    setState(() => _floatingEnabled = value);
  }

  Future<void> _saveAlbumName() async {
    await SettingsService.setAlbumName(_albumController.text);
    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('相册名称已保存'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1677FF);

    return Scaffold(
      appBar: AppBar(title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('悬浮窗'),
          _card(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('启用悬浮窗', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _hasOverlayPermission ? '点击悬浮窗自动读取剪贴板并解析' : '需要先授予悬浮窗权限',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasOverlayPermission ? Colors.grey : Colors.orange,
                    ),
                  ),
                  value: _floatingEnabled,
                  activeColor: primary,
                  onChanged: _toggleFloating,
                ),
                if (!_hasOverlayPermission) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.security_rounded, color: Colors.orange, size: 20),
                    title: const Text('前往授权悬浮窗权限', style: TextStyle(fontSize: 14, color: Colors.orange)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
                    onTap: () async {
                      await FloatingWindowService.requestOverlayPermission();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('下载设置'),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('相册名称', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('视频和图片将保存到该相册下',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _albumController,
                          decoration: InputDecoration(
                            hintText: '抖音下载',
                            prefixIcon: const Icon(Icons.photo_album_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _saveAlbumName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size(64, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
  );

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}
