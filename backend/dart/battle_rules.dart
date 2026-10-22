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
          ? (BattleMatch(data['roomId'], data['seed'], data['now'])
            ..mode =
                battleModes.containsKey(data['mode']) ? data['mode'] : 'duel'
            ..invited = [
              for (final id in data['invited'] as List? ?? []) id as int
            ]
            // Jokerler yalnız 1v1'de; odayı kuran sunucu açar.
            ..jokers = data['jokers'] == true && data['mode'] != 'trio')
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
        case 'rematch':
          m.rematch(data['id'], now, newSeed: data['seed'] as int?);
        case 'pick':
          result = m.pick(data['id'], data['joker'] as String, now);
        case 'joker':
          result = m.useJoker(data['id'], data['joker'] as String, now,
              corner: data['corner'] as String?);
        case 'aim':
          result = m.aim(data['id'], data['on'] == true, now);
        case 'place':
          result = m.place(data['id'], data['moveId'], data['slot'],
              data['row'], data['col'], now,
              round: data['round'] as int?);
      }
      return jsonEncode({'state': m.toJson(), 'events': m.events, ...?result})
          .toJS;
    } on StateError catch (error) {
      return jsonEncode({'error': error.message}).toJS;
    } catch (_) {
      return jsonEncode({'error': 'Geçersiz maç isteği.'}).toJS;
    }
  }).toJS;
}
