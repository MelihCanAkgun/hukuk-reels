import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';

BlockBlastEngine emptyGame() => BlockBlastEngine(random: Random(7))
  ..tray = [
    const BlockPiece(0, 0),
    const BlockPiece(0, 1),
    const BlockPiece(0, 2)
  ];

// Independent solver, including simultaneous row/column clearing. It deliberately
// does not use the engine's fits/place implementation to verify generated trays.
bool solvable(List<List<int?>> board, List<BlockPiece> pieces) {
  if (pieces.isEmpty) return true;
  for (var i = 0; i < pieces.length; i++) {
    final p = pieces[i];
    for (var r = 0; r <= 8 - p.rows; r++) {
      for (var c = 0; c <= 8 - p.cols; c++) {
        if (p.cells.any((v) => board[r + v[0]][c + v[1]] != null)) continue;
        final b = [
          for (final row in board) [...row]
        ];
        for (final v in p.cells) {
          b[r + v[0]][c + v[1]] = 0;
        }
        final rows = [
          for (var y = 0; y < 8; y++)
            if (b[y].every((v) => v != null)) y
        ];
        final cols = [
          for (var x = 0; x < 8; x++)
            if (b.every((row) => row[x] != null)) x
        ];
        for (final y in rows) {
          for (var x = 0; x < 8; x++) {
            b[y][x] = null;
          }
        }
        for (final x in cols) {
          for (var y = 0; y < 8; y++) {
            b[y][x] = null;
          }
        }
        final rest = [...pieces]..removeAt(i);
        if (solvable(b, rest)) return true;
      }
    }
  }
  return false;
}

