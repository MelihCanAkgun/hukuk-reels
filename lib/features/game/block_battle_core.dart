import 'dart:math';
import 'dart:typed_data';
import 'block_blast_engine.dart';

/// Battle rules shared by Flutter and the Dart-compiled Worker module.
/// All time is injected by the server; there are no timers, IO or UI here.
List<BlockPiece?> battleTray(int seed, int setIndex) {
  // Integer products stay below JS's exact integer limit. Independent of board,
  // score, timing and Random's platform-specific implementation.
  var state = (seed + (setIndex % 2147483646) * 104729) % 2147483646 + 1;
  return List.generate(3, (_) {
    state = state * 48271 % 2147483647;
    final shape = state % legacyShapeCount;
    return BlockPiece(shape, shape % 8);
  });
}

/// Stable integer RNG shared by native Dart and the compiled Worker. No hashCode
/// or platform Random implementation participates in piece generation.
class BattleRandom implements Random {
  int _state;
  BattleRandom(int seed, int index)
      : _state = (seed + (index % 2147483646) * 104729) % 2147483646 + 1;
  int _next() => _state = _state * 48271 % 2147483647;
  @override
  int nextInt(int max) => _next() % max;
  @override
  double nextDouble() => (_next() - 1) / 2147483646;
  @override
  bool nextBool() => nextInt(2) == 0;
}

/// A bounded existence check, not an automatic move or a guaranteed rescue.
/// Search includes piece order and line clears; checking fits individually is
/// insufficient because the first placement can block the remaining two.
bool battleTrayPlayable(BlockBlastEngine board, List<BlockPiece> pieces) {
  var remainingNodes = 144;
  bool search(List<List<int?>> grid, List<BlockPiece?> tray) {
    if (tray.every((p) => p == null)) return true;
    if (remainingNodes-- <= 0) return false;
    final probe = BlockBlastEngine.empty(nextTray: () => [null, null, null])
      ..grid = grid
      ..tray = tray;
    for (var slot = 0; slot < tray.length; slot++) {
      final piece = tray[slot];
      if (piece == null) continue;
      for (final (r, c) in probe.placements(piece)) {
        if (remainingNodes <= 0) return false;
        final next = BlockBlastEngine.empty(nextTray: () => [null, null, null])
          ..grid = [
            for (final row in grid) [...row]
          ]
          ..tray = [...tray];
        next.place(slot, r, c);
        if (search(next.grid, next.tray)) return true;
      }
    }
    return false;
  }

  return search(board.grid, [...pieces]);
}

/// Ortak set üreticisi: aynı üç parça bütün (oyundaki) tahtalara verilir.
///
/// Set her tahtanın kopyasında birlikte kurulur: her aday parça her tahtada
/// en iyi yerine (satır/sütun temizleyen, boşluk bırakmayan) konmaya çalışılır;
/// bir tahtaya sığmayan aday elenir. Böylece seçilen üçlünün her tahtada
/// sırayla konabildiği bir yol vardır. Tahta doldukça küçük ve satır kapatan
/// parçaların ağırlığı artar (kalabalık tahtayı kurtarma eğilimi). Oyuncunun
/// elinde kalan parçalar önce kopyaya yerleştirilir.
double flex = 6;
int candidates = 6;
double fillPenalty = 8;
List<BlockPiece?> fairBattleTray(
        int seed, int index, List<BlockBlastEngine> boards) =>
    fairBattleSet(seed, index, boards).$1;

/// [fairBattleTray] ve kurtarma: [rescue] izinliyse ve en sıkışık tahta
/// gerçekten sıkışmışsa (yarı yarıya şansla) setin ilk parçası o tahtada
/// satır temizleyen, bütün tahtalara sığan bir kurtarma parçası olur.
/// İkinci değer kurtarma verilip verilmediği.
(List<BlockPiece?>, bool) fairBattleSet(
    int seed, int index, List<BlockBlastEngine> boards,
    {bool rescue = false}) {
  final rng = BattleRandom(seed, index);
  // Canonical order makes swapping player identities irrelevant.
  final ordered = [...boards]..sort((a, b) {
      final fillA = a.grid.expand((r) => r).where((v) => v != null).length;
      final fillB = b.grid.expand((r) => r).where((v) => v != null).length;
      if (fillA != fillB) return fillB.compareTo(fillA);
      return a.grid
          .expand((r) => r)
          .map((v) => v == null ? '0' : '1')
          .join()
          .compareTo(
              b.grid.expand((r) => r).map((v) => v == null ? '0' : '1').join());
    });
  final start = [
    for (final b in ordered)
      _settle(_Scratch.of(b.grid), b.tray.whereType<BlockPiece>())
  ];
  final saver = rescue && start.isNotEmpty && start.first.tight
      ? _rescue(start, rng)
      : null;
  if (saver != null) {
    for (final s in start) {
      s.place(saver, s.best(saver)!.$1);
    }
  }
  // Birkaç aday set kurulur; konduktan sonra tahtaları en açık bırakan seçilir
  // (en kötü tahtada sığabilen parça türü sayısı, sonra doluluk).
  var pieces = <BlockPiece>[];
  var bestValue = double.negativeInfinity;
  for (var attempt = 0; attempt < candidates; attempt++) {
    final scratches = [
      for (final s in start) _Scratch(Uint8List.fromList(s.cells))
    ];
    final tray = [
      if (saver != null) BlockPiece(saver, saver % 8),
      ..._buildTray(scratches, rng, saver == null ? 3 : 2),
    ];
    // Çökmüş tahta tek hücrelik parçalarla kurtarılmaz (en çok bir tekli).
    if (tray.length < 3 || tray.where((p) => p.cells.length == 1).length > 1) {
      continue;
    }
    final open = scratches.isEmpty
        ? 0.0
        : scratches
            .map((s) => s.openShapes() - s.fill * fillPenalty)
            .reduce(min);
    if (open > bestValue) {
      bestValue = open;
      pieces = tray;
    }
  }
  // Gerçekten tıkanmış bir tahta için kurtarma yok: geçerli aday çıkmazsa
  // tek kişilik oyunun boş tahta dağılımı.
  if (pieces.isEmpty) {
    pieces =
        BlockBlastEngine(random: rng).tray.whereType<BlockPiece>().toList();
  }
  pieces.shuffle(rng);
  return (pieces, saver != null && pieces.any((p) => p.shape == saver));
}

