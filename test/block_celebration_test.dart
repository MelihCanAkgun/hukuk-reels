import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/block_celebration.dart';

void main() {
  test('celebration tiers distinguish chains, multi-clears and perfect boards',
      () {
    BlockCelebrationData rank(int combo, int lines, {bool allClear = false}) =>
        BlockCelebrationData.forClear(
            combo: combo, lines: lines, points: 500, allClear: allClear);
    expect(rank(2, 1).title, 'COMBO!');
    expect(rank(4, 1).title, 'SUPER!');
    expect(rank(1, 3).title, 'SUPER!');
    expect(rank(6, 1).title, 'SSS');
    expect(rank(1, 4).title, 'SSS');
    expect(rank(1, 1, allClear: true).title, 'PERFECT!');
    expect(rank(6, 1, allClear: true).title, 'SSS');
  });
  for (final reduced in [false, true]) {
    testWidgets('celebration passes touches and expires (reduced=$reduced)',
        (tester) async {
      var taps = 0;
      final data = BlockCelebrationData.forClear(
          combo: 6, lines: 2, points: 240, allClear: false);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Center(
            child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(children: [
                  Positioned.fill(
                      child: GestureDetector(
                          onTap: () => taps++,
                          child: const ColoredBox(color: Colors.blue))),
                  Positioned.fill(child: BlockCelebration(data: data)),
                ]))),
      )));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tapAt(tester.getCenter(find.byType(BlockCelebration)));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(
          find.descendant(
              of: find.byType(BlockCelebration),
              matching: find.byType(CustomPaint)),
          findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
