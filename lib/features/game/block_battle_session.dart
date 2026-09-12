import 'dart:async';
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
    if (listen) listenBattle(receive);
  }
  int get now => DateTime.now().millisecondsSinceEpoch + _offset;
  String get status => state?['status'] ?? 'waiting';
  String? get room => state?['roomId'];
  int get round => state?['round'] as int? ?? 1;
  List<Map<String, dynamic>> get players =>
      (state?['players'] as List? ?? []).cast<Map<String, dynamic>>();
  Map<String, dynamic>? get mine =>
      players.where((p) => p['id'] == me).firstOrNull;
  Map<String, dynamic>? get opponent =>
      players.where((p) => p['id'] != me).firstOrNull;
  bool get canPlay =>
      connected &&
      !pending &&
      status == 'playing' &&
      players.length == 2 &&
      players.every((p) => p['connected'] == true);
  bool get rematchRequested => mine?['rematch'] == true;
  bool get opponentRematchRequested => opponent?['rematch'] == true;

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
        action('place', {'slot': slot, 'row': row, 'col': col, 'round': round}).then((ok) {
      if (!ok && !_disposed) {
        pending = false;
        notifyListeners();
      }
    }));
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(call('detach', {}));
    super.dispose();
  }
}
