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
    expect(jsonDecode(prefs.getString('block_game_v1')!), {'score': 20});
    final clearing = service.clearBlockGame();
    expect(service.loadBlockGame(), isNull);
    final next = service.saveBlockGame({'score': 0});
    await Future.wait([clearing, next]);
    expect(jsonDecode(prefs.getString('block_game_v1')!), {'score': 0});
    await Future.wait(
        [service.submitBlockScore(100), service.submitBlockScore(50)]);
    expect(service.blockHigh, 100);
    await service.resetAll();
    expect(service.loadBlockGame(), isNull);
    expect(service.blockHigh, 0);
  });
}
