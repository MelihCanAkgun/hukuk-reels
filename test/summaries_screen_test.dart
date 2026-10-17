import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/summaries/summaries_screen.dart';

void main() {
  testWidgets('summaries list shows İcra and explains web-only notes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SummariesScreen()));
    await tester.pump();
    expect(find.text('Özetler'), findsOneWidget);
    expect(find.text('İcra Hukuku'), findsOneWidget);
    expect(find.textContaining('19 konu'), findsOneWidget);
    expect(find.textContaining('henüz not yok'), findsOneWidget);
    // Testler yerel (VM) derlemede çalışır: not modu yalnız web'de.
    expect(find.textContaining('web uygulamasında'), findsOneWidget);

    await tester.tap(find.text('İcra Hukuku'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('last edit label counts calendar days in Turkish', () {
    final now = DateTime(2026, 10, 17, 9);
    expect(editedLabel(DateTime(2026, 10, 17, 0, 5), now), 'bugün');
    expect(editedLabel(DateTime(2026, 10, 18, 8), now), 'bugün');
    expect(editedLabel(DateTime(2026, 10, 16, 23, 59), now), 'dün');
    expect(editedLabel(DateTime(2026, 10, 12, 12), now), '5 gün önce');
    expect(editedLabel(DateTime(2026, 10, 10, 12), now), '10 Ekim');
    expect(editedLabel(DateTime(2026, 3, 3), now), '3 Mart');
    expect(editedLabel(DateTime(2025, 12, 31), now), '31 Aralık 2025');
    // Yaz saati geçişinde de takvim günü sayılır.
    expect(editedLabel(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 29, 1)),
        'dün');
  });

  test('every summary id maps to a bundled content file', () {
    for (final s in kSummaries) {
      expect(RegExp(r'^[a-z0-9-]+$').hasMatch(s.id), isTrue);
      expect(File('web/notes/summaries/${s.id}.js').existsSync(), isTrue,
          reason: s.id);
    }
  });
}