/// En sıkışık tahtada (ilk) en çok satır temizleyen, bütün tahtalara sığan
/// parça; yarı yarıya şansla. Çapraz ikili yalnız daha çok temizliyorsa.
int? _rescue(List<_Scratch> boards, Random rng) {
  if (rng.nextDouble() >= .5) return null;
  int? pick;
  var bestValue = 0;
  for (var id = 0; id < blockShapes.length; id++) {
    final best = boards.first.best(id);
    if (best == null || best.$2 == 0) continue;
    if (boards.skip(1).any((s) => s.best(id) == null)) continue;
    final value = best.$2 * 100 +
        (rescueShapes.contains(id) ? 0 : 50) +
        blockShapes[id].length;
    if (value > bestValue) {
      bestValue = value;
      pick = id;
    }
  }
  return pick;
}

/// Tek aday set: her yuva için bütün tahtalara sığan parçalardan ağırlıklı
/// seçim; seçilen parça her kopyada en iyi yerine konur.
List<BlockPiece> _buildTray(List<_Scratch> scratches, Random rng,
    [int slots = 3]) {
  final pieces = <BlockPiece>[];
  for (var slot = 0; slot < slots; slot++) {
    final crowd =
        scratches.isEmpty ? 0.0 : scratches.map((s) => s.fill).reduce(max);
    final options = <(int, List<int>, double)>[];
    for (final id in regularShapes) {
      final spots = <int>[];
      var clears = 0, room = 81;
      for (final s in scratches) {
        final best = s.best(id);
        if (best == null) break;
        spots.add(best.$1);
        clears += best.$2;
        room = min(room, best.$3);
      }
      if (spots.length != scratches.length) continue;
      final cells = blockShapes[id].length;
      // Üç büyük parça birden verilmez.
      if (cells >= 5 && pieces.where((p) => p.cells.length >= 5).length == 2) {
        continue;
      }
      var weight = cells == 1 ? .18 : 1.0;
      if (cells >= 5) weight *= crowd < .35 ? 1.3 : .6;
      if (crowd > .45 && cells <= 3) weight *= 1 + (crowd - .45) * 4;
      if (clears > 0) weight *= 1 + clears * (crowd > .4 ? 1.2 : .4);
      if (pieces.any((p) => p.shape == id)) weight *= .25;
      // Esneklik: yalnız birkaç yere sığan parça, en iyi yeri bulamayan
      // (hızlı oynayan) oyuncuyu kilitler.
      weight *= room / (room + flex);
      options.add((id, spots, weight));
    }
    if (options.isEmpty) break;
    var roll = rng.nextDouble() * options.fold(0.0, (sum, o) => sum + o.$3);
    var pick = options.last;
    for (final option in options) {
      roll -= option.$3;
      if (roll <= 0) {
        pick = option;
        break;
      }
    }
    pieces.add(BlockPiece(pick.$1, pick.$1 % 8));
    for (var i = 0; i < scratches.length; i++) {
      scratches[i].place(pick.$1, pick.$2[i]);
    }
  }
  return pieces;
}

/// Oyuncunun elindeki parçaları en iyi yerlerine koyar (büyükten küçüğe).
_Scratch _settle(_Scratch s, Iterable<BlockPiece> pending) {
  final order = [...pending]
    ..sort((a, b) => b.cells.length.compareTo(a.cells.length));
  for (final p in order) {
    final best = s.best(p.shape);
    if (best != null) s.place(p.shape, best.$1);
  }
  return s;
}

/// Set üretimi için hafif tahta kopyası (renk tutmaz); n×n (8 ya da 9).
class _Scratch {
  final Uint8List cells;
  final int n;
  _Scratch(this.cells) : n = sqrt(cells.length).round();
  factory _Scratch.of(List<List<int?>> grid) => _Scratch(Uint8List.fromList([
        for (final row in grid)
          for (final v in row) v == null ? 0 : 1
      ]));

