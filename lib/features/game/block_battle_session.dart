import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/services/battle_bridge.dart';
import 'block_battle_core.dart';
import 'block_blast_engine.dart';

typedef BattleCall = Future<Map<String, dynamic>> Function(
    String, Map<String, dynamic>);

class BlockBattleSession extends ChangeNotifier {
  final BattleCall call;
  Map<String, dynamic>? state;
  int? me;
  bool connected = false, pending = false;
  String? error;
  int _offset = 0;
  bool _disposed = false;
  List<dynamic> events = [];
  BlockBattleSession({BattleCall? transport, bool listen = true})
      : call = transport ?? ((action, data) => battleCall(action, data)) {
    if (listen) {
      listenBattle(receive);
      _listening = this;
    }
  }

  /// Köprüyü dinleyen son oturum. Eski ekran geç kapanınca (ör. davetle
  /// açılan yeni lobi) yeni oturumun bağlantısını koparmaz.
  static BlockBattleSession? _listening;
  int get now => DateTime.now().millisecondsSinceEpoch + _offset;
  String get status => state?['status'] ?? 'waiting';
  String? get room => state?['roomId'];
  int get round => state?['round'] as int? ?? 1;
  List<Map<String, dynamic>> get players =>
      (state?['players'] as List? ?? []).cast<Map<String, dynamic>>();
  Map<String, dynamic>? get mine =>
      players.where((p) => p['id'] == me).firstOrNull;

  /// 'duel' (1v1) ya da 'trio' (üç oyuncu, herkes herkese karşı).
  String get mode => state?['mode'] == 'trio' ? 'trio' : 'duel';
  bool get trio => mode == 'trio';
  int get capacity => trio ? 3 : 2;
  List<Map<String, dynamic>> get opponents =>
      players.where((p) => p['id'] != me).toList();
  Map<String, dynamic>? get opponent => opponents.firstOrNull;
  bool get eliminated => mine?['out'] == true;

  /// Oyuncunun tahtası dondurma jokeriyle donmuş mu (sunucu saatine göre).
  bool frozen(Map<String, dynamic>? p) =>
      p != null && (p['frozenUntil'] as int? ?? 0) > now;
  bool get stuck => mine?['stuckAt'] != null || mine?['stuckLeft'] != null;

  /// Takılınca kalan süre (ms); köşe seçilirken durur.
  int get stuckLeft =>
      mine?['stuckLeft'] as int? ??
      max(0, (mine?['stuckAt'] as int? ?? now) - now);

  /// 1v1 joker seçimi: sırası gelen oyuncu (yoksa null).
  int? get turn {
    if (status != 'draft') return null;
    final order = draftOrder(
        state?['picker'] as int?, players.map((p) => p['id'] as int));
    final picked = players.fold(0, (n, p) => n + jokersOf(p).length);
    return picked < order.length ? order[picked] : null;
  }

  List<String> jokersOf(Map<String, dynamic>? p) =>
      [...?(p?['jokers'] as List?)?.cast<String>()];
  bool jokerUsed(Map<String, dynamic>? p, String kind) =>
      (p?['usedJokers'] as List?)?.contains(kind) == true;
  List<String> get myJokers => jokersOf(mine);

  /// [kind] jokeri şimdi kullanılabilir mi.
  bool jokerReady(String kind) =>
      myJokers.contains(kind) &&
      !jokerUsed(mine, kind) &&
      status == 'playing' &&
      connected &&
      !pending &&
      !eliminated &&
      !frozen(mine) &&
      (kind != 'expand' || (mine!['game']['grid'] as List).length == 8);

  Future<bool> pickJoker(String joker) => action('pick', {'joker': joker});
  Future<bool> useJoker(String joker, {String? corner}) =>
      action('joker', {'joker': joker, if (corner != null) 'corner': corner});

  /// Süre duraklatılmışken köşe seçmek için kalan süre (ms), yoksa null.
  int? get aimLeft {
    final until = mine?['aimUntil'] as int?;
    if (mine?['stuckLeft'] == null || until == null) return null;
    return max(0, until - now);
  }

  /// Kendi süreli etkinin ([key]: 'reflectUntil', 'expandUntil' …) kalan
  /// süresi (ms); bitmişse null.
  int? effectLeft(String key, [Map<String, dynamic>? p]) {
    final until = (p ?? mine)?[key] as int?;
    return until == null || until <= now ? null : until - now;
  }

  /// Genişletme çarkı açık/kapalı: takılıyken sunucu süreyi durdurur.
  Future<bool> aimJoker(bool on) => action('aim', {'on': on});

  bool get canPlay =>
      connected &&
      !pending &&
      status == 'playing' &&
      !eliminated &&
      !frozen(mine) &&
      !stuck &&
      players.length == capacity &&
      players.every((p) => p['out'] == true || p['connected'] == true);
  bool get rematchRequested => mine?['rematch'] == true;
  bool get opponentRematchRequested =>
      opponents.any((p) => p['rematch'] == true);

  void receive(Map<String, dynamic> frame) {
    if (_disposed) return;
    if (frame['me'] is int) me = frame['me'];
    if (frame['type'] == 'LEFT') state = null;
    if (frame['state'] is Map) {
      final next = Map<String, dynamic>.from(frame['state']);
      if (state == null ||
          next['roomId'] != state!['roomId'] ||
          next['revision'] >= state!['revision']) {
        state = next;
      }
    }
    if (frame['serverNow'] is int) {
      _offset = frame['serverNow'] - DateTime.now().millisecondsSinceEpoch;
    }
    if (frame['connected'] is bool) connected = frame['connected'];
    if (frame['pending'] is bool) pending = frame['pending'];
    error = frame['error'] as String?;
    events = frame['events'] as List? ?? [];
    notifyListeners();
  }

  BlockBlastEngine? engine() {
    if (mine == null) return null;
    var nextSet = mine!['nextSet'] as int;
    final seed = state!['seed'] as int;
    return BlockBlastEngine.restore(Map<String, dynamic>.from(mine!['game']),
        // Shared board-aware sets are selected only by the authoritative server.
        // Keep the tray empty during the existing pending-ack interval.
        nextTray: () => state?['version'] == 2
            ? <BlockPiece?>[null, null, null]
            : battleTray(seed, nextSet++));
  }

  Future<bool> action(String action,
      [Map<String, dynamic> data = const {}]) async {
    final result = await call(action, data);
    if (_disposed) return false;
    if (action == 'leave' && result['error'] == null) state = null;
    receive(result);
    return result['error'] == null;
  }

  Future<bool> requestRematch() => action('rematch');

  void place(int slot, int row, int col) {
    if (!canPlay) return;
    pending = true;
    // Only a completed placement crosses the bridge. The screen may predict its
    // visual impact but every persistent score/HP/board comes back from server.
    unawaited(
        action('place', {'slot': slot, 'row': row, 'col': col, 'round': round})
            .then((ok) {
      if (!ok && !_disposed) {
        pending = false;
        notifyListeners();
      }
    }));
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listening == this) {
      _listening = null;
      unawaited(call('detach', {}));
    } else if (_listening == null) {
      unawaited(call('detach', {}));
    }
    super.dispose();
  }
}
