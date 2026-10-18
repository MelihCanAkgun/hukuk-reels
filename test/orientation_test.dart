import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/core/data/questions_data.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/beat/beat_mode_screen.dart';
import 'package:hukuk_reels/features/countdown/countdown_screen.dart';
import 'package:hukuk_reels/features/game/block_battle_lobby.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';
import 'package:hukuk_reels/features/game/block_blast_screen.dart';
import 'package:hukuk_reels/features/game/flappy_cat_screen.dart';
import 'package:hukuk_reels/features/game/game_leaderboard.dart';
import 'package:hukuk_reels/features/game/game_pause_overlay.dart';
import 'package:hukuk_reels/features/game/subway_cat_screen.dart';
import 'package:hukuk_reels/features/game/tower_screen.dart';
import 'package:hukuk_reels/features/games/games_screen.dart';
import 'package:hukuk_reels/features/home/home_tab.dart';
import 'package:hukuk_reels/features/intro/confidence_gate_screen.dart';
import 'package:hukuk_reels/features/profile/avatar_editor_screen.dart';
import 'package:hukuk_reels/features/profile/profile_settings_screen.dart';
import 'package:hukuk_reels/features/reels/screens/reels_maintenance_screen.dart';
import 'package:hukuk_reels/features/reels/screens/reels_screen.dart';
import 'package:hukuk_reels/features/shell/home_shell.dart';
import 'package:hukuk_reels/features/study/study_screen.dart';
import 'package:hukuk_reels/features/summaries/summaries_screen.dart';
import 'package:hukuk_reels/features/surprise/flower_surprise_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

/// Dikey boyutlar (genişlik, yükseklik); yatay olanı ters çevrilerek elde edilir.
const _devices = <String, Size>{
  'iPhone SE 1': Size(320, 568),
  'iPhone 15': Size(393, 852),
  'iPad mini': Size(744, 1133),
  'iPad Air': Size(820, 1180),
  'iPad Pro 12.9': Size(1024, 1366),
  'Tarayıcı penceresi': Size(600, 800),
};