  double get fill => cells.where((v) => v != 0).length / cells.length;

  /// Kurtarma gereken tahta: yarıdan fazlası dolu ve normal parça türlerinin
  /// üçte birinden azı sığıyor.
  bool get tight => fill >= .5 && openShapes() < regularShapes.length / 3;

  /// Tahtaya en az bir yerde sığan (normal) parça türü sayısı.
  int openShapes() {
    var open = 0;
    for (final id in regularShapes) {
      final shape = blockShapes[id];
      search:
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (fits(shape, r, c)) {
            open++;
            break search;
          }
        }
      }
    }
    return open;
  }

  bool fits(List<List<int>> shape, int r, int c) {
    for (final cell in shape) {
      final y = r + cell[0], x = c + cell[1];
      if (y >= n || x >= n || cells[y * n + x] != 0) return false;
    }
    return true;
  }

  /// En iyi yer (r*n+c), o yerde temizlenen satır+sütun sayısı ve parçanın
  /// sığdığı yer sayısı. Önce çok temizleyen, sonra kenara/dolu hücreye en çok
  /// değen yer; eşitlikte ilki.
  (int, int, int)? best(int shapeId) {
    final shape = blockShapes[shapeId];
    (int, int)? best;
    var bestValue = -1, count = 0;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!fits(shape, r, c)) continue;
        count++;
        for (final cell in shape) {
          cells[(r + cell[0]) * n + c + cell[1]] = 2;
        }
        var lines = 0, touch = 0;
        for (var i = 0; i < n; i++) {
          var row = true, col = true;
          for (var j = 0; j < n; j++) {
            if (cells[i * n + j] == 0) row = false;
            if (cells[j * n + i] == 0) col = false;
          }
          if (row) lines++;
          if (col) lines++;
        }
        for (final cell in shape) {
          final y = r + cell[0], x = c + cell[1];
          for (final (dy, dx) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
            final yy = y + dy, xx = x + dx;
            if (yy < 0 ||
                yy >= n ||
                xx < 0 ||
                xx >= n ||
                cells[yy * n + xx] == 1) {
              touch++;
            }
          }
        }
        for (final cell in shape) {
          cells[(r + cell[0]) * n + c + cell[1]] = 0;
        }
        final value = lines * 1000 + touch;
        if (value > bestValue) {
          bestValue = value;
          best = (r * n + c, lines);
        }
      }
    }
    return best == null ? null : (best.$1, best.$2, count);
  }

  void place(int shapeId, int at) {
    final r = at ~/ n, c = at % n;
    for (final cell in blockShapes[shapeId]) {
      cells[(r + cell[0]) * n + c + cell[1]] = 1;
    }
    final full = <int>{};
    for (var i = 0; i < n; i++) {
      if (List.generate(n, (j) => cells[i * n + j]).every((v) => v != 0)) {
        for (var j = 0; j < n; j++) {
          full.add(i * n + j);
        }
      }
      if (List.generate(n, (j) => cells[j * n + i]).every((v) => v != 0)) {
        for (var j = 0; j < n; j++) {
          full.add(j * n + i);
        }
      }
    }
    for (final k in full) {
      cells[k] = 0;
    }
  }
}

class BattlePlayer {
  final int id, seed;
  List<BlockPiece?> Function(int)? sharedTray;
  final String name;
  late BlockBlastEngine game;
  int nextSet = 0, lives = 5, boardOuts = 0, thresholds = 0, damage = 0;
  int lastMove = 0;
  bool ready = false, connected = false, rematch = false;
  int? disconnectAt;

  /// Üçlü maçta canı biten oyuncu elenir: tahtası donar, sırası [place] olur.
  bool out = false;
  int? place;

  /// 1v1 jokerleri (oyuncu başına [jokersEach]); her biri maçta bir kez.
  List<String> jokers = [];
  List<String> usedJokers = [];

  /// [kind] jokeri elinde ve kullanılmamış.
  bool has(String kind) => jokers.contains(kind) && !usedJokers.contains(kind);

  /// Dondurma jokeri: bu ana kadar parça konamaz.
  int? frozenUntil;

  /// Hamlesi kalmayan ama genişletme jokeri duran oyuncuya süre: bu ana
  /// kadar genişletmezse tahtası gider (board-out).
  int? stuckAt;

  /// Köşe seçilirken (çark açık) süre durur: [stuckLeft] kalan süre,
  /// [aimUntil] bu takılmada duraklatmanın en geç bittiği an.
  int? stuckLeft, aimUntil;

  /// Genişletme [expandUntil]'de biter; tahta [expandCorner]'dan geri 8×8.
  int? expandUntil;
  String? expandCorner;

  /// Yansıt: bu ana kadar rakibin zarar veren jokeri kendisine döner. Rakip
  /// görmez; [reflected] yansıtma gerçekleşince açığa çıkar.
  int? reflectUntil;
  bool reflected = false;

