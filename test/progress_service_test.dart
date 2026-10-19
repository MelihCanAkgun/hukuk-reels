import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';

void main() {
  test('session writes stay ordered and clearing is visible immediately',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = ProgressService.instance;
    await service.init();
    final a = service.saveBlockGame({'score': 10});
    final b = service.saveBlockGame({'score': 20});
    await Future.wait([a, b]);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('block_game_v2')!), {'score': 20});
    final clearing = service.clearBlockGame();
    expect(service.loadBlockGame(), isNull);
    final next = service.saveBlockGame({'score': 0});
    await Future.wait([clearing, next]);
    expect(jsonDecode(prefs.getString('block_game_v2')!), {'score': 0});
    await Future.wait(
        [service.submitBlockScore(100), service.submitBlockScore(50)]);
    expect(service.blockHigh, 100);
    await service.resetAll();
    expect(service.loadBlockGame(), isNull);
    expect(service.blockHigh, 0);
  });

  test('question stats are cached, copied on read and persisted on write',
      () async {
    final service = ProgressService.instance;
    final prefs = await SharedPreferences.getInstance();
    await service.resetAll();
    expect(service.unsolvedCount, greaterThan(0));
    final total = service.unsolvedCount;
    await service.recordAnswer('q1', true);
    await service.recordAnswer('q1', false);
    await service.recordAnswer('q2', false);
    expect(service.stats['q1']!.correct, 1);
    expect(service.stats['q1']!.wrong, 1);
    // Returned collections are copies: mutating them must not leak.
    service.stats.remove('q1');
    service.solvedIds.clear();
    expect(service.stats.containsKey('q1'), isTrue);
    expect(service.solvedIds, containsAll(['q1', 'q2']));
    final raw = jsonDecode(prefs.getString('stats_v1')!) as Map;
    expect(raw['q1'], {'c': 1, 'w': 1});
    expect(prefs.getStringList('solved_v1'), containsAll(['q1', 'q2']));
    expect(service.unsolvedCount, total); // q1/q2 are not real pool ids
    await service.resetPool();
    expect(service.solvedIds, isEmpty);
    expect(service.stats['q2']!.wrong, 1);
    await service.resetAll();
    expect(service.stats, isEmpty);
    expect(prefs.getString('stats_v1'), isNull);
  });
}
