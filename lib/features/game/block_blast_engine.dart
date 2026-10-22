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

  // Büyük L (3x3, 5 hücre) — 4 dönüş
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [2, 1],
    [2, 2]
  ],
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 0],
    [2, 0]
  ],
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 2],
    [2, 2]
  ],
  [
    [0, 2],
    [1, 2],
    [2, 0],
    [2, 1],
    [2, 2]
  ],

  // Çapraz ikili: yalnız kurtarma parçası (normal dağıtımda çıkmaz).
  [
    [0, 0],
    [1, 1]
  ],
  [
    [0, 1],
    [1, 0]
  ],
];

/// Büyük L ve kurtarma parçalarından önceki parça sayısı (eski maç üreticisi).
const legacyShapeCount = 33;

/// Yalnız sıkışmış tahtayı kurtarmak için verilen parçalar.
final rescueShapes = {blockShapes.length - 2, blockShapes.length - 1};

/// Normal dağıtımdaki parça türleri.
final List<int> regularShapes = [
  for (var id = 0; id < blockShapes.length; id++)
    if (!rescueShapes.contains(id)) id
];

/// Kurtarma parçası: sıkışmış tahtada en çok satır/sütun temizleyen parça.
/// Eşitlikte normal parça (çapraz ikili yalnız daha fazla temizliyorsa) ve
/// daha çok hücreye/kenara değen yer. Hiçbir parça temizlemiyorsa null.
(int, int, int)? rescueMove(List<List<int?>> grid) {
  final n = grid.length;
  (int, int, int)? best;
  var bestValue = 0;
  for (var id = 0; id < blockShapes.length; id++) {
    final shape = blockShapes[id];
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!shape.every((e) {
          final y = r + e[0], x = c + e[1];
          return y < n && x < n && grid[y][x] == null;
        })) {
          continue;
        }
        final cells = {for (final e in shape) (r + e[0]) * n + c + e[1]};
        bool filled(int y, int x) =>
            grid[y][x] != null || cells.contains(y * n + x);
        var lines = 0;
        for (var i = 0; i < n; i++) {
          if (List.generate(n, (j) => filled(i, j)).every((v) => v)) lines++;
          if (List.generate(n, (j) => filled(j, i)).every((v) => v)) lines++;
        }
        if (lines == 0) continue;
        final value =
            lines * 100 + (rescueShapes.contains(id) ? 0 : 50) + shape.length;
        if (value > bestValue) {
          bestValue = value;
          best = (id, r, c);
        }
      }
    }
  }
  return best;
}

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
  /// Başlangıç tahtası 8×8; genişletme jokeri bir kez 9×9 yapar.
  static const baseSize = 8;

  /// Billur tuz jokerinin hücresi: engel. Üstüne parça konamaz ve içinden
  /// geçen satır/sütun tamamlanamaz (renk değil).
  static const saltCell = 8;
  static bool _solid(int? v) => v != null && v != saltCell;
  static const comboGrace = 3;

  /// Kurtarma parçası en çok bu kadar sette bir verilir ve yalnız tahta
  /// sıkışmışken, yarı yarıya şansla.
  static const rescueGap = 6;
  final Random random;
  final List<BlockPiece?> Function()? nextTray;
  List<List<int?>> grid =
      List.generate(baseSize, (_) => List.filled(baseSize, null));
  int get size => grid.length;

  /// Son kurtarma parçasından beri verilen set sayısı.
  int sinceRescue = rescueGap;
  List<BlockPiece?> tray = [null, null, null];
  int score = 0, combo = 0, misses = 0, comboBonus = 0;
  // Run summary counters are presentation data; they never affect move rules.
  int placementsMade = 0, linesCleared = 0, bestCombo = 0, allClears = 0;
  bool runSummaryAvailable = true;
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
          for (var r = 0; r < b.length; r++)
            if (b[r].every(_solid)) r
        ],
        [
          for (var c = 0; c < b.length; c++)
            if (List.generate(b.length, (r) => b[r][c]).every(_solid)) c
        ],
      );

  /// Dolu satır/sütunları siler; anahtar r * n + c.
  static Map<int, int> _clear(List<List<int?>> b) {
    final (rows, cols) = _lines(b);
    final n = b.length;
    final cells = <int, int>{
      for (final r in rows)
        for (var c = 0; c < n; c++) r * n + c: b[r][c]!,
      for (final c in cols)
        for (var r = 0; r < n; r++) r * n + c: b[r][c]!,
    };
    for (final k in cells.keys) {
      b[k ~/ n][k % n] = null;
    }
    return cells;
  }

  /// Genişletme jokeri: tahta [corner] köşesine doğru bir satır ve bir sütun
  /// büyür ('tl', 'tr', 'bl', 'br'). Yalnız 8×8 tahtada bir kez.
  bool expand(String corner) {
    if (size != baseSize || !const {'tl', 'tr', 'bl', 'br'}.contains(corner)) {
      return false;
    }
    final dr = corner[0] == 't' ? 1 : 0, dc = corner[1] == 'l' ? 1 : 0;
    final n = size + 1;
    grid = List.generate(
        n,
        (r) => List.generate(n, (c) {
              final y = r - dr, x = c - dc;
              return y >= 0 && y < size && x >= 0 && x < size
                  ? grid[y][x]
                  : null;
            }));
    return true;
  }

  /// Genişletmenin süresi bitti: [corner] tarafına eklenen satır ve sütun
  /// gider (üstündeki bloklarla). Kısalınca dolan satırlar puansız silinir.
  bool shrink(String corner) {
    if (size != baseSize + 1 ||
        !const {'tl', 'tr', 'bl', 'br'}.contains(corner)) {
      return false;
    }
    final dr = corner[0] == 't' ? 1 : 0, dc = corner[1] == 'l' ? 1 : 0;
    grid = List.generate(
        baseSize, (r) => List.generate(baseSize, (c) => grid[r + dr][c + dc]));
    _clear(grid);
    return true;
  }

  /// Billur tuz: tahtanın ortasına 1 en 3 boy tuzluk; altındaki bloklar
  /// gider.
  void placeSalt() {
    final top = (size - 2) ~/ 2, col = size ~/ 2;
    for (var r = top; r < top + 3; r++) {
      grid[r][col] = saltCell;
    }
  }

  void removeSalt() {
    for (final row in grid) {
      for (var c = 0; c < row.length; c++) {
        if (row[c] == saltCell) row[c] = null;
      }
    }
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
    placementsMade++;
    _stamp(grid, p, r, c);
    tray[slot] = null;
    final (rows, cols) = _lines(grid);
    final lines = rows.length + cols.length;
    final cleared = _clear(grid);
    if (lines > 0) {
      combo++;
      linesCleared += lines;
      bestCombo = max(bestCombo, combo);
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
    if (allClear) allClears++;
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
    sinceRescue++;
    // Sıkışmış tahtaya seyrek bir kurtarma parçası: bir boşluğu kapatıp satır
    // temizleyen parça (gerekirse çapraz ikili) setin ilk parçası olur.
    if (sinceRescue >= rescueGap &&
        tightBoard(scratch) &&
        random.nextDouble() < .5) {
      final rescue = rescueMove(scratch);
      if (rescue != null) {
        final p = BlockPiece(rescue.$1, rescue.$1 % 8);
        pieces.add(p);
        _stamp(scratch, p, rescue.$2, rescue.$3);
        _clear(scratch);
        sinceRescue = 0;
      }
    }
    for (var slot = pieces.length; slot < 3; slot++) {
      final candidates = <(BlockPiece, List<(int, int)>, double)>[];
      final fill = scratch.expand((r) => r).where((v) => v != null).length /
          (scratch.length * scratch.length);
      for (final id in regularShapes) {
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

  /// Sıkışık tahta: yarıdan fazlası dolu ve normal parça türlerinin üçte
  /// birinden azı bir yere sığıyor.
  static bool tightBoard(List<List<int?>> b) {
    final n = b.length;
    final fill = b.expand((r) => r).where((v) => v != null).length / (n * n);
    if (fill < .5) return false;
    final probe = BlockBlastEngine.empty()..grid = b;
    final open = regularShapes
        .where((id) => probe.placements(BlockPiece(id, 0)).isNotEmpty)
        .length;
    return open < regularShapes.length / 3;
  }

  void revive() {
    reviveUsed = true;
    combo = 0;
    misses = 0;
    comboBonus = 0;
    grid = List.generate(baseSize, (_) => List.filled(baseSize, null));
    if (tray.every((p) => p == null)) refill();
  }

  Map<String, dynamic> toJson({bool includeRunSummary = false}) {
    final data = <String, dynamic>{
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
      'sinceRescue': sinceRescue,
    };
    if (includeRunSummary) {
      data.addAll({
        'placementsMade': placementsMade,
        'linesCleared': linesCleared,
        'bestCombo': bestCombo,
        'allClears': allClears,
        'runSummaryAvailable': runSummaryAvailable,
      });
    }
    return data;
  }

  static BlockBlastEngine? restore(Map<String, dynamic>? data,
      {Random? random, List<BlockPiece?> Function()? nextTray}) {
    if (data == null) return null;
    try {
      if (data['version'] != 1) return null;
      final b = (data['grid'] as List)
          .map((row) => (row as List).map((v) {
                if (v != null && (v is! int || v < 0 || v > saltCell)) {
                  throw const FormatException();
                }
                return v as int?;
              }).toList())
          .toList();
      if ((b.length != baseSize && b.length != baseSize + 1) ||
          b.any((r) => r.length != b.length)) {
        return null;
      }
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
          comboBonus = data['comboBonus'] as int? ?? 0,
          placementsMade = data['placementsMade'] as int? ?? 0,
          linesCleared = data['linesCleared'] as int? ?? 0,
          bestCombo = data['bestCombo'] as int? ?? combo,
          allClears = data['allClears'] as int? ?? 0,
          runSummaryAvailable = data['runSummaryAvailable'] as bool? ??
              (data.containsKey('placementsMade') &&
                  data.containsKey('linesCleared') &&
                  data.containsKey('bestCombo') &&
                  data.containsKey('allClears'));
      if (score < 0 ||
          combo < 0 ||
          misses < 0 ||
          misses >= comboGrace ||
          (combo == 0 && misses != 0) ||
          placementsMade < 0 ||
          linesCleared < 0 ||
          allClears < 0) {
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
        ..reviveUsed = data['reviveUsed'] as bool
        ..sinceRescue = data['sinceRescue'] as int? ?? rescueGap
        ..placementsMade = placementsMade
        ..linesCleared = linesCleared
        ..bestCombo = bestCombo
        ..allClears = allClears
        ..runSummaryAvailable = runSummaryAvailable;
    } catch (_) {
      return null;
    }
  }
}