  /// Billur tuz tahtada bu ana kadar durur.
  int? saltUntil;

  /// Takılan oyuncunun tahtasının gideceği an (duraklatılmışsa üst sınır).
  int? get stuckDeadline => stuckAt ?? (stuckLeft != null ? aimUntil : null);

  bool frozen(int now) => frozenUntil != null && now < frozenUntil!;
  bool get canExpand => has('expand') && game.size == BlockBlastEngine.baseSize;

  BattlePlayer(this.id, this.name, this.seed, {bool initialize = true}) {
    if (initialize) game = BlockBlastEngine(nextTray: _nextTray);
  }
  List<BlockPiece?> _nextTray() =>
      (sharedTray ?? ((i) => battleTray(seed, i)))(nextSet++);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'game': game.toJson(),
        'nextSet': nextSet,
        'lives': lives,
        'boardOuts': boardOuts,
        'thresholds': thresholds,
        'damage': damage,
        'lastMove': lastMove,
        'ready': ready,
        'connected': connected,
        'rematch': rematch,
        'disconnectAt': disconnectAt,
        'out': out,
        'place': place,
        'jokers': jokers,
        'usedJokers': usedJokers,
        'frozenUntil': frozenUntil,
        'stuckAt': stuckAt,
        'stuckLeft': stuckLeft,
        'aimUntil': aimUntil,
        'expandUntil': expandUntil,
        'expandCorner': expandCorner,
        'reflectUntil': reflectUntil,
        'reflected': reflected,
        'saltUntil': saltUntil,
      };
  factory BattlePlayer.restore(Map<String, dynamic> data, int seed) {
    final p = BattlePlayer(data['id'], data['name'], seed, initialize: false)
      ..nextSet = data['nextSet']
      ..lives = data['lives']
      ..boardOuts = data['boardOuts']
      ..thresholds = data['thresholds']
      ..damage = data['damage']
      ..lastMove = data['lastMove']
      ..ready = data['ready']
      ..connected = data['connected']
      ..rematch = data['rematch'] ?? false
      ..disconnectAt = data['disconnectAt']
      ..out = data['out'] == true
      ..place = data['place'] as int?
      // Eski kayıt: tek joker ('joker', 'jokerUsed').
      ..jokers = [
        ...?(data['jokers'] as List?)?.cast<String>(),
        if (data['joker'] is String) data['joker'] as String
      ]
      ..usedJokers = [
        ...?(data['usedJokers'] as List?)?.cast<String>(),
        if (data['jokerUsed'] == true && data['joker'] is String)
          data['joker'] as String
      ]
      ..frozenUntil = data['frozenUntil'] as int?
      ..stuckAt = data['stuckAt'] as int?
      ..stuckLeft = data['stuckLeft'] as int?
      ..aimUntil = data['aimUntil'] as int?
      ..expandUntil = data['expandUntil'] as int?
      ..expandCorner = data['expandCorner'] as String?
      ..reflectUntil = data['reflectUntil'] as int?
      ..reflected = data['reflected'] == true
      ..saltUntil = data['saltUntil'] as int?;
    p.game = BlockBlastEngine.restore(Map<String, dynamic>.from(data['game']),
        nextTray: p._nextTray)!;
    return p;
  }
}

/// Maç türü: 'duel' iki oyuncu, 'trio' üç oyuncu (herkes herkese karşı).
const battleModes = {'duel': 2, 'trio': 3};

/// 1v1 jokerleri: dondurma (rakibin tahtası 8 sn donar), genişletme
/// (tahta seçilen köşeye doğru 15 sn 9×9 olur), yansıt (30 sn boyunca
/// rakibin zarar veren jokeri kendisine döner, gizli) ve billur tuz
/// (rakibin tahtasının ortasına 20 sn 1×3 tuzluk).
const jokerKinds = ['freeze', 'expand', 'reflect', 'salt'];

/// Rakibe zarar veren jokerler: yansıt bunları geri çevirir.
const harmfulJokers = {'freeze', 'salt'};
const freezeMs = 8000, draftMs = 20000, stuckMs = 5000, aimMaxMs = 10000;

/// Oyuncu başına joker; seçim sırası yılan: ilk, ikinci, ikinci, ilk.
const jokersEach = 2;

/// Seçim sırası: [picker] önce, sonra diğeri iki kez, son yine [picker].
List<int> draftOrder(int? picker, Iterable<int> ids) {
  final other = ids.where((id) => id != picker).firstOrNull;
  if (picker == null || other == null) return [];
  return [picker, other, other, picker].sublist(0, jokersEach * 2);
}

const expandMs = 15000, reflectMs = 30000, saltMs = 20000;

class BattleMatch {
  final String roomId;
  int seed;
  final int createdAt;
  final List<BattlePlayer> players = [];
  String mode = 'duel';

  /// Boş değilse odaya yalnız bu oyuncular girebilir (meydan okuma).
  List<int> invited = [];
  int get capacity => battleModes[mode] ?? 2;
  Iterable<BattlePlayer> get alive => players.where((p) => !p.out);
  int generatorVersion = 2;
  int round = 1;
  final Map<int, List<BlockPiece?>> _sets = {};

