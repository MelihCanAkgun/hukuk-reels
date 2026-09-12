// dart run tools/battle_generation_simulation.dart [runs=500] [moveCap=180] [--check]
// Same bounded greedy policy for every generator; not a claim about human play.
import 'dart:convert';
import 'dart:io';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';

(int, int, int)? botMove(BlockBlastEngine game, BattleRandom rng) {
  (int, int, int)? best;
  var bestValue = -1e9;
  for (var slot = 0; slot < 3; slot++) {
    final p = game.tray[slot];
    if (p == null) continue;
    for (final (r, c) in game.placements(p)) {
      var adjacent = 0;
      for (final cell in p.cells) {
        final y = r + cell[0], x = c + cell[1];
        for (final (dy, dx) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final yy = y + dy, xx = x + dx;
          if (yy < 0 ||
              yy >= 8 ||
              xx < 0 ||
              xx >= 8 ||
              game.grid[yy][xx] != null) {
            adjacent++;
          }
        }
      }
      final value = game.preview(p, r, c).length * 20 +
          adjacent * 2 +
          p.cells.length +
          rng.nextDouble();
      if (value > bestValue) {
        bestValue = value;
        best = (slot, r, c);
      }
    }
  }
  return best;
}

void main(List<String> args) {
  final check = args.contains('--check');
  args = args.where((a) => a != '--check').toList();
  final runs = args.isEmpty ? 500 : int.parse(args[0]);
  final cap = args.length < 2 ? 180 : int.parse(args[1]);
  final results = <String, dynamic>{
    'runsPerMode': runs,
    'moveCap': cap,
    'policy':
        'greedy clears + edge/occupied adjacency; independent fixed tie RNG'
  };
  for (final mode in ['solo', 'legacy', 'shared']) {
    final counts = <int>[];
    final shapes = List.filled(blockShapes.length, 0);
    var deadOnRefill = 0;
    for (var seed = 1; seed <= runs; seed++) {
      final games = <BlockBlastEngine>[];
      final cache = <int, List<BlockPiece?>>{};
      for (var id = 0; id < 2; id++) {
        var index = 0;
        final game =
            BlockBlastEngine.empty(random: BattleRandom(seed * 7919, id));
        games.add(game);
        if (mode != 'solo') {
          // Provider is attached before the initial refill.
          games[id] = BlockBlastEngine.empty(nextTray: () {
            final set = index++;
            final tray = mode == 'legacy'
                ? battleTray(seed * 7919, set)
                : cache.putIfAbsent(
                    set, () => fairBattleTray(seed * 7919, set, games));
            for (final p in tray.whereType<BlockPiece>()) {
              shapes[p.shape]++;
            }
            return [...tray];
          });
        }
      }
      for (final game in games) {
        game.refill();
        if (mode == 'solo') {
          for (final p in game.tray.whereType<BlockPiece>()) {
            shapes[p.shape]++;
          }
        }
      }
      final moves = [0, 0], done = [false, false];
      final rngs = [BattleRandom(seed * 17, 0), BattleRandom(seed * 17, 1)];
      for (var turn = 0; turn < cap * 2; turn++) {
        final id = turn % 2, game = games[id];
        if (done[id]) continue;
        final move = botMove(game, rngs[id]);
        if (move == null) {
          done[id] = true;
          // Battle resets an out board; do not keep a dead opponent's blocked
          // board in every later candidate evaluation of the survivor.
          game.grid = List.generate(8, (_) => List<int?>.filled(8, null));
          game.tray = [null, null, null];
          continue;
        }
        final refill = game.tray.whereType<BlockPiece>().length == 1;
        game.place(move.$1, move.$2, move.$3);
        moves[id]++;
        if (refill) {
          if (!game.hasMove) deadOnRefill++;
          if (mode == 'solo') {
            for (final p in game.tray.whereType<BlockPiece>()) {
              shapes[p.shape]++;
            }
          }
        }
      }
      counts.addAll(moves);
    }
    counts.sort();
    final total = shapes.fold(0, (a, b) => a + b);
    results[mode] = {
      'players': counts.length,
      'meanMovesToOutCapped': counts.reduce((a, b) => a + b) / counts.length,
      'medianMoves': counts[counts.length ~/ 2],
      'earlyOutAt12': counts.where((n) => n <= 12).length,
      'earlyOutAt24': counts.where((n) => n <= 24).length,
      'reachedCap': counts.where((n) => n == cap).length,
      'deadOnRefill': deadOnRefill,
      'meanPieceCells':
          List.generate(shapes.length, (i) => shapes[i] * blockShapes[i].length)
                  .reduce((a, b) => a + b) /
              total,
      'shapeCounts': shapes
    };
  }
  final solo = results['solo'] as Map,
      shared = results['shared'] as Map,
      legacy = results['legacy'] as Map;
  final a = (solo['shapeCounts'] as List).cast<int>(),
      b = (shared['shapeCounts'] as List).cast<int>();
  final totalA = a.reduce((x, y) => x + y), totalB = b.reduce((x, y) => x + y);
  final distance =
      List.generate(a.length, (i) => (a[i] / totalA - b[i] / totalB).abs())
              .reduce((x, y) => x + y) /
          2;
  results['comparison'] = {
    'shapeTotalVariation': distance,
    'sharedToSoloCappedMean':
        shared['meanMovesToOutCapped'] / solo['meanMovesToOutCapped']
  };
  if (check) {
    if (runs < 200 ||
        shared['meanMovesToOutCapped'] < solo['meanMovesToOutCapped'] * .85 ||
        shared['earlyOutAt24'] > legacy['earlyOutAt24'] * .6 ||
        distance > .10 ||
        shared['reachedCap'] == shared['players']) {
      throw StateError('Generator simulation regression: $results');
    }
    results['regressionChecks'] = 'passed';
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(results));
}
