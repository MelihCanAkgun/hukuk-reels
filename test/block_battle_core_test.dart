import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';

BattleMatch playing() {
  final m = BattleMatch('ABC234', 12345, 0);
  for (final id in [1, 2]) {
    m.join(id, 'Player $id', 0);
    m.connect(id, 0);
    m.ready(id, 0);
  }
  m.advance(3000);
  return m;
}

void single(BattlePlayer p, int score) {
  p.game.tray = [const BlockPiece(0, 0), const BlockPiece(0, 1), null];
  p.game.score = score;
}

void blocked(BattlePlayer p) {
  p.game.grid = List.generate(
      8, (r) => List<int?>.generate(8, (c) => (r + c).isEven ? 0 : null));
  p.game.tray = [const BlockPiece(0, 0), const BlockPiece(10, 1), null];
}

void main() {
  test('both players receive identical sets independent of board and pace', () {
    final m = playing();
    final a = m.player(1), b = m.player(2);
    a.game.score = 9876;
    a.game.grid[0][0] = 4;
    for (var i = 0; i < 200; i++) {
      expect(a.game.toJson()['tray'], b.game.toJson()['tray']);
      a.game.refill();
      b.game.refill();
    }
    expect(b.game.grid[0][0], null);
    expect(b.game.score, 0);
  });
  for (final value in [999, 1999]) {
    test('$value crossing applies exactly one NEW damage threshold', () {
      final m = playing();
      final p = m.player(1);
      single(p, value);
      p.thresholds = value ~/ 1000;
      expect(m.place(1, 1, 0, 0, 0, 3001)['ok'], true);
      expect(p.game.score, value + 1);
      expect(m.player(2).lives, 4);
      expect(p.damage, 1);
      final before = jsonEncode(m.toJson());
      expect(m.place(1, 1, 0, 0, 0, 3002)['duplicate'], true);
      expect(jsonEncode(m.toJson()), before);
    });
  }
  test('multiple thresholds crossed in one legal clear each damage once', () {
    final m = playing();
    final p = m.player(1);
    single(p, 999);
    p.game.grid[0] = [null, 0, 0, 0, 0, 0, 0, 0];
    p.game.combo = 199;
    m.place(1, 1, 0, 0, 0, 3001);
    expect(p.game.score, 3300);
    expect(m.player(2).lives, 2);
    expect(p.damage, 3);
    expect(p.thresholds, 3);
  });
  test('board-out loses one life, preserves score/damage and draws next set',
      () {
    final m = playing();
    final p = m.player(1);
    blocked(p);
    p.game.score = 2650;
    p.thresholds = 2;
    p.damage = 2;
    final set = p.nextSet;
    m.place(1, 1, 0, 0, 1, 3001);
    expect(p.lives, 4);
    expect(p.boardOuts, 1);
    expect(p.game.score, 2651);
    expect(p.damage, 2);
    expect(p.thresholds, 2);
    expect(p.game.grid.expand((r) => r).every((v) => v == null), true);
    expect(p.nextSet, set + 1);
    expect(p.game.hasMove, true);
    final next = p.game.tray.indexWhere((p) => p != null);
    final (r, c) = p.game.placements(p.game.tray[next]!).first;
    expect(m.place(1, 2, next, r, c, 3002)['ok'], true);
    expect(m.player(2).game.score, 0);
  });
  test('last life board-out ends match and later moves are rejected', () {
    final m = playing();
    final p = m.player(1);
    blocked(p);
    p.lives = 1;
    m.place(1, 1, 0, 0, 1, 3001);
    expect(m.winner, 2);
    expect(m.reason, 'board_out');
    expect(p.lives, 0);
    expect(p.boardOuts, 1);
    expect(m.place(2, 1, 0, 0, 0, 3002)['error'], isNotNull);
  });
  test('score damage ends match before a subsequent board-out', () {
    final m = playing();
    final p = m.player(1);
    blocked(p);
    p.game.score = 999;
    m.player(2).lives = 1;
    m.place(1, 1, 0, 0, 1, 3001);
    expect(m.winner, 1);
    expect(m.reason, 'score');
    expect(p.boardOuts, 0);
    expect(p.lives, 5);
  });
  test('invalid, fabricated or out-of-order move cannot mutate rules', () {
    final m = playing();
    final before = jsonEncode(m.toJson());
    for (final args in [
      [2, 0, 0, 0],
      [1, 3, 0, 0],
      [1, 0, -1, 0],
      [1, 0, 100, 0]
    ]) {
      expect(m.place(1, args[0], args[1], args[2], args[3], 3001)['error'],
          isNotNull);
      expect(jsonEncode(m.toJson()), before);
    }
  });
  test('reconnect restores exact state and cannot create another player', () {
    var m = playing();
    m.disconnect(1, 4000);
    expect(m.place(2, 1, 0, 0, 0, 4001)['error'], isNotNull);
    m = BattleMatch.restore(jsonDecode(jsonEncode(m.toJson())));
    m.join(1, 'Different', 5000);
    m.connect(1, 5000);
    expect(m.players.length, 2);
    expect(m.player(1).name, 'Player 1');
    expect(m.player(1).disconnectAt, null);
    expect(m.status, 'playing');
    m.disconnect(1, 6000);
    m.advance(20999);
    expect(m.finished, false);
    m.advance(21000);
    expect(m.winner, 2);
    expect(m.reason, 'disconnect');
    m.connect(1, 22000);
    expect(m.finished, true);
  });
  test('countdown is three seconds and disconnect cancels/restarts it', () {
    final m = BattleMatch('ABC234', 9, 0);
    for (final id in [1, 2]) {
      m.join(id, '$id', 0);
      m.connect(id, 0);
      m.ready(id, 0);
    }
    expect(m.status, 'countdown');
    m.advance(2999);
    expect(m.status, 'countdown');
    m.disconnect(2, 2999);
    expect(m.status, 'waiting');
    m.connect(2, 4000);
    expect(m.startAt, 7000);
    m.advance(7000);
    expect(m.status, 'playing');
  });
  test('active matches have no artificial time limit', () {
    final m = playing();
    m.advance(3600001);
    expect(m.status, 'playing');
  });
  test('persist/restore preserves deterministic future tray and move ack', () {
    final m = playing();
    final p = m.player(1);
    final restored = BattleMatch.restore(jsonDecode(jsonEncode(m.toJson())));
    for (var i = 0; i < 30; i++) {
      p.game.refill();
      restored.player(1).game.refill();
      expect(p.game.toJson(), restored.player(1).game.toJson());
    }
  });
}