  /// 1v1'de maçtan önce joker seçimi: [picker] ilk seçer (yazı-tura),
  /// seçim [draftEnd]'de kapanır; seçmeyene kalanlardan rastgele verilir.
  bool jokers = false;
  int? draftEnd, picker;

  /// Son kurtarma parçasının verildiği set (kurtarmalar arası en az
  /// [BlockBlastEngine.rescueGap] set).
  int lastRescue = -100;

  List<BlockPiece?> _sharedTray(int index) {
    if (generatorVersion == 1) return battleTray(seed, index);
    final pieces = _sets.putIfAbsent(index, () {
      final (set, rescued) = fairBattleSet(
          seed, index, alive.map((p) => p.game).toList(),
          rescue: index - lastRescue >= BlockBlastEngine.rescueGap);
      if (rescued) lastRescue = index;
      return set;
    });
    // Keep only sets that a slower player can still need. A late join must
    // retain set zero, so pruning starts only with every player present.
    // Eliminated players no longer draw sets.
    if (players.length == capacity && alive.isNotEmpty) {
      final consumed = alive.map((p) => p.nextSet).reduce(min);
      _sets.removeWhere((key, _) => key < consumed);
    }
    return [...pieces]; // Each player consumes its own tray, never the cache.
  }

  String status = 'waiting';
  int revision = 0;
  int? startAt, endedAt, winner;
  String? reason;
  List<Map<String, dynamic>> events = [];

  BattleMatch(this.roomId, this.seed, this.createdAt);
  bool get finished => status == 'finished';
  BattlePlayer player(int id) => players.firstWhere((p) => p.id == id);

  void join(int id, String name, int now) {
    if (players.any((p) => p.id == id)) return;
    if (invited.isNotEmpty && !invited.contains(id)) {
      throw StateError('Bu oda başka bir oyuncu için kuruldu.');
    }
    if (status != 'waiting' || players.length >= capacity) {
      throw StateError('Oda dolu veya maç başlamış.');
    }
    final p = BattlePlayer(id, name, seed, initialize: false)
      ..sharedTray = _sharedTray;
    p.game = BlockBlastEngine.empty(nextTray: p._nextTray);
    players.add(p);
    p.game.refill();
    revision++;
  }

  void connect(int id, int now) {
    advance(now);
    final p = player(id);
    p.connected = true;
    p.disconnectAt = null;
    revision++;
    _countdown(now);
  }

  void disconnect(int id, int now) {
    advance(now);
    final p = player(id);
    p.connected = false;
    p.rematch = false;
    if (finished) {
      revision++;
      return;
    }
    if (status == 'playing' && !p.out) {
      p.disconnectAt = now + 15000;
    } else {
      p.disconnectAt = null;
    }
    if (status == 'countdown' || status == 'draft') {
      status = 'waiting';
      startAt = null;
      draftEnd = null;
      for (final p in players) {
        p.jokers = [];
      }
    }
    revision++;
  }

  void ready(int id, int now) {
    advance(now);
    if (status != 'waiting') return;
    final p = player(id);
    if (!p.connected) return;
    p.ready = true;
    revision++;
    _countdown(now);
  }

  void _countdown(int now) {
    if (status == 'waiting' &&
        players.length == capacity &&
        players.every((p) => p.ready && p.connected)) {
      if (jokers && mode == 'duel') {
        _startDraft(now);
        return;
      }
      status = 'countdown';
      startAt = now + 3000;
      revision++;
    }
  }

  /// Yazı-tura: iki oyuncu için de yarı yarıya (oda tohumu rastgeledir).
  void _startDraft(int now) {
    status = 'draft';
    startAt = null;
    draftEnd = now + draftMs;
    final order = [...players]..sort((a, b) => a.id.compareTo(b.id));
    picker = order[BattleRandom(seed, 7919 + round).nextInt(2)].id;
    for (final p in players) {
      p.jokers = [];
      p.usedJokers = [];
    }
    events.add({'type': 'DRAFT', 'picker': picker});
    revision++;
  }

  List<String> get _freeJokers => [
        for (final k in jokerKinds)
          if (!players.any((p) => p.jokers.contains(k))) k
      ];

  /// Sırası gelen oyuncu (yılan sırası: ilk, ikinci, ikinci, ilk); bitince
  /// null.
  int? get turn {
    if (status != 'draft') return null;
    final order = draftOrder(picker, players.map((p) => p.id));
    final picked = players.fold(0, (n, p) => n + p.jokers.length);
    return picked < order.length ? order[picked] : null;
  }

  void _give(int id, String kind) {
    player(id).jokers.add(kind);
    events.add({'type': 'JOKER_PICKED', 'player': id, 'joker': kind});
  }

