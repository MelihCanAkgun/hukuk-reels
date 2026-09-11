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
      {'slot': 0, 'row': 0, 'col': 0}
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
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
