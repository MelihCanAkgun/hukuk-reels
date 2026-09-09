import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
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
}