  Map<String, dynamic> pick(int id, String kind, int now) {
    events = [];
    advance(now);
    if (status != 'draft') return {'error': 'Joker seçimi bitti.'};
    if (turn != id) return {'error': 'Seçim sırası sende değil.'};
    if (!_freeJokers.contains(kind)) return {'error': 'Bu joker alınmış.'};
    _give(id, kind);
    // Tek joker kaldıysa sıradakine o verilir.
    final next = turn;
    if (next != null && _freeJokers.length == 1) {
      _give(next, _freeJokers.single);
    }
    // Herkes seçtiyse sonuç kısa bir süre görünür, sonra geri sayım.
    if (turn == null) draftEnd = min(draftEnd!, now + 2500);
    revision++;
    return {'ok': true};
  }

  Map<String, dynamic> useJoker(int id, String kind, int now,
      {String? corner}) {
    events = [];
    advance(now);
    if (status != 'playing') return {'error': 'Maç şu anda oynanabilir değil.'};
    final p = player(id);
    if (p.out) return {'error': 'Bu maçta elendin.'};
    if (!p.has(kind)) return {'error': 'Bu joker sende yok.'};
    if (!p.connected || alive.any((p) => !p.connected)) {
      return {'error': 'Bağlantı bekleniyor.'};
    }
    if (p.frozen(now)) return {'error': 'Tahtan donuk.'};
    if (harmfulJokers.contains(kind)) {
      var target = alive.where((o) => o.id != id).firstOrNull;
      if (target == null) return {'error': 'Rakip yok.'};
      final reflected =
          target.reflectUntil != null && now < target.reflectUntil!;
      if (reflected) {
        target.reflected = true;
        target.reflectUntil = null;
        target = p;
      }
      if (kind == 'freeze') {
        target.frozenUntil = now + freezeMs;
        events.add({
          'type': 'FREEZE',
          'player': target.id,
          'by': id,
          'until': target.frozenUntil,
          if (reflected) 'reflected': true,
        });
      } else {
        target.game.placeSalt();
        target.saltUntil = now + saltMs;
        events.add({
          'type': 'SALT',
          'player': target.id,
          'by': id,
          'until': target.saltUntil,
          if (reflected) 'reflected': true,
        });
        _checkStuck(target, now);
      }
    } else if (kind == 'reflect') {
      // Gizli: olay yok, rakip durumda görmez (sunucu süzer).
      p.reflectUntil = now + reflectMs;
    } else {
      if (!p.canExpand || corner == null || !p.game.expand(corner)) {
        return {'error': 'Tahta genişletilemez.'};
      }
      p.expandUntil = now + expandMs;
      p.expandCorner = corner;
      events.add({'type': 'EXPAND', 'player': id, 'corner': corner});
      if (p.stuckDeadline != null) {
        _unstick(p);
        if (!p.game.hasMove) _boardOut(p, now);
      }
    }
    p.usedJokers.add(kind);
    revision++;
    return {'ok': true};
  }

  /// Genişletme çarkı açılınca/kapanınca: takılan oyuncunun süresi durur
  /// ya da kaldığı yerden sürer. Bir takılmada duraklatma toplam
  /// [aimMaxMs]'yi geçemez.
  Map<String, dynamic> aim(int id, bool on, int now) {
    events = [];
    advance(now);
    if (status != 'playing') return {'ok': true};
    final p = player(id);
    if (p.out || !p.canExpand) return {'ok': true};
    if (on && p.stuckAt != null) {
      p.aimUntil ??= now + aimMaxMs;
      if (now >= p.aimUntil!) return {'ok': true};
      p.stuckLeft = p.stuckAt! - now;
      p.stuckAt = null;
      revision++;
    } else if (!on && p.stuckLeft != null) {
      p.stuckAt = now + p.stuckLeft!;
      p.stuckLeft = null;
      revision++;
    }
    return {'ok': true};
  }

  /// Tahtası değişen oyuncunun hamlesi kalmadıysa: genişletme jokeri
  /// duruyorsa süre başlar, yoksa board-out.
  void _checkStuck(BattlePlayer p, int now) {
    if (finished || p.out || p.game.hasMove || p.stuckDeadline != null) return;
    if (p.canExpand) {
      p.stuckAt = now + stuckMs;
      events.add({'type': 'STUCK', 'player': p.id, 'until': p.stuckAt});
    } else {
      _boardOut(p, now);
    }
  }

  /// Süresi dolan tuz ve genişletme (sırayla, zamanında).
  void _expireEffects(int now) {
    while (!finished) {
      BattlePlayer? next;
      int? at;
      for (final p in alive) {
        for (final t in [p.saltUntil, p.expandUntil]) {
          if (t != null && t <= now && (at == null || t < at)) {
            at = t;
            next = p;
          }
        }
      }
      if (next == null) return;
      final p = next;
      if (p.saltUntil == at) {
        p.saltUntil = null;
        p.game.removeSalt();
        events.add({'type': 'SALT_GONE', 'player': p.id});
        // Tuz gidince yer açıldıysa takılma biter.
        if (p.stuckDeadline != null && p.game.hasMove) _unstick(p);
      } else {
        p.expandUntil = null;
        p.game.shrink(p.expandCorner ?? 'br');
        p.expandCorner = null;
        events.add({'type': 'SHRINK', 'player': p.id});
        _checkStuck(p, at!);
      }
      revision++;
    }
  }

