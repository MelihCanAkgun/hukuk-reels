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

class BattlePlayer {
  final int id, seed;
  final String name;
  late BlockBlastEngine game;
  int nextSet = 0, lives = 5, boardOuts = 0, thresholds = 0, damage = 0;
  int lastMove = 0;
  bool ready = false, connected = false;
  int? disconnectAt;

  BattlePlayer(this.id, this.name, this.seed, {bool initialize = true}) {
    if (initialize) game = BlockBlastEngine(nextTray: _nextTray);
  }
  List<BlockPiece?> _nextTray() => battleTray(seed, nextSet++);

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
      ..disconnectAt = data['disconnectAt'];
    p.game = BlockBlastEngine.restore(Map<String, dynamic>.from(data['game']),
        nextTray: p._nextTray)!;
    return p;
  }
}

class BattleMatch {
  final String roomId;
  final int seed, createdAt;
  final List<BattlePlayer> players = [];
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
    players.add(BattlePlayer(id, name, seed));
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
    if (finished) return;
    final p = player(id);
    if (!p.connected) return;
    p.connected = false;
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
    if (now >= createdAt + 60 * 60 * 1000) {
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
      int id, int moveId, int slot, int row, int col, int now) {
    events = [];
    advance(now);
    final p = player(id);
    if (moveId <= p.lastMove && moveId > 0) return {'duplicate': true};
    if (status != 'playing') return {'error': 'Maç şu anda oynanabilir değil.'};
    if (!p.connected || players.any((p) => !p.connected)) {
      return {'error': 'Bağlantı bekleniyor.'};
    }
    if (moveId != p.lastMove + 1)
      return {'error': 'Hamle sırası güncel değil.'};
    final move = p.game.place(slot, row, col);
    if (move == null) return {'error': 'Geçersiz yerleştirme.'};
    p.lastMove = moveId;
    final other = players.firstWhere((p) => p.id != id);
    final crossed = p.game.score ~/ 1000 - p.thresholds;
    p.thresholds = p.game.score ~/ 1000;
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

  Map<String, dynamic> toJson() => {
        'version': 1,
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
    if (data['version'] != 1) throw const FormatException('Battle version');
    final m = BattleMatch(data['roomId'], data['seed'], data['createdAt'])
      ..status = data['status']
      ..revision = data['revision']
      ..startAt = data['startAt']
      ..endedAt = data['endedAt']
      ..winner = data['winner']
      ..reason = data['reason'];
    for (final p in data['players']) {
      m.players.add(BattlePlayer.restore(Map<String, dynamic>.from(p), m.seed));
    }
    return m;
  }
}
