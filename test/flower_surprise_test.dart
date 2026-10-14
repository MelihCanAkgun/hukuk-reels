import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/main.dart';
import 'package:hukuk_reels/core/config/app_config.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/intro/confidence_gate_screen.dart';
import 'package:hukuk_reels/features/surprise/bouquet_sprite.dart';
import 'package:hukuk_reels/features/surprise/flower_surprise_screen.dart';
import 'package:hukuk_reels/features/surprise/pixel_font.dart';

Future<void> _play(WidgetTester tester, double seconds) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  test('message, glyphs, song and sprite data are consistent', () {
    expect(kFlowerMessageLines.join(' '), kFlowerMessage);
    expect(kFlowerMessage, 'Seni Seviyorum Ve Seni Çok Özledim Güzel Sevgilim');
    for (final ch in '$kFlowerMessage♥'.split('')) {
      expect(kPixelGlyphs.containsKey(ch), isTrue, reason: 'glyph "$ch"');
    }
    for (final g in kPixelGlyphs.values) {
      expect(g.length, kGlyphRows);
      expect(g.every((r) => r.length == g.first.length), isTrue);
    }
    expect(AppConfig.musicTracks, contains(kFlowerSong));
    expect(kBouquetLayers.length, greaterThan(20));
    for (final l in kBouquetLayers) {
      expect(l.left >= 0 && l.top >= 0, isTrue);
      expect(l.top + l.rows.length <= kBouquetH, isTrue);
      for (final row in l.rows) {
        expect(row.length, l.rows.first.length);
        expect(l.left + row.length <= kBouquetW, isTrue);
        for (final ch in row.split('')) {
          expect(ch == '.' || kBouquetPalette.containsKey(ch), isTrue);
        }
      }
    }
  });

  for (final size in const [Size(393, 852), Size(375, 667), Size(320, 568)]) {
    testWidgets('flower plays through on $size and reacts to taps',
        (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = size * 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: FlowerSurpriseScreen()));
      await _play(tester, 6);
      await tester.tapAt(Offset(size.width / 2, size.height * 0.3));
      await _play(tester, 7.5);
      await tester.tapAt(Offset(size.width / 2, size.height * 0.3));
      await tester.tapAt(const Offset(30, 300));
      await _play(tester, 2);
      expect(find.text('bukete dokun 💗'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Kapat'));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('first launch after update shows the surprise once',
      (tester) async {
    await ProgressService.instance.setFlowerSurpriseSeen(false);
    await tester.pumpWidget(const HukukReelsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(ConfidenceGateScreen), findsOneWidget);
    expect(find.textContaining('Sana bir sürprizim var'), findsOneWidget);
    expect(ProgressService.instance.flowerSurpriseSeen, isFalse);

    await tester.tap(find.text('Evet 🥰'));
    await _play(tester, 1);
    expect(find.byType(FlowerSurpriseScreen), findsOneWidget);
    expect(ProgressService.instance.flowerSurpriseSeen, isTrue);

    await tester.tap(find.byTooltip('Kapat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(FlowerSurpriseScreen), findsNothing);
    expect(find.text('Block Blast'), findsOneWidget);

    // 🌷 düğmesiyle çiçek yeniden açılır.
    await tester.tap(find.text('🌷'));
    await _play(tester, 1);
    expect(find.byType(FlowerSurpriseScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