  void _unstick(BattlePlayer p) {
    p.stuckAt = null;
    p.stuckLeft = null;
    p.aimUntil = null;
  }

  void advance(int now) {
    if (finished) return;
    if (status == 'playing') {
      final expired = alive
          .where((p) => p.disconnectAt != null && now >= p.disconnectAt!)
          .toList()
        ..sort((a, b) => a.disconnectAt!.compareTo(b.disconnectAt!));
      for (final p in expired) {
        _eliminate(p, 'disconnect', p.disconnectAt!);
      }
      if (finished) return;
    }
    if (status == 'waiting' && now >= createdAt + 60 * 60 * 1000) {
      status = 'finished';
      reason = 'expired';
      endedAt = now;
      revision++;
      return;
    }
    if (status == 'draft' && now >= draftEnd!) {
      // Süre doldu: seçmeyenlere kalan jokerlerden rastgele.
      final rng = BattleRandom(seed, 104729 + round);
      for (int? id = turn; id != null; id = turn) {
        final free = _freeJokers;
        _give(id, free[rng.nextInt(free.length)]);
      }
      status = 'countdown';
      startAt = draftEnd! + 3000;
      revision++;
    }
    if (status == 'countdown' && now >= startAt!) {
      status = 'playing';
      revision++;
    }
    if (status == 'playing') {
      _expireEffects(now);
      final stuck = alive
          .where((p) => p.stuckDeadline != null && now >= p.stuckDeadline!)
          .toList()
        ..sort((a, b) => a.stuckDeadline!.compareTo(b.stuckDeadline!));
      for (final p in stuck) {
        if (finished) break;
        final at = p.stuckDeadline!;
        _unstick(p);
        _boardOut(p, at);
        revision++;
      }
    }
  }

  /// Oyuncu elenir; tek kişi kalınca maç biter ve kalan kazanır. İkili
  /// maçta ilk eleme maçı bitirir.
  void _eliminate(BattlePlayer p, String why, int now) {
    if (finished || p.out) return;
    p.place = alive.length;
    p.out = true;
    p.disconnectAt = null;
    revision++;
    final left = alive.toList();
    if (left.length > 1) {
      events.add({'type': 'ELIMINATED', 'player': p.id, 'reason': why});
      return;
    }
    status = 'finished';
    endedAt = now;
    reason = why;
    winner = left.isEmpty ? null : left.single.id;
    for (final w in left) {
      w.place = 1;
    }
    events.add({'type': 'GAME_OVER', 'loser': p.id, 'reason': why});
  }

  void resign(int id, int now) {
    advance(now);
    final p = player(id);
    if (finished) return;
    // Maç başlamadan ayrılan yalnız odadan çıkar; diğerleri beklemeyi sürdürür.
    if (status == 'waiting' && players.length > 1) {
      players.remove(p);
      revision++;
      return;
    }
    _eliminate(p, 'resigned', now);
  }

  /// Monotonic per-player move identifiers survive reconnect/refresh. A replay
  /// is a no-op, and a gap cannot skip an unacknowledged move.
  Map<String, dynamic> place(
      int id, int moveId, int slot, int row, int col, int now,
      {int? round}) {
    events = [];
    advance(now);
    final p = player(id);
    if (round != null && round != this.round) {
      return {'error': 'Eski round hamlesi.'};
    }
    if (moveId <= p.lastMove && moveId > 0) return {'duplicate': true};
    if (status != 'playing') return {'error': 'Maç şu anda oynanabilir değil.'};
    if (p.out) return {'error': 'Bu maçta elendin.'};
    if (!p.connected || alive.any((p) => !p.connected)) {
      return {'error': 'Bağlantı bekleniyor.'};
    }
    if (p.frozen(now)) return {'error': 'Tahtan donuk.'};
    if (moveId != p.lastMove + 1) {
      return {'error': 'Hamle sırası güncel değil.'};
    }
    final move = p.game.place(slot, row, col);
    if (move == null) return {'error': 'Geçersiz yerleştirme.'};
    p.lastMove = moveId;
    // Her 500 puan eşiği oyundaki bütün rakiplerden birer can götürür.
    final crossed = p.game.score ~/ 500 - p.thresholds;
    p.thresholds = p.game.score ~/ 500;
    if (crossed > 0) {
      final targets = alive.where((o) => o.id != id).toList();
      for (final other in targets) {
        final dealt = crossed.clamp(0, other.lives);
        p.damage += dealt;
        other.lives -= dealt;
        events.add({'type': 'DAMAGE', 'player': other.id, 'amount': dealt});
      }
      // Aynı hamlede birden çok oyuncu düşerse puanı az olan daha geride.
      final fallen = targets.where((o) => o.lives == 0).toList()
        ..sort((a, b) => a.game.score.compareTo(b.game.score));
      for (final other in fallen) {
        _eliminate(other, 'score', now);
      }
    }
    // Genişletme jokeri duruyorsa tahta gitmeden önce kısa bir süre.
    if (!finished) _checkStuck(p, now);
    revision++;
    return {
      'ok': true,
      'move': {
        'player': id,
        'slot': slot,
        'row': row,
        'col': col,
        'lines': move.lines,
        'points': move.points,
        'allClear': move.allClear,
        'clearedCells': {
          for (final e in move.clearedCells.entries) '${e.key}': e.value
        },
      }
    };
  }

