import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';
import 'package:hukuk_reels/features/game/block_battle_session.dart';
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
  test('shared sets survive lag, different boards, restore and cache pruning',
      () {
    var m = playing();
    final expected = <Object?>[];
    for (var i = 0; i < 15; i++) {
      m.player(1).game.grid[0][i % 7] = i % 8;
      m.player(1).game.refill();
      expected.add(m.player(1).game.toJson()['tray']);
    }
    m = BattleMatch.restore(jsonDecode(jsonEncode(m.toJson())));
    m.player(2).game.grid = List.generate(
        8, (r) => List.generate(8, (c) => (r + c).isEven ? 0 : null));
    for (final tray in expected) {
      m.player(2).game.refill();
      expect(m.player(2).game.toJson()['tray'], tray);
    }
    expect(m.toJson()['sets'], isEmpty);
  });
  test('legacy persisted matches keep their original future sequence', () {
    final data = playing().toJson()..['version'] = 1;
    data.remove('sets');
    final m = BattleMatch.restore(data);
    final index = m.player(1).nextSet;
    m.player(1).game.refill();
    expect(m.player(1).game.tray.map((p) => p!.shape),
        battleTray(m.seed, index).map((p) => p!.shape));
    expect(m.toJson()['version'], 1);
  });
  test('fair generator is symmetric, deterministic and never mutates boards',
      () {
    final a = BlockBlastEngine(), b = BlockBlastEngine();
    a.grid[0][0] = 1;
    b.grid[7][7] = 2;
    a.score = 2000;
    final before = jsonEncode([a.toJson(), b.toJson()]);
    for (var index = 0; index < 80; index++) {
      final x =
          fairBattleTray(123, index, [a, b]).map((p) => p!.shape).toList();
      expect(fairBattleTray(123, index, [b, a]).map((p) => p!.shape), x);
      expect(fairBattleTray(123, index, [a, b]).map((p) => p!.shape), x);
    }
    expect(jsonEncode([a.toJson(), b.toJson()]), before);
  });
  test('early shared distribution avoids all-large trays without single spam',
      () {
    final boards = [BlockBlastEngine.empty(), BlockBlastEngine.empty()];
    var oldLarge = 0, newLarge = 0, singles = 0;
    for (var seed = 1; seed <= 500; seed++) {
      final old = battleTray(seed * 7919, 0).whereType<BlockPiece>().toList();
      final next = fairBattleTray(seed * 7919, 0, boards)
          .whereType<BlockPiece>()
          .toList();
      if (old.every((p) => p.cells.length >= 5)) oldLarge++;
      if (next.every((p) => p.cells.length >= 5)) newLarge++;
      singles += next.where((p) => p.cells.length == 1).length;
      expect(next.length, 3);
    }
    expect(oldLarge, greaterThan(0));
    expect(newLarge, 0);
    expect(singles, lessThan(150));
  });
  test('ruined boards can still receive an unplayable shared set', () {
    final a = BlockBlastEngine.empty();
    a.grid = List.generate(
        8, (r) => List.generate(8, (c) => (r + c).isEven ? 0 : null));
    var blocked = 0;
    for (var seed = 1; seed <= 50; seed++) {
      a.tray = fairBattleTray(seed, 20, [a, a]);
      if (!a.hasMove) blocked++;
    }
    expect(blocked, greaterThan(25));
  });
  test(
      'client waits for authoritative refill instead of choosing shared pieces',
      () {
    final m = playing();
    final session =
        BlockBattleSession(listen: false, transport: (_, __) async => {})
          ..receive({'me': 1, 'state': m.toJson(), 'connected': true});
    final before = jsonEncode(session.state);
    final prediction = session.engine()!;
    prediction.refill();
    expect(prediction.tray, everyElement(isNull));
    expect(jsonEncode(session.state), before);
    session.dispose();
  });
  for (final value in [499, 999]) {
    test('$value crossing applies exactly one NEW damage threshold', () {
      final m = playing();
      final p = m.player(1);
      single(p, value);
      p.thresholds = value ~/ 500;
      expect(m.place(1, 1, 0, 0, 0, 3001)['ok'], true);
      expect(p.game.score, value + 1);
      expect(m.player(2).lives, 4);
      expect(p.damage, 1);
      final before = jsonEncode(m.toJson());
      expect(m.place(1, 1, 0, 0, 0, 3002)['duplicate'], true);
      expect(jsonEncode(m.toJson()), before);
    });
  }
  for (final target in [499, 500, 999, 1000, 1500, 2000, 2500]) {
    test(
        'cumulative 500 thresholds at $target points, including restore and replay',
        () {
      var m = playing();
      final prior = (target - 1) ~/ 500;
      single(m.player(1), target - 1);
      m.player(1).thresholds = prior;
      m.player(1).damage = prior;
      m.player(2).lives = 5 - prior;
      m = BattleMatch.restore(jsonDecode(jsonEncode(m.toJson())));
      m.place(1, 1, 0, 0, 0, 3001);
      expect(m.player(1).game.score, target);
      expect(m.player(1).damage, target ~/ 500);
      expect(m.player(2).lives, 5 - target ~/ 500);
      final snapshot = jsonEncode(m.toJson());
      m.place(1, 1, 0, 0, 0, 3002);
      expect(jsonEncode(m.toJson()), snapshot);
    });
  }
  for (final start in [490, 950]) {
    test('legal large jump from $start crosses only new thresholds', () {
      final m = playing();
      final p = m.player(1);
      // Keep a second occupied cell so the clear does not add all-clear bonus.
      single(p, start);
      p.game.grid[0] = [null, 0, 0, 0, 0, 0, 0, 0];
      p.game.grid[7][7] = 0;
      p.game.combo = start == 490 ? 13 : 69;
      p.thresholds = start ~/ 500;
      m.place(1, 1, 0, 0, 0, 3001);
      expect(p.game.score, start == 490 ? 631 : 1651);
      expect(p.damage, start == 490 ? 1 : 2);
    });
  }
  test('old damage snapshots rebase without surprise retroactive damage', () {
    final data = playing().toJson()..remove('damageStep');
    data['players'][0]['game']['score'] = 1750;
    data['players'][0]['thresholds'] = 1;
    final m = BattleMatch.restore(data);
    expect(m.player(1).thresholds, 3);
    expect(m.player(2).lives, 5);
    expect(m.toJson()['damageStep'], 500);
  });
  test('multiple thresholds crossed in one legal clear each damage once', () {
    final m = playing();
    final p = m.player(1);
    single(p, 499);
    p.game.grid[0] = [null, 0, 0, 0, 0, 0, 0, 0];
    p.game.combo = 199;
    m.place(1, 1, 0, 0, 0, 3001);
    expect(p.game.score, 2800);
    expect(m.player(2).lives, 0);
    expect(p.damage, 5);
    expect(p.thresholds, 5);
  });
  test('board-out loses one life, preserves score/damage and draws next set',
      () {
    final m = playing();
    final p = m.player(1);
    blocked(p);
    p.game.score = 1450;
    p.thresholds = 2;
    p.damage = 2;
    final set = p.nextSet;
    m.place(1, 1, 0, 0, 1, 3001);
    expect(p.lives, 4);
    expect(p.boardOuts, 1);
    expect(p.game.score, 1451);
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
    p.game.score = 499;
    m.player(2).lives = 1;
    m.place(1, 1, 0, 0, 1, 3001);
    expect(m.winner, 1);
    expect(m.reason, 'score');
    expect(p.boardOuts, 0);
    expect(p.lives, 5);
  });
  test('rematch flow requires mutual consent, resets match and rejects old round moves', () {
    final m = playing();
    m.resign(1, 5000);
    expect(m.status, 'finished');
    expect(m.round, 1);

    // Player 1 requests rematch
    m.rematch(1, 6000);
    expect(m.player(1).rematch, true);
    expect(m.player(2).rematch, false);
    expect(m.status, 'finished');

    // Player 2 requests rematch with new seed
    m.rematch(2, 7000, newSeed: 99999);
    expect(m.status, 'countdown');
    expect(m.round, 2);
    expect(m.seed, 99999);
    expect(m.winner, isNull);
    expect(m.reason, isNull);

    // Both players reset to 5 lives, 0 score, empty boards
    for (final p in m.players) {
      expect(p.lives, 5);
      expect(p.damage, 0);
      expect(p.thresholds, 0);
      expect(p.boardOuts, 0);
      expect(p.rematch, false);
      expect(p.game.score, 0);
    }

    // Advance 3s countdown to playing
    m.advance(10000);
    expect(m.status, 'playing');

    // Move with round 1 is rejected
    final oldMove = m.place(1, 1, 0, 0, 0, 10001, round: 1);
    expect(oldMove['error'], 'Eski round hamlesi.');

    // Move with round 2 succeeds
    final validMove = m.place(1, 1, 0, 0, 0, 10002, round: 2);
    expect(validMove['ok'], true);
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
  test(
      'waiting disconnect does not forfeit match, player can reconnect and 1h expiration works',
      () {
    final m = BattleMatch('WAIT01', 12345, 0);
    m.join(1, 'Player 1', 0);
    m.connect(1, 0);
    expect(m.status, 'waiting');

    // Player 1 disconnects in lobby
    m.disconnect(1, 1000);
    expect(m.player(1).connected, false);
    expect(m.player(1).disconnectAt, isNull);
    expect(m.status, 'waiting');

    // 16+ seconds pass: advance must NOT end match
    m.advance(20000);
    expect(m.status, 'waiting');
    expect(m.finished, false);
    expect(m.reason, isNull);

    // Player 1 reconnects successfully
    m.connect(1, 21000);
    expect(m.player(1).connected, true);
    expect(m.status, 'waiting');

    // Disconnect again and let 1 hour pass (60 * 60 * 1000)
    m.disconnect(1, 22000);
    m.advance(60 * 60 * 1000 + 22000);
    expect(m.status, 'finished');
    expect(m.reason, 'expired');
  });
  test(
      'battle combo tracks singleplayer engine rules: increase, bonus, reset countdown',
      () {
    final m = playing();
    final p = m.player(1);

    // Setup board with row 0 almost full (7 filled, 1 empty at col 0)
    p.game.grid[0] = [null, 0, 0, 0, 0, 0, 0, 0];
    p.game.tray = [
      const BlockPiece(0, 0),
      const BlockPiece(0, 1),
      const BlockPiece(0, 2)
    ];
    expect(p.game.combo, 0);
    expect(p.game.comboBonus, 0);

    // Place single cell at (0, 0) -> clears row 0 -> lines = 1
    final res1 = m.place(1, 1, 0, 0, 0, 3001);
    expect(res1['ok'], true);
    expect(p.game.combo, 1);
    expect(p.game.misses, 0);
    // Formula: 10 * 1^2 * 1 = 10
    expect(p.game.comboBonus, 10);

    // Place piece without line clear (miss 1) -> combo preserved, misses = 1
    p.game.tray = [const BlockPiece(0, 0), const BlockPiece(0, 1), null];
    final res2 = m.place(1, 2, 0, 2, 2, 3002);
    expect(res2['ok'], true);
    expect(p.game.combo, 1);
    expect(p.game.misses, 1);
    expect(p.game.comboBonus, 10); // Preserved from last clear

    // Another miss (miss 2) -> misses = 2
    p.game.tray = [const BlockPiece(0, 0), null, null];
    final res3 = m.place(1, 3, 0, 3, 3, 3003);
    expect(res3['ok'], true);
    expect(p.game.combo, 1);
    expect(p.game.misses, 2);
    expect(p.game.comboBonus, 10);

    // Setup row 4 for clear on 4th move to continue combo
    p.game.grid[4] = [null, 0, 0, 0, 0, 0, 0, 0];
    p.game.tray = [const BlockPiece(0, 0), null, null];
    final res4 = m.place(1, 4, 0, 4, 0, 3004);
    expect(res4['ok'], true);
    expect(p.game.combo, 2); // Increased to 2!
    expect(p.game.misses, 0); // Reset misses!
    // Formula: 10 * 1^2 * 2 = 20
    expect(p.game.comboBonus, 20);

    // Now 3 consecutive misses should reset combo to 0
    for (var i = 1; i <= 3; i++) {
      p.game.tray = [const BlockPiece(0, 0), null, null];
      m.place(1, 4 + i, 0, 5, i, 3004 + i);
    }
    expect(p.game.combo, 0); // Reset!
    expect(p.game.misses, 0);
    expect(p.game.comboBonus, 0);
  });
}
