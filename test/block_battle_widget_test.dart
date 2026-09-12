import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';
import 'package:hukuk_reels/features/game/block_battle_session.dart';
import 'package:hukuk_reels/features/game/block_blast_screen.dart';
import 'package:hukuk_reels/features/game/block_battle_life_fx.dart';
import 'package:hukuk_reels/features/game/block_battle_widgets.dart';

BattleMatch match() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final m = BattleMatch('ABC234', 42, now - 3000);
  for (final id in [1, 2]) {
    m.join(id, 'Oyuncu $id', now - 3000);
    m.connect(id, now - 3000);
    m.ready(id, now - 3000);
  }
  m.advance(now);
  m.player(1).game.tray = [
    const BlockPiece(0, 0),
    const BlockPiece(0, 1),
    const BlockPiece(0, 2)
  ];
  return m;
}

Map<String, dynamic> frame(BattleMatch m, {List events = const []}) => {
      'me': 1,
      'state': jsonDecode(jsonEncode(m.toJson())),
      'connected': true,
      'pending': false,
      'events': events,
    };
void main() {
  setUpAll(() async {
    // These rendering tests have no native audio plugin. Keep channel setup
    // explicit so runAsync image capture cannot leak unrelated plugin errors.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.just_audio.methods'), (call) async {
      if (call.method == 'init') {
        final id = call.arguments['id'];
        messenger.setMockMethodCallHandler(
            MethodChannel('com.ryanheise.just_audio.methods.$id'),
            (_) async => {'duration': 0});
        messenger.setMockMethodCallHandler(
            MethodChannel('com.ryanheise.just_audio.data.$id'),
            (_) async => null);
        messenger.setMockMethodCallHandler(
            MethodChannel('com.ryanheise.just_audio.events.$id'),
            (_) async => null);
      }
      return {};
    });
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
  });
  testWidgets('Life FX observe snapshots without actions or state mutation',
      (tester) async {
    final calls = <String>[];
    final m = match();
    final session = BlockBattleSession(
        listen: false,
        transport: (a, d) async {
          calls.add(a);
          return {};
        })
      ..receive(frame(m));
    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();
    expect(find.byType(BattleHearts), findsNWidgets(2));
    m.player(1).lives = 4;
    session.receive(frame(m));
    final snapshot = jsonEncode(session.state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(const ValueKey('battle-life-loss')), findsOneWidget);
    expect(find.text('−1'), findsOneWidget);
    expect(session.canPlay, isTrue);
    expect(jsonEncode(session.state), snapshot);
    // Duplicate snapshots cannot replay the hit.
    session.receive(frame(m));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('battle-life-loss')), findsNothing);
    m.player(1).lives = 1;
    session.receive(frame(m));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    m.player(1).lives = 2;
    session.receive(frame(m));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    m.player(1).lives = 0;
    session.receive(frame(m));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('Reduced motion keeps pixel lives static and disposes cleanly',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: BattleHearts(lives: 1, critical: true)))));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(844, 390)
  ]) {
    testWidgets(
        'Battle keeps shared board and opponent preview usable at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final m = match();
      final session =
          BlockBattleSession(listen: false, transport: (a, d) async => {})
            ..receive(frame(m));
      final previewKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: previewKey,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: BlockBlastScreen(battle: session))));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('battle-opponent-board')), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('block-board'))).width,
          greaterThan(100));
      expect(tester.takeException(), isNull);
      final preview = Platform.environment['BATTLE_PREVIEW_PATH'];
      if (preview != null && size.width == 320) {
        await tester.runAsync(() async {
          final boundary = previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(preview).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }
  testWidgets(
      'Battle drag sends only placement; authoritative ack preserves solo save',
      (tester) async {
    final solo = BlockBlastEngine()..score = 1234;
    unawaited(ProgressService.instance.saveBlockGame(solo.toJson()));
    await tester.pump();
    final saved = jsonEncode(ProgressService.instance.loadBlockGame());
    final m = match();
    final requests = <Map<String, dynamic>>[];
    final ack = Completer<Map<String, dynamic>>();
    final session = BlockBattleSession(
        listen: false,
        transport: (action, data) async {
          if (action == 'place') {
            requests.add(data);
            return ack.future;
          }
          return {};
        })
      ..receive(frame(m));
    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();
    final board = tester.getRect(find.byKey(const ValueKey('block-board'))),
        cell = board.width / 8;
    final start = tester.getCenter(find.byKey(const ValueKey('block-tray-0')));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(requests, isEmpty);
    final lifted = start - Offset(cell / 2, cell + 64);
    await gesture.moveTo(start + (board.topLeft - lifted) / 2.2);
    await tester.pump();
    expect(requests, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(requests, [
      {'slot': 0, 'row': 0, 'col': 0, 'round': 1}
    ]);
    expect(session.pending, true);
    m.place(1, 1, 0, 0, 0, DateTime.now().millisecondsSinceEpoch);
    ack.complete({...frame(m), 'ok': true});
    await tester.pumpAndSettle();
    expect(session.pending, false);
    expect(session.mine!['game']['score'], 1);
    expect(jsonEncode(ProgressService.instance.loadBlockGame()), saved);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('Battle shows defeat, final statistics, and no revive flow',
      (tester) async {
    final m = match();
    m.resign(1, DateTime.now().millisecondsSinceEpoch);
    final session =
        BlockBattleSession(listen: false, transport: (a, d) async => {})
          ..receive(frame(m));
    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();
    expect(find.text('DEFEAT'), findsOneWidget);
    expect(find.text('Kazanan: Oyuncu 2'), findsOneWidget);
    expect(find.textContaining('Rakibe verilen skor hasarı'), findsNWidgets(2));
    expect(find.text('Lobiye dön'), findsOneWidget);
    expect(find.text('Tekrar Oyna'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('Battle HUD displays attack progress bar for both players',
      (tester) async {
    final m = match();
    m.player(1).game.score = 250;
    m.player(2).game.score = 375;
    final session =
        BlockBattleSession(listen: false, transport: (a, d) async => {})
          ..receive(frame(m));
    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battle-mine-attack')), findsOneWidget);
    expect(find.text('ATTACK 250 / 500'), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-other-attack')), findsOneWidget);
    expect(find.text('375 / 500'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('BattleResult renders rematch states and triggers rematch action',
      (tester) async {
    final calls = <String>[];
    final m = match();
    m.resign(2, DateTime.now().millisecondsSinceEpoch);
    final session = BlockBattleSession(
        listen: false,
        transport: (action, data) async {
          calls.add(action);
          return {'ok': true};
        })
      ..receive(frame(m));

    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();

    // Initial state: "Tekrar Oyna"
    final rematchBtn = find.byKey(const ValueKey('battle-rematch-button'));
    expect(rematchBtn, findsOneWidget);
    expect(find.text('Tekrar Oyna'), findsOneWidget);

    // Tap rematch
    await tester.tap(rematchBtn);
    await tester.pumpAndSettle();
    expect(calls, ['rematch']);

    // Opponent requested rematch state
    m.player(2).rematch = true;
    m.player(1).rematch = false;
    session.receive(frame(m));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battle-opponent-rematch-notice')), findsOneWidget);
    expect(find.text('Rakip tekrar oynamak istiyor!'), findsOneWidget);
    expect(find.text('Kabul Et ve Tekrar Oyna'), findsOneWidget);

    // Waiting state (self requested rematch)
    m.player(1).rematch = true;
    m.player(2).rematch = false;
    session.receive(frame(m));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('battle-rematch-waiting-button')), findsOneWidget);
    expect(find.text('Rakip bekleniyor…'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('Battle HUD displays combo status and omits old 500pt notice',
      (tester) async {
    final m = match();
    // Initially combo = 0
    final session =
        BlockBattleSession(listen: false, transport: (a, d) async => {})
          ..receive(frame(m));
    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();

    // Old 500pt notice is gone
    expect(find.textContaining('Her 500 puan = rakibe'), findsNothing);
    // When combo is 0, no combo banner
    expect(find.textContaining('COMBO x'), findsNothing);

    // Now player has combo 4, misses 1 (reset in 2), comboBonus 120
    m.player(1).game.combo = 4;
    m.player(1).game.misses = 1;
    m.player(1).game.comboBonus = 120;
    session.receive(frame(m));
    await tester.pumpAndSettle();

    expect(find.text('COMBO x4  ·  +120 COMBO  ·  RESET: 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('BattleResult renders error message if session error occurs',
      (tester) async {
    final m = match();
    m.resign(2, DateTime.now().millisecondsSinceEpoch);
    final session = BlockBattleSession(
        listen: false, transport: (a, d) async => {'ok': true})
      ..receive(frame(m));
    await tester
        .pumpWidget(MaterialApp(home: BlockBlastScreen(battle: session)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battle-result-error')), findsNothing);

    // Session receives error frame
    session.receive({...frame(m), 'error': 'Bağlantı yeniden kuruluyor.'});
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('battle-result-error')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(BattleResult),
            matching: find.text('Bağlantı yeniden kuruluyor.')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
