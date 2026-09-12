import 'dart:math';
import 'block_blast_engine.dart';

/// Battle rules shared by Flutter and the Dart-compiled Worker module.
/// All time is injected by the server; there are no timers, IO or UI here.
List<BlockPiece?> battleTray(int seed, int setIndex) {
  // Integer products stay below JS's exact integer limit. Independent of board,
  // score, timing and Random's platform-specific implementation.
  var state = (seed + (setIndex % 2147483646) * 104729) % 2147483646 + 1;
  return List.generate(3, (_) {
    state = state * 48271 % 2147483647;
    final shape = state % blockShapes.length;
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

/// Bounded shared fairness, not per-player rescue. Candidates reuse solo's
/// constructive placement, line clearing and weights on copies of both boards.
/// The selected set is committed once per index by BattleMatch below.
List<BlockPiece?> fairBattleTray(
    int seed, int index, List<BlockBlastEngine> boards) {
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
  final score = ordered.isEmpty
      ? 0
      : ordered.fold<int>(0, (sum, b) => sum + b.score) ~/ ordered.length;
  List<BlockPiece?>? best;
  var bestQuality = -10000;
  for (var attempt = 0; attempt < 16; attempt++) {
    final source =
        ordered.isEmpty ? null : ordered[(attempt ~/ 2) % ordered.length];
    final scratch = BlockBlastEngine.empty(random: rng)..score = score;
    if (source != null) {
      scratch.grid = [
        for (final row in source.grid) [...row]
      ];
    }
    scratch.refill();
    final pieces = scratch.tray.whereType<BlockPiece>().toList();
    // Never solve a ruined board by handing out a tray of single-cell rescues.
    if (pieces.length != 3 ||
        pieces.where((p) => p.cells.length == 1).length > 1) {
      continue;
    }
    final large = pieces.where((p) => p.cells.length >= 5).length;
    final playable = ordered.where((b) => pieces.any(b.canPlace)).length;
    final solvable = ordered
        .where((b) => battleTrayPlayable(
            b, [...b.tray.whereType<BlockPiece>(), ...pieces]))
        .length;
    final choices = ordered.isEmpty
        ? 3
        : ordered.map((b) => pieces.where(b.canPlace).length).reduce(min);
    final flexibility = ordered.isEmpty
        ? 3
        : ordered
            .expand((b) => pieces.map((p) => min(b.placements(p).length, 3)))
            .reduce(min);
    final quality = playable * 100 +
        solvable * 30 +
        min(choices, 2) * 8 +
        flexibility * 4 -
        (large == 3 ? 20 : 0);
    if (quality > bestQuality) {
      best = [...pieces];
      bestQuality = quality;
    }
    if (solvable == ordered.length &&
        choices >= 2 &&
        flexibility >= 2 &&
        large < 3) {
      return [...pieces];
    }
  }
  if (best != null) return best;
  // No valid constructive candidate: use solo's empty-board distribution.
  // It deliberately provides no guarantee for a genuinely blocked board.
  return BlockBlastEngine(random: rng).tray;
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
      ..disconnectAt = data['disconnectAt'];
    p.game = BlockBlastEngine.restore(Map<String, dynamic>.from(data['game']),
        nextTray: p._nextTray)!;
    return p;
  }
}

class BattleMatch {
  final String roomId;
  int seed;
  final int createdAt;
  final List<BattlePlayer> players = [];
  int generatorVersion = 2;
  int round = 1;
  final Map<int, List<BlockPiece?>> _sets = {};

  List<BlockPiece?> _sharedTray(int index) {
    if (generatorVersion == 1) return battleTray(seed, index);
    final pieces = _sets.putIfAbsent(index,
        () => fairBattleTray(seed, index, players.map((p) => p.game).toList()));
    // Keep only sets that a slower player can still need. A late second join
    // must retain set zero, so pruning starts only with both players present.
    if (players.length == 2) {
      final consumed = players.map((p) => p.nextSet).reduce(min);
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
    if (status != 'waiting' || players.length >= 2) {
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
    p.disconnectAt = now + 15000;
    if (status == 'countdown') {
      status = 'waiting';
      startAt = null;
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
        players.length == 2 &&
        players.every((p) => p.ready && p.connected)) {
      status = 'countdown';
      startAt = now + 3000;
      revision++;
    }
  }

  void advance(int now) {
    if (finished) return;
    final expired = players
        .where((p) => p.disconnectAt != null && now >= p.disconnectAt!)
        .toList()
      ..sort((a, b) => a.disconnectAt!.compareTo(b.disconnectAt!));
    if (expired.isNotEmpty) {
      _end(expired.first.id, 'disconnect', expired.first.disconnectAt!);
      return;
    }
    if (status == 'waiting' && now >= createdAt + 60 * 60 * 1000) {
      status = 'finished';
      reason = 'expired';
      endedAt = now;
      revision++;
      return;
    }
    if (status == 'countdown' && now >= startAt!) {
      status = 'playing';
      revision++;
    }
  }

  void _end(int loser, String why, int now) {
    if (finished) return;
    status = 'finished';
    endedAt = now;
    reason = why;
    final others = players.where((p) => p.id != loser);
    winner = others.isEmpty ? null : others.first.id;
    events.add({'type': 'GAME_OVER', 'loser': loser, 'reason': why});
    revision++;
  }

  void resign(int id, int now) {
    advance(now);
    player(id);
    if (!finished) _end(id, 'resigned', now);
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
    if (!p.connected || players.any((p) => !p.connected)) {
      return {'error': 'Bağlantı bekleniyor.'};
    }
    if (moveId != p.lastMove + 1) {
      return {'error': 'Hamle sırası güncel değil.'};
    }
    final move = p.game.place(slot, row, col);
    if (move == null) return {'error': 'Geçersiz yerleştirme.'};
    p.lastMove = moveId;
    final other = players.firstWhere((p) => p.id != id);
    final crossed = p.game.score ~/ 500 - p.thresholds;
    p.thresholds = p.game.score ~/ 500;
    if (crossed > 0) {
      final dealt = crossed.clamp(0, other.lives);
      p.damage += dealt;
      other.lives -= dealt;
      events.add({'type': 'DAMAGE', 'player': other.id, 'amount': dealt});
      if (other.lives == 0) _end(other.id, 'score', now);
    }
    if (!finished && !p.game.hasMove) {
      p.lives--;
      p.boardOuts++;
      events.add({'type': 'BOARD_RESET', 'player': id, 'amount': 1});
      if (p.lives == 0) {
        _end(id, 'board_out', now);
      } else {
        p.game.grid = List.generate(8, (_) => List<int?>.filled(8, null));
        p.game.combo = 0;
        p.game.misses = 0;
        p.game.refill();
      }
    }
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

  void rematch(int id, int now, {int? newSeed}) {
    advance(now);
    if (!finished) return;
    final p = player(id);
    if (!p.connected) return;
    p.rematch = true;
    revision++;
    if (players.length == 2 && players.every((p) => p.rematch && p.connected)) {
      _startRematch(newSeed, now);
    }
  }

  void _startRematch(int? newSeed, int now) {
    round++;
    seed = newSeed ?? ((seed * 48271 + now) % 2147483646 + 1);
    _sets.clear();
    status = 'countdown';
    startAt = now + 3000;
    endedAt = null;
    winner = null;
    reason = null;
    events = [{'type': 'REMATCH_STARTED', 'round': round}];
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
      p.game.refill();
    }
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
      ..round = data['round'] ?? 1
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
