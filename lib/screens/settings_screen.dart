import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
  bool _floatingCompact = false;
  final _albumController = TextEditingController();
  final _cookieController = TextEditingController();
  ParseMode _parseMode = ParseMode.remote;
  bool _showCookie = false;

  static const _primary = Color(0xFF1677FF);

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
    _cookieController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _load() async {
    final enabled = await SettingsService.getFloatingWindowEnabled();
    final albumName = await SettingsService.getAlbumName();
    final mode = await SettingsService.getParseMode();
    final cookie = await SettingsService.getCookie();
    final compact = await SettingsService.getFloatingCompactMode();
    await _checkPermission();
    setState(() {
      _floatingEnabled = enabled;
      _albumController.text = albumName;
      _parseMode = mode;
      _cookieController.text = cookie;
      _floatingCompact = compact;
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
      await FloatingWindowService.start(compactMode: _floatingCompact);
    } else {
      await FloatingWindowService.stop();
    }
    setState(() => _floatingEnabled = value);
  }

  Future<void> _saveAlbumName() async {
    await SettingsService.setAlbumName(_albumController.text);
    if (mounted) {
      FocusScope.of(context).unfocus();
      _showSnack('相册名称已保存');
    }
  }

  Future<void> _saveCookie() async {
    await SettingsService.setCookie(_cookieController.text);
    if (mounted) {
      FocusScope.of(context).unfocus();
      _showSnack('Cookie 已保存');
    }
  }

  Future<void> _importCookieFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'cookie'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final cookie = content.trim();

      setState(() => _cookieController.text = cookie);
      await SettingsService.setCookie(cookie);
      if (mounted) _showSnack('Cookie 已从文件导入并保存');
    } catch (e) {
      if (mounted) _showSnack('导入失败: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFFF2F6FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 解析模式 ──
          _sectionLabel('解析模式'),
          _card(child: Column(
            children: [
              _modeOption(
                title: '远程 API',
                subtitle: '使用第三方接口解析，无需 Cookie，稳定性依赖服务商',
                value: ParseMode.remote,
                icon: Icons.cloud_rounded,
              ),
              const Divider(height: 1, indent: 56),
              _modeOption(
                title: '本地解析',
                subtitle: '直接请求抖音接口，需要配置 Cookie 以提高成功率',
                value: ParseMode.local,
                icon: Icons.phone_android_rounded,
              ),
            ],
          )),

          const SizedBox(height: 20),

          // ── Cookie 配置（本地模式时高亮显示） ──
          _sectionLabel('Cookie 配置',
            hint: _parseMode == ParseMode.local ? '本地模式建议配置' : null),
          _card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cookie_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text('抖音 Cookie',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    ),
                    IconButton(
                      icon: Icon(_showCookie ? Icons.visibility_off : Icons.visibility,
                        size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _showCookie = !_showCookie),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '从浏览器开发者工具中复制抖音网页版的 Cookie，可提高本地解析成功率',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cookieController,
                  maxLines: _showCookie ? 4 : 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'sessionid=xxx; uid_tt=xxx; ...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    suffixIcon: _cookieController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _cookieController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importCookieFromFile,
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('从文件导入'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _cookieController.clear()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('清除'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveCookie,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),

          const SizedBox(height: 20),

          // ── 下载设置 ──
          _sectionLabel('下载设置'),
          _card(child: Column(
            children: [
              Padding(
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
                              hintText: '便捷下载',
                              prefixIcon: const Icon(Icons.photo_album_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _primary, width: 2),
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
                            backgroundColor: _primary,
                            minimumSize: const Size(64, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _GroupByAuthorSwitch(primary: _primary),
            ],
          )),

          const SizedBox(height: 20),

          // ── 悬浮窗 ──
          _sectionLabel('悬浮窗'),
          _card(child: Column(
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
                activeColor: _primary,
                onChanged: _toggleFloating,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('简洁模式', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  '点击悬浮窗弹出小面板，不打断当前应用',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                value: _floatingCompact,
                activeColor: _primary,
                onChanged: (v) async {
                  await SettingsService.setFloatingCompactMode(v);
                  setState(() => _floatingCompact = v);
                  // 如果悬浮窗已启用，重启以应用新模式
                  if (_floatingEnabled && _hasOverlayPermission) {
                    await FloatingWindowService.stop();
                    await Future.delayed(const Duration(milliseconds: 300));
                    await FloatingWindowService.start(compactMode: v);
                  }
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _CompactAutoCloseSwitch(primary: _primary),
              if (!_hasOverlayPermission) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.security_rounded, color: Colors.orange, size: 20),
                  title: const Text('前往授权悬浮窗权限',
                    style: TextStyle(fontSize: 14, color: Colors.orange)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
                  onTap: () async => await FloatingWindowService.requestOverlayPermission(),
                ),
              ],
            ],
          )),

          const SizedBox(height: 24),

          // ── 关于 ──
          Center(
            child: Column(
              children: [
                Text('便捷下载', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 2),
                Text('Author: HACKFUN', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeOption({
    required String title,
    required String subtitle,
    required ParseMode value,
    required IconData icon,
  }) {
    final selected = _parseMode == value;
    return InkWell(
      onTap: () async {
        await SettingsService.setParseMode(value);
        setState(() => _parseMode = value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selected ? _primary.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: selected ? _primary : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: selected ? _primary : Colors.black87,
                    )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Radio<ParseMode>(
              value: value,
              groupValue: _parseMode,
              activeColor: _primary,
              onChanged: (v) async {
                if (v != null) {
                  await SettingsService.setParseMode(v);
                  setState(() => _parseMode = v);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {String? hint}) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Row(
      children: [
        Text(text, style: const TextStyle(
          color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        if (hint != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(hint, style: const TextStyle(
              color: _primary, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    ),
  );

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

// 简洁模式下载后自动关闭开关
class _CompactAutoCloseSwitch extends StatefulWidget {
  final Color primary;
  const _CompactAutoCloseSwitch({required this.primary});

  @override
  State<_CompactAutoCloseSwitch> createState() => _CompactAutoCloseSwitchState();
}

class _CompactAutoCloseSwitchState extends State<_CompactAutoCloseSwitch> {
  bool _value = true;

  @override
  void initState() {
    super.initState();
    SettingsService.getCompactAutoClose().then((v) => setState(() => _value = v));
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: const Text('下载后自动关闭面板', style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '简洁模式下载完成后 3 秒自动关闭悬浮面板',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      value: _value,
      activeColor: widget.primary,
      onChanged: (v) async {
        await SettingsService.setCompactAutoClose(v);
        setState(() => _value = v);
      },
    );
  }
}

// 独立的按作者分组开关（有自己的状态）
class _GroupByAuthorSwitch extends StatefulWidget {
  final Color primary;
  const _GroupByAuthorSwitch({required this.primary});

  @override
  State<_GroupByAuthorSwitch> createState() => _GroupByAuthorSwitchState();
}

class _GroupByAuthorSwitchState extends State<_GroupByAuthorSwitch> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    SettingsService.getGroupByAuthor().then((v) => setState(() => _value = v));
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: const Text('按发布者分组', style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '开启后保存到 相册名/发布者名称 子文件夹，文件名也会带上发布者',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      value: _value,
      activeColor: widget.primary,
      onChanged: (v) async {
        await SettingsService.setGroupByAuthor(v);
        setState(() => _value = v);
      },
    );
  }
}
