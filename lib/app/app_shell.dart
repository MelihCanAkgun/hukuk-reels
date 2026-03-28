import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/utils/platform_utils.dart';
import '../features/reels/screens/reels_screen.dart';
import '../features/reels/widgets/android_install_banner.dart';
import '../features/reels/widgets/ios_install_banner.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/ocr/screens/ocr_screen.dart';
import '../features/statistics/screens/statistics_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _showInstallBanner = false;
  bool _isAndroid = false;
  final _db = DatabaseService.instance;

  final _screens = const [
    ReelsScreen(),
    NotesScreen(),
    OcrScreen(),
    StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkInstallBanner();
  }

  void _checkInstallBanner() {
    if (_db.installBannerDismissed) return;

    if (PlatformUtils.shouldShowIosBanner) {
      setState(() {
        _showInstallBanner = true;
        _isAndroid = false;
      });
    } else if (PlatformUtils.shouldShowAndroidBanner) {
      setState(() {
        _showInstallBanner = true;
        _isAndroid = true;
      });
    }
  }

  void _dismissBanner() {
    _db.dismissInstallBanner();
    setState(() => _showInstallBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Platform'a göre install banner
          if (_showInstallBanner)
            Positioned(
              left: 0,
              right: 0,
              // iOS: alttan, Android: üstten
              bottom: _isAndroid ? null : 0,
              top: _isAndroid ? 0 : null,
              child: _isAndroid
                  ? AndroidInstallBanner(onDismiss: _dismissBanner)
                  : IosInstallBanner(onDismiss: _dismissBanner),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle_filled),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              activeIcon: Icon(Icons.note_alt),
              label: 'Notlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'OCR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'İstatistik',
            ),
          ],
        ),
      ),
    );
  }
}
