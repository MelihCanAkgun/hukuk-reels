import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/profile/avatar_editor_screen.dart';

// 1×1 PNG önizleme.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

Future<Map<String, dynamic>?> _edit(
    WidgetTester tester, Future<void> Function() actions,
    {bool admin = false}) async {
  Map<String, dynamic>? result;
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(
                  builder: (_) => AvatarEditorScreen(
                      preview: _png,
                      srcWidth: 4032,
                      srcHeight: 3024,
                      admin: admin)));
        },
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await actions();
  await tester.tap(find.text('Kaydet'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('default spec is a centred cover crop at native resolution',
      (tester) async {
    final spec = await _edit(tester, () async {});
    expect(spec, isNotNull);
    expect(spec!['out'], 3024);
    final img = spec['img'] as Map<String, dynamic>;
    expect(img['w'], closeTo(4032 / 3024, 1e-9));
    expect(img['h'], 1.0);
    expect(img['x'], closeTo(-(4032 / 3024 - 1) / 2, 1e-9));
    expect(img['y'], 0.0);
    expect(spec['stickers'], isEmpty);
  });

  testWidgets('stickers land in free corners and can be resized or deleted',
      (tester) async {
    final spec = await _edit(tester, () async {
      await tester.tap(find.text('Sevimli'));
      await tester.pump();
      final tray = find.bySemanticsLabel('Çıkartma ekle');
      await tester.tap(tray.at(0));
      await tester.pump();
      await tester.tap(tray.at(1));
      await tester.pump();
      // Seçili (ikinci) çıkartmayı kaydırıcıyla büyüt, sonra ilkini sil.
      await tester.drag(find.byType(Slider).first, const Offset(120, 0));
      await tester.pump();
      await tester.tap(tray.at(2));
      await tester.pump();
      await tester.tap(find.byTooltip('Çıkartmayı sil'));
      await tester.pump();
    });
    final stickers = (spec!['stickers'] as List).cast<Map<String, dynamic>>();
    expect(stickers, hasLength(2));
    // İlki sol üst köşede, ikincisi sağ üstte ve büyütülmüş.
    expect(stickers[0]['x'] + stickers[0]['size'] / 2, closeTo(0.15, 1e-9));
    expect(stickers[0]['y'] + stickers[0]['size'] / 2, closeTo(0.15, 1e-9));
    expect(stickers[1]['x'] + stickers[1]['size'] / 2, closeTo(0.85, 1e-9));
    expect(stickers[1]['size'], greaterThan(0.24));
    expect((stickers[0]['palette'] as Map)['r'], '#ed343d');
    expect(stickers[0]['rows'], isA<List>());
  });

  testWidgets('download hints are shown only to Player 1', (tester) async {
    await _edit(tester, () async {
      expect(find.textContaining('indirilen'), findsNothing);
      expect(find.textContaining('px'), findsNothing);
      expect(find.textContaining('profilde görünür'), findsOneWidget);
    });
    await _edit(tester, () async {
      expect(find.textContaining('indirilen fotoğrafta kalır'), findsOneWidget);
      expect(find.textContaining('3024×3024 px'), findsOneWidget);
    }, admin: true);
  });

  testWidgets('selected stickers rotate with the slider and the 90° button',
      (tester) async {
    final spec = await _edit(tester, () async {
      expect(find.byType(Slider), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Çıkartma ekle').first);
      await tester.pump();
      // Seçiliyken boyut + döndürme kaydırıcıları görünür.
      expect(find.byType(Slider), findsNWidgets(2));
      await tester.tap(find.byTooltip('90° döndür'));
      await tester.pump();
      expect(find.text('90°'), findsOneWidget);
      await tester.tap(find.text('Oyun'));
      await tester.pump();
      expect(find.bySemanticsLabel('Çıkartma ekle'),
          findsNWidgets(kAvatarStickerGroups[1].$2.length.clamp(0, 6)));
    });
    final st = (spec!['stickers'] as List).single as Map<String, dynamic>;
    expect(st['rot'], closeTo(1.5707963, 1e-6));
  });
}
