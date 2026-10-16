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

  test('every summary id maps to a bundled content file', () {
    for (final s in kSummaries) {
      expect(RegExp(r'^[a-z0-9-]+$').hasMatch(s.id), isTrue);
      expect(File('web/notes/summaries/${s.id}.js').existsSync(), isTrue,
          reason: s.id);
    }
  });
}
