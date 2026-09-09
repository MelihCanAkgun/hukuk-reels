import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/main.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/game/block_blast_screen.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';
import 'package:hukuk_reels/features/game/flappy_cat_screen.dart';
import 'package:hukuk_reels/features/game/subway_cat_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  testWidgets('games are the entry point and questions remain reachable',
      (tester) async {
    await tester.pumpWidget(const HukukReelsApp());
    expect(find.text('Block Blast'), findsOneWidget);
    expect(find.text('Soru bankası'), findsOneWidget);
    await tester.tap(find.text('Block Blast'));
    await tester.pumpAndSettle();
    expect(find.byType(BlockBlastScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'drag clears a line, commits save before animation and restores it',
      (tester) async {
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
    await tester.pumpWidget(const MaterialApp(home: BlockBlastScreen()));
    await tester.pumpAndSettle();
    final board = tester.getRect(find.byKey(const ValueKey('block-board')));
    final cell = board.width / 8;
    final start = tester.getCenter(find.byKey(const ValueKey('block-tray-0')));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    final liftedOrigin = start - Offset(cell / 2, cell + 64);
    await gesture.moveTo(start + (board.topLeft - liftedOrigin) / 2.2);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    final saved =
        BlockBlastEngine.restore(ProgressService.instance.loadBlockGame())!;
    expect(saved.score, 311);
    expect(saved.combo, 1);
    expect(saved.grid.every((r) => r.every((c) => c == null)), isTrue);
    // Leave while burst is running: rules must already be committed.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: BlockBlastScreen()));
    await tester.pumpAndSettle();
    expect(find.text('311'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    ProgressService.instance.clearBlockGame();
    await tester.pump();
  });

  testWidgets(
      'touch lifts immediately, travels farther and ignores a second finger',
      (tester) async {
    final game = BlockBlastEngine()
      ..tray = [
        const BlockPiece(9, 0),
        const BlockPiece(0, 1),
        const BlockPiece(0, 2)
      ];
    ProgressService.instance.saveBlockGame(game.toJson());
    await tester.pumpWidget(const MaterialApp(home: BlockBlastScreen()));
    await tester.pumpAndSettle();
    final start = tester.getCenter(find.byKey(const ValueKey('block-tray-0')));
    final first = await tester.startGesture(start, pointer: 1);
    await tester.pump();
    final feedback = find.byKey(const ValueKey('block-drag-feedback'));
    expect(feedback, findsOneWidget); // no pan threshold or hold required
    await tester.pump(const Duration(milliseconds: 120));
    final initial = tester.getRect(feedback);
    final board = tester.getRect(find.byKey(const ValueKey('block-board')));
    expect(initial.width, closeTo(board.width / 4, .1)); // full 2-cell size
    expect(initial.bottom, closeTo(start.dy - 64, .1));
    await first.moveBy(const Offset(20, -30));
    await tester.pump();
    final moved = tester.getRect(feedback);
    expect(moved.left - initial.left, closeTo(44, .1));
    expect(moved.top - initial.top, closeTo(-66, .1));
    final second = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('block-tray-1'))),
        pointer: 2);
    await second.moveBy(const Offset(80, -80));
    await second.up();
    await tester.pump();
    expect(tester.getRect(feedback), moved);
    await first.cancel();
    await tester.pump();
    expect(feedback, findsNothing);
    expect(ProgressService.instance.loadBlockGame()!['score'], 0);
    final tap = await tester.startGesture(start);
    await tester.pump();
    expect(feedback, findsOneWidget);
    await tap.up();
    await tester.pump();
    expect(feedback, findsNothing);
    expect(ProgressService.instance.loadBlockGame()!['score'], 0);
    await tester.pumpWidget(const SizedBox());
    ProgressService.instance.clearBlockGame();
    await tester.pump();
  });

  testWidgets('Block Blast supports large text and reduced motion',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 667);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!),
        home: const BlockBlastScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(393, 852),
    const Size(844, 390),
    const Size(1024, 768),
    const Size(507, 768)
  ]) {
    testWidgets('Block Blast fits $size and can reset', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: BlockBlastScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Yeni oyun'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final game in [const FlappyCatScreen(), const SubwayCatScreen()]) {
    testWidgets(
        '${game.runtimeType} pauses on background and waits for resume tap',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: game));
      await tester.pump(const Duration(milliseconds: 50));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Devam et'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Devam et'), findsOneWidget);
      await tester.tap(find.text('Devam et'));
      await tester.pump();
      expect(find.text('Devam et'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