final _screens = <String, Widget Function()>{
  'Sekme kabuğu': () => const HomeShell(),
  'Ana sayfa': () => const HomeTab(),
  'Çalış': () => const StudyScreen(),
  'Oyunlar': () => const GamesScreen(),
  'Soru bankası': () => const ReelsScreen(),
  'Bakım': () => const ReelsMaintenanceScreen(),
  'Beat modu': () => BeatModeScreen(questions: kQuestions.take(6).toList()),
  'Özetler': () => const SummariesScreen(),
  'Profil': () => const ProfileSettingsScreen(),
  'Fotoğraf düzenleyici': () =>
      AvatarEditorScreen(preview: _png, srcWidth: 4032, srcHeight: 3024),
  'Geri sayım': () => const CountdownScreen(),
  'Lider tablosu': () => const GameLeaderboard(),
  'Battle lobisi': () => const BlockBattleLobby(),
  'Güven kapısı': () => const ConfidenceGateScreen(),
  'Sürpriz': () => const FlowerSurpriseScreen(),
  'Block Blast': () => const BlockBlastScreen(),
  'Flappy': () => const FlappyCatScreen(),
  'Subway': () => const SubwayCatScreen(),
  'Adliye Kulesi': () => const TowerScreen(),
};

Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('com.ryanheise')) {
        return const StandardMethodCodec()
            .encodeSuccessEnvelope(<String, dynamic>{});
      }
      return handler?.call(message);
    };
  });

  for (final screen in _screens.entries) {
    for (final device in _devices.entries) {
      final p = device.value, l = device.value.flipped;
      for (final order in [
        [p, l, p],
        [l, p, l],
      ]) {
        final name =
            order.first == p ? 'dikey→yatay→dikey' : 'yatay→dikey→yatay';
        testWidgets('${screen.key} · ${device.key} · $name', (tester) async {
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          tester.view.physicalSize = order.first * 2;
          await tester.pumpWidget(
              MaterialApp(theme: AppTheme.dark, home: screen.value()));
          await _frames(tester, 400);
          expect(tester.takeException(), isNull, reason: '${order.first}');
          for (final size in order.skip(1)) {
            tester.view.physicalSize = size * 2;
            await _frames(tester, 400);
            expect(tester.takeException(), isNull, reason: '$size');
          }
          await tester.pumpWidget(const SizedBox());
          await _frames(tester, 50);
        });
      }
    }
  }

  // ─────────────── Oyun sürerken döndürme ───────────────
  // Döndürme oyunu duraklatır; "Devam et" ile aynı oyun yeni boyutta sürer.
  Future<void> rotateMidGame(WidgetTester tester, Widget game, Size size,
      void Function(dynamic st) step,
      {required void Function(dynamic st) start}) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.physicalSize = size * 2;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: game));
    await _frames(tester, 300);
    final dynamic st = tester.state(find.byWidget(game));
    start(st);
    Future<void> play(int ms) async {
      for (var t = 0; t < ms; t += 16) {
        step(st);
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    await play(1500);
    for (final next in [size.flipped, size]) {
      tester.view.physicalSize = next * 2;
      await tester.pump();
      await _frames(tester, 200);
      expect(tester.takeException(), isNull, reason: '$next');
      expect(find.byType(GamePauseOverlay), findsOneWidget,
          reason: 'döndürme oyunu duraklatmalı ($next)');
      await tester.tap(find.text('Devam et'));
      await tester.pump();
      expect(find.byType(GamePauseOverlay), findsNothing);
      await play(1500);
      expect(tester.takeException(), isNull, reason: '$next');
    }
  }

  for (final device in ['iPhone 15', 'iPad Air']) {
    for (final land in [false, true]) {
      final size = land ? _devices[device]!.flipped : _devices[device]!;
      final tag = '$device · ${land ? 'yatayda başla' : 'dikeyde başla'}';

      testWidgets('Flappy oyun ortasında döndürme · $tag', (tester) async {
        await rotateMidGame(
            tester, const FlappyCatScreen(), size, (st) => st.autopilot(),
            start: (st) => st.autopilot());
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Subway oyun ortasında döndürme · $tag', (tester) async {
        await rotateMidGame(tester, const SubwayCatScreen(), size, (_) {},
            start: (st) => st.debugStart(god: true));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Kule oyun ortasında döndürme · $tag', (tester) async {
        late int before;
        await rotateMidGame(
            tester, const TowerScreen(), size, (st) => st.autopilot(),
            start: (st) {
          st.autopilot();
          before = 0;
        });
        final dynamic st = tester.state(find.byType(TowerScreen));
        expect(st.phaseName, 'playing');
        expect(st.score as int, greaterThan(before));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Block Blast yerleştirme ve döndürme · $tag', (tester) async {
        final game = BlockBlastEngine()
          ..tray = [
            const BlockPiece(0, 0),
            const BlockPiece(0, 1),
            const BlockPiece(0, 2)
          ];
        for (var c = 1; c < 8; c++) {
          game.grid[0][c] = 0;
        }
        ProgressService.instance.saveBlockGame(game.toJson());
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = size * 2;
        await tester.pumpWidget(
            MaterialApp(theme: AppTheme.dark, home: const BlockBlastScreen()));
        await _frames(tester, 600);

        // Parçayı, sürüklenen görüntüsü sol üst hücreye oturana dek götür.
        final board = tester.getRect(find.byKey(const ValueKey('block-board')));
        final cell = board.width / 8;
        final g = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('block-tray-0'))));
        await g.moveBy(const Offset(0, -20));
        await tester.pump();
        final fb = find.byKey(const ValueKey('block-drag-feedback'));
        for (var i = 0; i < 30; i++) {
          final d = board.topLeft +
              Offset(cell * 0.3, cell * 0.3) -
              tester.getRect(fb).topLeft;
          if (d.distance < cell * 0.15) break;
          await g.moveBy(d * 0.4);
          await tester.pump();
        }
        await g.up();
        await tester.pump();
        expect(
            BlockBlastEngine.restore(ProgressService.instance.loadBlockGame())!
                .score,
            311);
        // Döndürünce aynı oyun sürer; sıradaki parça hâlâ sürüklenebilir.
        for (final next in [size.flipped, size]) {
          tester.view.physicalSize = next * 2;
          await _frames(tester, 600);
          expect(tester.takeException(), isNull, reason: '$next');
          expect(find.text('311'), findsOneWidget);
          final tray = find.byKey(const ValueKey('block-tray-1'));
          final r = tester.getRect(tray);
          expect((Offset.zero & next).contains(r.center), isTrue,
              reason: '$next');
          final h = await tester.startGesture(r.center);
          await tester.pump(const Duration(milliseconds: 50));
          expect(fb, findsOneWidget);
          await h.cancel();
          await tester.pump();
        }
        await tester.pumpWidget(const SizedBox());
        ProgressService.instance.clearBlockGame();
        await tester.pump();
      });
    }
  }
}
