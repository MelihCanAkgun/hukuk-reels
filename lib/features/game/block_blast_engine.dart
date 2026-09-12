import 'dart:math';

const List<List<List<int>>> blockShapes = [
  // Tekli
  [
    [0, 0]
  ],

  // İkili (yatay / dikey)
  [
    [0, 0],
    [0, 1]
  ],
  [
    [0, 0],
    [1, 0]
  ],

  // Üçlü çizgi
  [
    [0, 0],
    [0, 1],
    [0, 2]
  ],
  [
    [0, 0],
    [1, 0],
    [2, 0]
  ],

  // Dörtlü çizgi
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [0, 3]
  ],
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [3, 0]
  ],

  // Beşli çizgi
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [0, 3],
    [0, 4]
  ],
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [3, 0],
    [4, 0]
  ],

  // 2x2 kare
  [
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
  ],

  // 3x3 kare
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 0],
    [1, 1],
    [1, 2],
    [2, 0],
    [2, 1],
    [2, 2]
  ],

  // Küçük L köşe (3 hücre) — 4 dönüş
  [
    [0, 0],
    [0, 1],
    [1, 0]
  ],
  [
    [0, 0],
    [0, 1],
    [1, 1]
  ],
  [
    [0, 0],
    [1, 0],
    [1, 1]
  ],
  [
    [0, 1],
    [1, 0],
    [1, 1]
  ],

  // L (4 hücre) — 4 dönüş
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [2, 1]
  ],
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 0]
  ],
  [
    [0, 0],
    [0, 1],
    [1, 1],
    [2, 1]
  ],
  [
    [0, 2],
    [1, 0],
    [1, 1],
    [1, 2]
  ],

  // J (4 hücre) — 4 dönüş
  [
    [0, 1],
    [1, 1],
    [2, 0],
    [2, 1]
  ],
  [
    [0, 0],
    [1, 0],
    [1, 1],
    [1, 2]
  ],
  [
    [0, 0],
    [0, 1],
    [1, 0],
    [2, 0]
  ],
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 2]
  ],

  // T (4 hücre) — 4 dönüş
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 1]
  ],
  [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, 2]
  ],
  [
    [0, 0],
    [1, 0],
    [1, 1],
    [2, 0]
  ],
  [
    [0, 1],
    [1, 0],
    [1, 1],
    [2, 1]
  ],

  // S / Z (4 hücre)
  [
    [0, 1],
    [0, 2],
    [1, 0],
    [1, 1]
  ],
  [
    [0, 0],
    [1, 0],
    [1, 1],
    [2, 1]
  ],
  [
    [0, 0],
    [0, 1],
    [1, 1],
    [1, 2]
  ],
  [
    [0, 1],
    [1, 0],
    [1, 1],
    [2, 0]
  ],

  // Dikdörtgenler
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 0],
    [1, 1],
    [1, 2]
  ], // 2x3
  [
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1],
    [2, 0],
    [2, 1]
  ], // 3x2
];

/// Immutable pieces and pure rules: no widget, audio or storage dependencies.
class BlockPiece {
  final int shape;
  final int color;
  const BlockPiece(this.shape, this.color);
  List<List<int>> get cells => blockShapes[shape];
  int get rows => cells.map((e) => e[0]).reduce(max) + 1;
  int get cols => cells.map((e) => e[1]).reduce(max) + 1;
  bool has(int r, int c) => cells.any((e) => e[0] == r && e[1] == c);
}

class BlockMove {
  final Map<int, int> clearedCells;
  final int lines, points;
  final bool allClear;
  const BlockMove(this.clearedCells, this.lines, this.points, this.allClear);
}

class BlockBlastEngine {
  static const size = 8;
  static const comboGrace = 3;
  final Random random;
  final List<BlockPiece?> Function()? nextTray;
  List<List<int?>> grid = List.generate(size, (_) => List.filled(size, null));
  List<BlockPiece?> tray = [null, null, null];
  int score = 0, combo = 0, misses = 0, comboBonus = 0;
  bool reviveUsed = false;
  BlockBlastEngine({Random? random, this.nextTray})
      : random = random ?? Random() {
    refill();
  }

  BlockBlastEngine.empty({Random? random, this.nextTray})
      : random = random ?? Random();

  bool fits(BlockPiece p, int r, int c, [List<List<int?>>? board]) {
    final b = board ?? grid;
    return p.cells.every((cell) {
      final y = r + cell[0], x = c + cell[1];
      return y >= 0 && y < size && x >= 0 && x < size && b[y][x] == null;
    });
  }

  List<(int, int)> placements(BlockPiece p, [List<List<int?>>? board]) => [
        for (var r = 0; r <= size - p.rows; r++)
          for (var c = 0; c <= size - p.cols; c++)
            if (fits(p, r, c, board)) (r, c),
      ];
  bool canPlace(BlockPiece p) => placements(p).isNotEmpty;
  bool get hasMove => tray.any((p) => p != null && canPlace(p));

  static (List<int>, List<int>) _lines(List<List<int?>> b) => (
        [
          for (var r = 0; r < size; r++)
            if (b[r].every((v) => v != null)) r
        ],
        [
          for (var c = 0; c < size; c++)
            if (List.generate(size, (r) => b[r][c]).every((v) => v != null)) c
        ],
      );
  static Map<int, int> _clear(List<List<int?>> b) {
    final (rows, cols) = _lines(b);
    final cells = <int, int>{
      for (final r in rows)
        for (var c = 0; c < size; c++) r * size + c: b[r][c]!,
      for (final c in cols)
        for (var r = 0; r < size; r++) r * size + c: b[r][c]!,
    };
    for (final k in cells.keys) {
      b[k ~/ size][k % size] = null;
    }
    return cells;
  }

