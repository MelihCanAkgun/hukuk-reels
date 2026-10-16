import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/widgets/pressable.dart';

void main() {
  testWidgets('Pressable is announced as a labelled button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: Pressable(
          semanticLabel: 'Oyunlara dön',
          onTap: () => taps++,
          child: const Icon(Icons.arrow_back_rounded),
        ),
      ),
    ));

    final node = find.bySemanticsLabel('Oyunlara dön');
    expect(node, findsOneWidget);
    expect(
      tester.getSemantics(node),
      matchesSemantics(
        label: 'Oyunlara dön',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Oyunlara dön'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('a Pressable without handlers is a disabled button',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: Pressable(semanticLabel: 'Kilitli', child: Text('x')),
      ),
    ));
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('Kilitli'))),
      matchesSemantics(
        label: 'Kilitli\nx',
        isButton: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });
}
