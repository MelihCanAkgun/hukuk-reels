import 'dart:convert';
import '../../lib/features/game/block_battle_core.dart';

void main() {
  final m = BattleMatch('ABC234', 987654321, 0);
  final steps = <Map<String, dynamic>>[];
  void record(Map<String, dynamic> command) {
    steps.add({'command': command, 'state': m.toJson()});
    // Snapshots must not retain references to subsequently mutated boards.
    steps[steps.length - 1] = jsonDecode(jsonEncode(steps.last));
  }

  for (final id in [1, 2]) {
    m.join(id, 'P$id', 0);
    record({'action': 'join', 'id': id, 'name': 'P$id', 'now': 0});
    m.connect(id, 0);
    record({'action': 'connect', 'id': id, 'now': 0});
    m.ready(id, 0);
    record({'action': 'ready', 'id': id, 'now': 0});
  }
  m.advance(3000);
  record({'action': 'advance', 'now': 3000});
  for (var i = 0; i < 200 && !m.finished; i++) {
    final id = i % 2 + 1, p = m.player(id);
    final slot = p.game.tray.indexWhere((v) => v != null && p.game.canPlace(v));
    final (r, c) = p.game.placements(p.game.tray[slot]!).last;
    final command = {
      'action': 'place',
      'id': id,
      'moveId': p.lastMove + 1,
      'slot': slot,
      'row': r,
      'col': c,
      'now': 3001 + i
    };
    m.place(id, p.lastMove + 1, slot, r, c, 3001 + i);
    record(command);
  }
  print(jsonEncode(steps));
}