void main() {
  test('illegal placement does not mutate score, tray or board', () {
    final game = emptyGame();
    final before = jsonEncode(game.toJson());
    expect(game.place(0, -1, 0), isNull);
    expect(game.place(3, 0, 0), isNull);
    expect(jsonEncode(game.toJson()), before);
    game.place(0, 0, 0);
    expect(game.place(1, 0, 0), isNull);
    expect(game.place(0, 1, 0), isNull);
    expect(game.score, 1);
  });

  test('cross clear scores both lines and clears intersection once', () {
    final game = emptyGame();
    for (var i = 1; i < 8; i++) {
      game.grid[0][i] = 0;
      game.grid[i][0] = 1;
    }
    game.grid[7][7] = 2; // excludes all-clear bonus
    expect(game.preview(game.tray[0]!, 0, 0).length, 15);
    final move = game.place(0, 0, 0)!;
    expect(move.lines, 2);
    expect(move.clearedCells.length, 15);
    expect(move.points, 41);
    expect(game.grid[7][7], 2);
    expect(game.combo, 1);
  });

  test('combo survives two misses and expires on third', () {
    final game = emptyGame();
    for (var c = 1; c < 8; c++) {
      game.grid[0][c] = 0;
    }
    game.place(0, 0, 0);
    expect(game.combo, 1);
    game.place(1, 1, 1);
    game.place(2, 2, 2);
    expect(game.combo, 1);
    expect(game.misses, 2);
    game.tray = [const BlockPiece(0, 0), null, null];
    game.place(0, 3, 3);
    expect(game.combo, 0);
    expect(game.misses, 0);
  });

  test('next clear increases combo and all-clear has explicit bonus', () {
    final game = emptyGame();
    for (var c = 1; c < 8; c++) {
      game.grid[0][c] = 0;
    }
    expect(game.place(0, 0, 0)!.points, 311);
    for (var c = 1; c < 8; c++) {
      game.grid[0][c] = 0;
    }
    expect(game.place(1, 0, 0)!.points, 321);
    expect(game.combo, 2);
    expect(game.score, 632);
  });

  test('run summary counters persist without changing scoring rules', () {
    final game = emptyGame();
    for (var c = 1; c < 8; c++) {
      game.grid[0][c] = 0;
    }
    final first = game.place(0, 0, 0)!;
    expect(first.lines, 1);
    expect(first.allClear, isTrue);
    for (var c = 1; c < 8; c++) {
      game.grid[0][c] = 1;
    }
    final second = game.place(1, 0, 0)!;
    expect(second.lines, 1);
    expect(second.allClear, isTrue);
    expect(game.placementsMade, 2);
    expect(game.linesCleared, 2);
    expect(game.bestCombo, 2);
    expect(game.allClears, 2);
    expect(game.toJson().containsKey('linesCleared'), isFalse,
        reason: 'Battle serialization remains unchanged by singleplayer stats');

    final restored = BlockBlastEngine.restore(
        jsonDecode(jsonEncode(game.toJson(includeRunSummary: true))))!;
    expect(restored.placementsMade, 2);
    expect(restored.linesCleared, 2);
    expect(restored.bestCombo, 2);
    expect(restored.allClears, 2);
    expect(restored.runSummaryAvailable, isTrue);
  });

  test('older saved games restore with empty run summary counters', () {
    final save = emptyGame().toJson()
      ..remove('placementsMade')
      ..remove('linesCleared')
      ..remove('bestCombo')
      ..remove('allClears');
    final restored = BlockBlastEngine.restore(save)!;
    expect(restored.placementsMade, 0);
    expect(restored.linesCleared, 0);
    expect(restored.bestCombo, 0);
    expect(restored.allClears, 0);
    expect(restored.runSummaryAvailable, isFalse);
  });

  test('tray refills only after all three pieces have been used', () {
    final game = emptyGame();
    game.place(0, 0, 0);
    expect(game.tray[0], isNull);
    game.place(1, 1, 1);
    expect(game.tray.whereType<BlockPiece>().length, 1);
    game.place(2, 2, 2);
    expect(game.tray.whereType<BlockPiece>().length, 3);
  });

  test('generated trays have a legal full sequence across board pressures', () {
    final random = Random(411);
    for (var seed = 0; seed < 90; seed++) {
      final game = BlockBlastEngine(random: Random(seed));
      final density = (seed % 9) / 10;
      game.grid = List.generate(
          8,
          (_) => List.generate(
              8, (_) => random.nextDouble() < density ? 0 : null));
      // Avoid starting with full lines (invalid live-game state).
      for (var i = 0; i < 8; i++) {
        game.grid[i][i] = null;
      }
      game.refill();
      expect(game.tray.whereType<BlockPiece>().length, 3, reason: 'seed $seed');
      expect(solvable(game.grid, game.tray.whereType<BlockPiece>().toList()),
          isTrue,
          reason: 'seed $seed');
    }
  });

  test('session round trip preserves board, partial tray, combo and revive',
      () {
    final game = emptyGame()..combo = 2;
    game.place(0, 2, 3);
    game.reviveUsed = true;
    final restored =
        BlockBlastEngine.restore(jsonDecode(jsonEncode(game.toJson())));
    expect(restored, isNotNull);
    expect(restored!.toJson(), game.toJson());
  });

  test('corrupt and unsupported sessions are safely rejected', () {
    for (final patch in [
      {'version': 99},
      {'grid': []},
      {
        'tray': [
          [999, 0],
          null,
          null
        ]
      },
      {'score': -1},
      {'misses': 3},
      {'reviveUsed': 'yes'},
      {
        'tray': [null, null, null]
      },
    ]) {
      expect(BlockBlastEngine.restore({...emptyGame().toJson(), ...patch}),
          isNull);
    }
  });

  test('game over checks every remaining piece; revive preserves score', () {
    final game = emptyGame();
    game.grid = List.generate(8, (_) => List.filled(8, 0));
    game.grid[0][0] = null;
    game.tray = [const BlockPiece(9, 0), null, null];
    expect(game.hasMove, isFalse);
    game.tray[1] = const BlockPiece(0, 1);
    expect(game.hasMove, isTrue);
    game.score = 123;
    game.combo = 4;
    game.revive();
    expect(game.hasMove, isTrue);
    expect(game.score, 123);
    expect(game.combo, 0);
    expect(game.reviveUsed, isTrue);
  });

  test('büyük L dört dönüşüyle var; çapraz ikili yalnız kurtarmada', () {
    final big = [
      for (var id = 0; id < blockShapes.length; id++)
        if (blockShapes[id].length == 5 &&
            BlockPiece(id, 0).rows == 3 &&
            BlockPiece(id, 0).cols == 3)
          {for (final c in blockShapes[id]) c[0] * 3 + c[1]}
    ];
    expect(big.length, 4);
    expect(big.toSet().length, 4);
    expect(rescueShapes.length, 2);
    expect(regularShapes.any(rescueShapes.contains), false);
    // Normal dağıtım çapraz ikiliyi hiç vermez.
    final engine = BlockBlastEngine(random: Random(1));
    for (var i = 0; i < 300; i++) {
      engine.grid = List.generate(8, (_) => List.filled(8, null));
      engine.refill();
      expect(engine.tray.any((p) => rescueShapes.contains(p!.shape)), false);
    }
  });

  test('çapraz iki boşluk: kurtarma parçası çapraz ikili', () {
    final grid = List.generate(8, (_) => List<int?>.filled(8, 0));
    grid[3][3] = null;
    grid[4][4] = null;
    final move = rescueMove(grid)!;
    expect(rescueShapes.contains(move.$1), true);
    expect((move.$2, move.$3), (3, 3));
  });

  test('kurtarma seyrek: yalnız sıkışık tahtada ve en az 6 sette bir', () {
    var rescues = 0, sets = 0, lastAt = -100;
    for (var seed = 0; seed < 40; seed++) {
      final engine = BlockBlastEngine.empty(random: Random(seed));
      for (var i = 0; i < 30; i++) {
        // Sıkışık tahta: yalnız iki satırın ve sütunun birer hücresi boş.
        engine.grid = List.generate(8, (_) => List<int?>.filled(8, 0));
        engine.grid[2][2] = null;
        engine.grid[5][6] = null;
        final before = engine.sinceRescue;
        engine.refill();
        sets++;
        if (engine.sinceRescue == 0) {
          rescues++;
          expect(before + 1, greaterThanOrEqualTo(BlockBlastEngine.rescueGap));
          if (lastAt >= 0) expect(i - lastAt, greaterThanOrEqualTo(6));
          lastAt = i;
        }
      }
      lastAt = -100;
    }
    expect(rescues, greaterThan(0));
    // Sürekli sıkışık tahtada bile setlerin ancak küçük bir kısmı.
    expect(rescues / sets, lessThan(.2));
    // Boş tahtada hiç kurtarma yok.
    final open = BlockBlastEngine(random: Random(3));
    for (var i = 0; i < 100; i++) {
      open.grid = List.generate(8, (_) => List.filled(8, null));
      open.refill();
      expect(open.sinceRescue, isNot(0));
    }
  });

  test('eski kayıt (kurtarma sayacı yok) aynı skorla açılır', () {
    final game = emptyGame()..score = 1234;
    final data = game.toJson()..remove('sinceRescue');
    final restored = BlockBlastEngine.restore(data)!;
    expect(restored.score, 1234);
    expect(restored.sinceRescue, BlockBlastEngine.rescueGap);
    expect(BlockBlastEngine.restore(restored.toJson())!.sinceRescue,
        BlockBlastEngine.rescueGap);
  });

  test('eski maç üreticisi değişmedi; ortak sette kurtarma seyrek', () {
    for (var i = 0; i < 200; i++) {
      for (final p in battleTray(42, i)) {
        expect(p!.shape, lessThan(legacyShapeCount));
      }
    }
    // Sıkışık iki tahta: kurtarma ancak izin verildiğinde ve seyrek.
    var rescued = 0;
    for (var i = 0; i < 60; i++) {
      final boards = [
        for (var b = 0; b < 2; b++)
          BlockBlastEngine.empty(nextTray: () => [null, null, null])
            ..grid = (List.generate(8, (_) => List<int?>.filled(8, 0))
              ..[2][2] = null
              ..[5][6] = null)
      ];
      expect(fairBattleSet(42, i, boards).$2, false);
      if (fairBattleSet(42, i, boards, rescue: true).$2) rescued++;
    }
    expect(rescued, greaterThan(0));
    final m = BattleMatch('ABC234', 42, 0);
    final copy = BattleMatch.restore(
        jsonDecode(jsonEncode((m..lastRescue = 7).toJson()))
            as Map<String, dynamic>);
    expect(copy.lastRescue, 7);
  });
}
