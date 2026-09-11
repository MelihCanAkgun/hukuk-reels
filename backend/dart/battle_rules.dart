import 'dart:convert';
import 'dart:js_interop';
import 'package:hukuk_reels/features/game/block_battle_core.dart';

@JS('globalThis.blockBattleRules')
external set _rules(JSFunction fn);

void main() {
  _rules = ((JSString input) {
    try {
      final data = jsonDecode(input.toDart) as Map<String, dynamic>;
      final m = data['state'] == null
          ? BattleMatch(data['roomId'], data['seed'], data['now'])
          : BattleMatch.restore(Map<String, dynamic>.from(data['state']));
      final now = data['now'] as int;
      Map<String, dynamic>? result;
      switch (data['action']) {
        case 'join':
          m.join(data['id'], data['name'], now);
        case 'connect':
          m.connect(data['id'], now);
        case 'disconnect':
          m.disconnect(data['id'], now);
        case 'ready':
          m.ready(data['id'], now);
        case 'advance':
          m.advance(now);
        case 'resign':
          m.resign(data['id'], now);
        case 'place':
          result = m.place(data['id'], data['moveId'], data['slot'],
              data['row'], data['col'], now);
      }
      return jsonEncode({'state': m.toJson(), 'events': m.events, ...?result})
          .toJS;
    } catch (_) {
      return jsonEncode({'error': 'Geçersiz maç isteği.'}).toJS;
    }
  }).toJS;
}