  /// Hamlesi kalmayan oyuncu bir can kaybeder; tahta 8×8 ve boş yenilenir.
  void _boardOut(BattlePlayer p, int now) {
    _unstick(p);
    p.expandUntil = null;
    p.expandCorner = null;
    p.saltUntil = null;
    p.lives--;
    p.boardOuts++;
    events.add({'type': 'BOARD_RESET', 'player': p.id, 'amount': 1});
    if (p.lives == 0) {
      _eliminate(p, 'board_out', now);
    } else {
      p.game.grid = List.generate(BlockBlastEngine.baseSize,
          (_) => List<int?>.filled(BlockBlastEngine.baseSize, null));
      p.game.combo = 0;
      p.game.misses = 0;
      p.game.comboBonus = 0;
      p.game.refill();
    }
  }

  void rematch(int id, int now, {int? newSeed}) {
    advance(now);
    if (!finished) return;
    final p = player(id);
    if (!p.connected) return;
    p.rematch = true;
    revision++;
    if (players.length == capacity &&
        players.every((p) => p.rematch && p.connected)) {
      _startRematch(newSeed, now);
    }
  }

  void _startRematch(int? newSeed, int now) {
    round++;
    seed = newSeed ?? ((seed * 48271 + now) % 2147483646 + 1);
    _sets.clear();
    lastRescue = -100;
    status = 'countdown';
    startAt = now + 3000;
    endedAt = null;
    winner = null;
    reason = null;
    events = [
      {'type': 'REMATCH_STARTED', 'round': round}
    ];
    for (final p in players) {
      p.game = BlockBlastEngine.empty(nextTray: p._nextTray);
      p.nextSet = 0;
      p.lives = 5;
      p.boardOuts = 0;
      p.thresholds = 0;
      p.damage = 0;
      p.lastMove = 0;
      p.ready = true;
      p.rematch = false;
      p.out = false;
      p.place = null;
      p.disconnectAt = null;
      p.frozenUntil = null;
      _unstick(p);
      p.expandUntil = null;
      p.expandCorner = null;
      p.reflectUntil = null;
      p.reflected = false;
      p.saltUntil = null;
      p.game.refill();
    }
    if (jokers && mode == 'duel') _startDraft(now);
    revision++;
  }

  Map<String, dynamic> toJson() => {
        'version': generatorVersion,
        'damageStep': 500,
        'round': round,
        if (generatorVersion == 2)
          'sets': {
            for (final e in _sets.entries)
              '${e.key}': [
                for (final p in e.value) p == null ? null : [p.shape, p.color]
              ]
          },
        'roomId': roomId,
        'mode': mode,
        'invited': invited,
        'jokers': jokers,
        'draftEnd': draftEnd,
        'picker': picker,
        'lastRescue': lastRescue,
        'seed': seed,
        'createdAt': createdAt,
        'status': status,
        'revision': revision,
        'startAt': startAt,
        'endedAt': endedAt,
        'winner': winner,
        'reason': reason,
        'players': players.map((p) => p.toJson()).toList(),
      };
  factory BattleMatch.restore(Map<String, dynamic> data) {
    if (data['version'] != 1 && data['version'] != 2) {
      throw const FormatException('Battle version');
    }
    final m = BattleMatch(data['roomId'], data['seed'], data['createdAt'])
      ..generatorVersion = data['version']
      ..mode = battleModes.containsKey(data['mode']) ? data['mode'] : 'duel'
      ..invited = [for (final id in data['invited'] as List? ?? []) id as int]
      ..round = data['round'] ?? 1
      ..jokers = data['jokers'] == true
      ..draftEnd = data['draftEnd'] as int?
      ..picker = data['picker'] as int?
      ..lastRescue = data['lastRescue'] as int? ?? -100
      ..status = data['status']
      ..revision = data['revision']
      ..startAt = data['startAt']
      ..endedAt = data['endedAt']
      ..winner = data['winner']
      ..reason = data['reason'];
    for (final e in (data['sets'] as Map? ?? {}).entries) {
      m._sets[int.parse(e.key)] = [
        for (final p in e.value) p == null ? null : BlockPiece(p[0], p[1])
      ];
    }
    for (final p in data['players']) {
      final restored =
          BattlePlayer.restore(Map<String, dynamic>.from(p), m.seed)
            ..sharedTray = m._sharedTray;
      // Old snapshots used 1000 or 600-point thresholds. Rebase without retroactive
      // damage; only future crossings of the new cumulative threshold apply.
      if (data['damageStep'] != 500) {
        restored.thresholds = restored.game.score ~/ 500;
      }
      m.players.add(restored);
    }
    return m;
  }
}
