import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/core/data/questions_data.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/beat/beat_mode_screen.dart';
import 'package:hukuk_reels/features/reels/screens/reels_maintenance_screen.dart';
import 'package:hukuk_reels/features/reels/screens/reels_screen.dart';
import 'package:hukuk_reels/features/surprise/pixel_font.dart';
import 'package:hukuk_reels/features/surprise/pixel_sprites.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
  });

  test('pixel font and sprites cover every text they draw', () {
    for (final text in [
      ReelsMaintenanceScreen.title,
      ...ReelsMaintenanceScreen.lines,
      'BONK!',
      'K.O.!',
    ]) {
      for (final ch in text.split('')) {
        expect(kPixelGlyphs.containsKey(ch), isTrue, reason: '"$ch" in $text');
      }
    }
    for (final g in kPixelGlyphs.values) {
      expect(g.length, kGlyphRows);
      expect(g.every((r) => r.length == g.first.length), isTrue);
    }
    for (final sprite in [kBatSprite, kBurstSprite, kLoveFaceSprite]) {
      for (final row in sprite) {
        expect(row.length, sprite.first.length);
        for (final ch in row.split('')) {
          expect(ch == '.' || kSpritePalette.containsKey(ch), isTrue);
        }
      }
    }
  });

  for (final size in const [Size(393, 852), Size(320, 568)]) {
    testWidgets('reels show the maintenance screen on $size and save nothing',
        (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = size * 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ReelsScreen.maintenance = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_v1');
      await tester.pumpWidget(const MaterialApp(home: ReelsScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ReelsMaintenanceScreen), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Bakımda')), findsOneWidget);
      expect(prefs.getString('session_v1'), isNull,
          reason: 'maintenance must not start a test');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('beat mode: 10 hits defeat the question, early pick resists',
      (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(393, 852) * 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: BeatModeScreen(questions: kQuestions.take(2).toList())));
    await tester.pump();

    // Pes etmeden şık seçmek: direnç balonu.
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.textContaining('kez döv'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));

    // Soru metninin üstüne 10 vuruş (her biri animasyonla).
    for (var i = 0; i < 10; i++) {
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 450));
    }
    expect(find.textContaining('İstediğin şıkkı'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1. soru sizden özür dilemek istiyor'), findsOneWidget);
    await tester.tap(find.text('Kabul et'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Yüce Hukuk Profesörü'), findsOneWidget);

    // Artık seçilen şık doğru sayılır.
    await tester.tap(find.text('B'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Senin dediğin doğru'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
