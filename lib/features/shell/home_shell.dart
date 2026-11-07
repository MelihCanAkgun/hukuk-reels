import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/activity_area.dart';
import '../../core/services/battle_bridge.dart';
import '../../core/services/progress_service.dart';
import '../../core/widgets/pixel_logo.dart';
import '../films/films_screen.dart';
import '../game/block_battle_lobby.dart';
import '../games/games_screen.dart';
import '../home/home_store.dart';
import '../home/home_tab.dart';
import '../profile/profile_avatar.dart';
import '../profile/profile_settings_screen.dart';
import '../study/study_screen.dart';
import '../surprise/flower_surprise_flow.dart';

/// Uygulamanın kabuğu: altta (geniş yatay ekranda solda) beş sekme.
/// Sekmeler bir kez kurulduktan sonra yaşamaya devam eder (kaydırma konumu
/// korunur); etkin sekmeye yeniden dokunmak başa kaydırır. Oyunlar ve özetler
/// tam ekran açılır, sekme çubuğu gizlenir.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class _Tab {
  const _Tab(this.label, this.logo, this.area);
  final String label;

  /// Piksel simge (arcade teması); profil sekmesinde avatar gösterilir.
  final List<String>? logo;
  final String area;
}

const _tabs = [
  _Tab('Ana sayfa', kLogoHome, 'home'),
  _Tab('Oyunlar', kLogoGames, 'games'),
  _Tab('Çalış', kLogoLawBook, 'study'),
  _Tab('Filmler', kLogoFilm, 'films'),
  _Tab('Profil', null, 'profile'),
];

/// Seçili olmayan sekmelerin soluk piksel simgesi: renkler zemine doğru
/// karıştırılır (Opacity katmanı açmadan).
final Map<String, Color> _dimPalette = {
  for (final e in kLogoPalette.entries)
    e.key: Color.lerp(e.value, AppTheme.bgElevated, .5)!,
};

/// Sekme numaraları (ana sayfadaki kısayollar için).
abstract final class ShellTab {
  static const home = 0, games = 1, study = 2, films = 3, profile = 4;
}

class HomeShellState extends State<HomeShell> {
  final _progress = ProgressService.instance;
  late int _index = widget.initialTab;

  /// Bir kez açılmış sekmeler (ilk açılışta yalnız ana sayfa kurulur).
  late final Set<int> _built = {_index};
  final _scroll = [for (final _ in _tabs) ScrollController()];

  @override
  void initState() {
    super.initState();
    // Uçuşlar ve mantar pano: uygulama açıkken düzenli tazelenir.
    HomeStore.instance
      ..start()
      ..refresh(force: true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Sayfa yenilenirse kayıtlı Battle odasına (bağlanma süresi içinde)
      // doğrudan dönülür.
      final saved = await battleCall('inspect');
      if (!mounted || BlockBattleLobby.inviteOpened) return;
      if (saved['room'] != null) {
        Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BlockBattleLobby()));
        return;
      }
      // Güncellemeyle gelen çiçek sürprizi: ilk açılışta bir kez.
      if (!_progress.flowerSurpriseSeen) {
        await showFlowerSurpriseGate(context);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    for (final c in _scroll) {
      c.dispose();
    }
    HomeStore.instance.stop();
    super.dispose();
  }

  /// Sekmeye geçer; etkin sekmeye yeniden dokunulursa başa kaydırır.
  void select(int i) {
    if (i == _index) {
      final c = _scroll[i];
      if (c.hasClients && c.offset > 0) {
        c.animateTo(0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic);
      }
      return;
    }
    setState(() {
      _index = i;
      _built.add(i);
    });
  }

  Widget _page(int i) => switch (i) {
        ShellTab.home => HomeTab(onOpenTab: select),
        ShellTab.games => GamesScreen(),
        ShellTab.study => StudyScreen(),
        ShellTab.films => const FilmsScreen(),
        _ => ProfileSettingsScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rail = size.width >= 900 && size.width > size.height;
    // Sekmeler her kurulumda yeni örnek alır: sekme değişince rekorlar ve
    // profil bilgileri tazelenir (durum ve kaydırma korunur).
    final pages = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < _tabs.length; i++)
          TickerMode(
            enabled: i == _index,
            child: PrimaryScrollController(
              controller: _scroll[i],
              child: _built.contains(i) ? _page(i) : const SizedBox.shrink(),
            ),
          ),
      ],
    );
    return ActivityAreaScope(
      area: _tabs[_index].area,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: rail ? Row(children: [_rail(), Expanded(child: pages)]) : pages,
        bottomNavigationBar: rail ? null : _bar(),
      ),
    );
  }

  Widget _icon(int i, bool selected) {
    final logo = _tabs[i].logo;
    if (logo == null) return _profileIcon(selected);
    return PixelLogo(logo,
        size: 24, palette: selected ? kLogoPalette : _dimPalette);
  }

  Widget _profileIcon(bool selected) => Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? AppTheme.textPrimary : Colors.transparent,
              width: 1.5),
        ),
        child: const ProfileAvatar(size: 24, ring: false),
      );

  Widget _bar() => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.6)),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: _index,
          onDestinationSelected: select,
          backgroundColor: AppTheme.bgElevated,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppTheme.accent.withValues(alpha: .16),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _tabs.length; i++)
              NavigationDestination(
                key: ValueKey('tab-${_tabs[i].area}'),
                label: _tabs[i].label,
                tooltip: '',
                icon: _icon(i, false),
                selectedIcon: _icon(i, true),
              ),
          ],
        ),
      );

  Widget _rail() => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bgElevated,
          border: Border(right: BorderSide(color: AppTheme.border, width: 0.6)),
        ),
        child: SafeArea(
          right: false,
          child: NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: select,
            backgroundColor: Colors.transparent,
            indicatorColor: AppTheme.accent.withValues(alpha: .16),
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.85,
            destinations: [
              for (var i = 0; i < _tabs.length; i++)
                NavigationRailDestination(
                  label: Text(_tabs[i].label),
                  icon: _icon(i, false),
                  selectedIcon: _icon(i, true),
                ),
            ],
          ),
        ),
      );
}