  static List<List<int?>> _copy(List<List<int?>> b) => [
        for (final row in b) [...row]
      ];
  static void _stamp(List<List<int?>> b, BlockPiece p, int r, int c) {
    for (final cell in p.cells) {
      b[r + cell[0]][c + cell[1]] = p.color;
    }
  }

  Set<int> preview(BlockPiece p, int r, int c) {
    if (!fits(p, r, c)) return {};
    final b = _copy(grid);
    _stamp(b, p, r, c);
    return _clear(b).keys.toSet();
  }

  BlockMove? place(int slot, int r, int c) {
    if (slot < 0 || slot >= tray.length) return null;
    final p = tray[slot];
    if (p == null || !fits(p, r, c)) return null;
    _stamp(grid, p, r, c);
    tray[slot] = null;
    final (rows, cols) = _lines(grid);
    final lines = rows.length + cols.length;
    final cleared = _clear(grid);
    if (lines > 0) {
      combo++;
      misses = 0;
      comboBonus = 10 * lines * lines * combo;
    } else if (combo > 0) {
      misses++;
      if (misses >= comboGrace) {
        combo = 0;
        misses = 0;
        comboBonus = 0;
      }
    }
    final allClear =
        lines > 0 && grid.every((row) => row.every((v) => v == null));
    // Tunable approximation, not Hungry Studio's unpublished scoring formula.
    final points =
        p.cells.length + 10 * lines * lines * combo + (allClear ? 300 : 0);
    score += points;
    if (tray.every((p) => p == null)) refill();
    return BlockMove(cleared, lines, points, allClear);
  }

  /// Construct a legal three-move sequence on a scratch board, clearing
  /// lines after each step. Shuffle its pieces so order remains a puzzle.
  /// Independent "fits now" checks cannot ensure a whole tray is solvable.
  void refill() {
    if (nextTray != null) {
      tray = nextTray!();
      return;
    }
    final scratch = _copy(grid);
    final pieces = <BlockPiece>[];
    for (var slot = 0; slot < 3; slot++) {
      final candidates = <(BlockPiece, List<(int, int)>, double)>[];
      final fill = scratch.expand((r) => r).where((v) => v != null).length / 64;
      for (var id = 0; id < blockShapes.length; id++) {
        final p = BlockPiece(id, id % 8);
        final spots = placements(p, scratch);
        if (spots.isEmpty) continue;
        var weight = p.cells.length == 1 ? 0.18 : 1.0;
        if (p.cells.length >= 5) weight *= 1.3 + min(score / 5000, 0.7);
        if (fill > 0.65 && p.cells.length <= 3) weight *= 1.8;
        if (pieces.any((old) => old.shape == id)) weight *= 0.25;
        candidates.add((p, spots, weight));
      }
      if (candidates.isEmpty) break;
      var roll =
          random.nextDouble() * candidates.fold(0.0, (sum, e) => sum + e.$3);
      var pick = candidates.last;
      for (final candidate in candidates) {
        roll -= candidate.$3;
        if (roll <= 0) {
          pick = candidate;
          break;
        }
      }
      final spot = pick.$2[random.nextInt(pick.$2.length)];
      pieces.add(pick.$1);
      _stamp(scratch, pick.$1, spot.$1, spot.$2);
      _clear(scratch);
    }
    pieces.shuffle(random);
    tray = List.generate(3, (i) => i < pieces.length ? pieces[i] : null);
  }

  void revive() {
    reviveUsed = true;
    combo = 0;
    misses = 0;
    comboBonus = 0;
    grid = List.generate(size, (_) => List.filled(size, null));
    if (tray.every((p) => p == null)) refill();
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'grid': grid,
        'tray': [
          for (final p in tray) p == null ? null : [p.shape, p.color]
        ],
        'score': score,
        'combo': combo,
        'misses': misses,
        'comboBonus': comboBonus,
        'reviveUsed': reviveUsed,
      };
  static BlockBlastEngine? restore(Map<String, dynamic>? data,
      {Random? random, List<BlockPiece?> Function()? nextTray}) {
    if (data == null) return null;
    try {
      if (data['version'] != 1) return null;
      final b = (data['grid'] as List)
          .map((row) => (row as List).map((v) {
                if (v != null && (v is! int || v < 0 || v >= 8)) {
                  throw const FormatException();
                }
                return v as int?;
              }).toList())
          .toList();
      if (b.length != size || b.any((r) => r.length != size)) return null;
      final t = (data['tray'] as List).map((v) {
        if (v == null) return null;
        if (v is! List ||
            v.length != 2 ||
            v[0] is! int ||
            v[1] is! int ||
            v[0] < 0 ||
            v[0] >= blockShapes.length ||
            v[1] < 0 ||
            v[1] >= 8) {
          throw const FormatException();
        }
        return BlockPiece(v[0], v[1]);
      }).toList();
      if (t.length != 3 || t.every((p) => p == null)) return null;
      final score = data['score'] as int,
          combo = data['combo'] as int,
          misses = data['misses'] as int,
          comboBonus = data['comboBonus'] as int? ?? 0;
      if (score < 0 ||
          combo < 0 ||
          misses < 0 ||
          misses >= comboGrace ||
          (combo == 0 && misses != 0)) {
        return null;
      }
      final (rows, cols) = _lines(b);
      if (rows.isNotEmpty || cols.isNotEmpty) return null;
      return BlockBlastEngine.empty(random: random, nextTray: nextTray)
        ..grid = b
        ..tray = t
        ..score = score
        ..combo = combo
        ..misses = misses
        ..comboBonus = comboBonus
        ..reviveUsed = data['reviveUsed'] as bool;
    } catch (_) {
      return null;
    }
  }
}
