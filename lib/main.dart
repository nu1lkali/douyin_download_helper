import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  runApp(const DouyinDownloaderApp());
}

class DouyinDownloaderApp extends StatelessWidget {
  const DouyinDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '便捷下载',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1677FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1677FF), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const PermissionGateway(),
    );
  }
}

class PermissionGateway extends StatefulWidget {
  const PermissionGateway({super.key});

  @override
  State<PermissionGateway> createState() => _PermissionGatewayState();
}

class _PermissionGatewayState extends State<PermissionGateway> {
  bool _checking = true;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final granted = await PermissionService.hasStoragePermission();
    setState(() { _checking = false; _granted = granted; });
    if (granted) _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _requestPermission() async {
    final granted = await PermissionService.requestStoragePermission();
    if (granted) {
      _goHome();
    } else {
      setState(() => _granted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1677FF))),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1677FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.folder_open, size: 50, color: Color(0xFF1677FF)),
              ),
              const SizedBox(height: 32),
              const Text('需要存储权限', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                '下载视频和图片需要访问您的存储空间，请授予相关权限。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('去授权', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goHome,
                child: Text('暂时跳过', style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
