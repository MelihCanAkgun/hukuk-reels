import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/tower_rules.dart';

TowerDrop drop(double cx, {double w = 96, double tolerance = 3}) =>
    resolveTowerDrop(
        moverCx: cx, moverW: w, topX0: -48, topX1: 48, tolerance: tolerance);

void main() {
  test('centered drop within tolerance snaps onto the floor below', () {
    final d = drop(2.5);
    expect(d.kind, TowerDropKind.perfect);
    expect(d.x0, -48);
    expect(d.x1, 48);
    expect(d.hasChunk, isFalse);
  });

  test('right overhang is cut off and falls to the right', () {
    final d = drop(20);
    expect(d.kind, TowerDropKind.cut);
    expect(d.x0, -28);
    expect(d.x1, 48);
    expect(d.width, 76);
    expect(d.rightSide, isTrue);
    expect(d.chunk0, 48);
    expect(d.chunk1, 68);
    expect(d.hasChunk, isTrue);
  });

  test('left overhang is cut off and falls to the left', () {
    final d = drop(-30, w: 60);
    expect(d.kind, TowerDropKind.cut);
    expect(d.x0, -48);
    expect(d.x1, 0);
    expect(d.rightSide, isFalse);
    expect(d.chunk0, -60);
    expect(d.chunk1, -48);
  });

  test('a sliver of overlap or none at all is a miss', () {
    expect(drop(95.6).kind, TowerDropKind.miss);
    expect(drop(-200).kind, TowerDropKind.miss);
    expect(drop(95).kind, TowerDropKind.cut);
  });

  test('tiny trims are not dropped as falling chunks', () {
    final d = drop(0.2, tolerance: 0.1);
    expect(d.kind, TowerDropKind.cut);
    expect(d.hasChunk, isFalse);
  });

  test('difficulty ramps up and then levels off', () {
    expect(towerSpeed(0), 80);
    expect(towerSpeed(10), greaterThan(towerSpeed(5)));
    expect(towerSpeed(1000), 235);
    expect(towerTolerance(0), 3.4);
    expect(towerTolerance(10), lessThan(towerTolerance(5)));
    expect(towerTolerance(1000), 1.7);
  });

  test('the floor keeps growing for as long as the perfect streak lasts', () {
    expect([for (var s = 0; s <= 9; s++) towerStreakGrows(s)],
        [false, false, false, false, false, true, true, true, true, true]);
    expect(towerStreakGrows(3, every: 3), isTrue);
  });

  test('streak growth never exceeds the base width', () {
    expect(towerGrownWidth(50, 96, 12), 62);
    expect(towerGrownWidth(90, 96, 12), 96);
  });
}
