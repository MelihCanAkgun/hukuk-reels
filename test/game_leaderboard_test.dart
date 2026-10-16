import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/game/flappy_cat_screen.dart';
import 'package:hukuk_reels/features/game/game_leaderboard.dart';
import 'package:hukuk_reels/features/game/subway_cat_screen.dart';
import 'package:hukuk_reels/features/game/tower_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
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

  final board = <String, dynamic>{
    'me': 1,
    'players': [
      {'id': 1, 'name': 'A', 'best': 900, 'active': 1},
      {'id': 2, 'name': 'B', 'best': 300, 'active': 1},
    ],
    'scores': [
      {'id': 2, 'game': 'flappy', 'best': 14},
      {'id': 1, 'game': 'flappy', 'best': 9},
      {'id': 1, 'game': 'tower', 'best': 22},
    ],
  };

  test('each game ranks the players by its own best', () {
    List<List<Object?>> rank(LeaderboardGame g) => [
          for (final r in leaderboardRows(board, g)) [r['id'], r['best']]
        ];
    expect(rank(LeaderboardGame.block), [
      [1, 900],
      [2, 300]
    ]);
    expect(rank(LeaderboardGame.flappy), [
      [2, 14],
      [1, 9]
    ]);
    expect(rank(LeaderboardGame.tower), [
      [1, 22],
      [2, 0]
    ]);
    // Henüz kimse oynamadıysa ikisi 0'da, sıra oyuncu numarasına göre.
    expect(rank(LeaderboardGame.subway), [
      [1, 0],
      [2, 0]
    ]);
    expect(leaderboardRows(const {}, LeaderboardGame.flappy), isEmpty);
  });

  test('every game except Block Blast has its own server code', () {
    expect(LeaderboardGame.values.map((g) => g.name),
        ['block', 'flappy', 'subway', 'tower']);
    expect(LeaderboardGame.tower.unit, ' kat');
  });

  for (final (game, screen) in [
    (LeaderboardGame.flappy, const FlappyCatScreen()),
    (LeaderboardGame.subway, const SubwayCatScreen()),
    (LeaderboardGame.tower, const TowerScreen()),
  ]) {
    testWidgets('${game.title} opens its own leaderboard', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('İkimizin sıralaması'));
      await tester.pumpAndSettle();
      final page = tester.widget<GameLeaderboard>(find.byType(GameLeaderboard));
      expect(page.game, game);
      final chip = tester.widget<ChoiceChip>(
          find.byKey(ValueKey('leaderboard-${game.name}')));
      expect(chip.selected, isTrue);

      // Sayfada diğer oyunların sıralamasına geçilebilir.
      await tester.tap(find.byKey(const ValueKey('leaderboard-block')));
      await tester.pump();
      expect(
          tester
              .widget<ChoiceChip>(
                  find.byKey(const ValueKey('leaderboard-block')))
              .selected,
          isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
