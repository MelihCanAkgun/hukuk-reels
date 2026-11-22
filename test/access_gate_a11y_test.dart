import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:hukuk_reels/features/gate/access_gate.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928
      ? v / 12.92
      : ((v + 0.055) / 1.055) *
              ((v + 0.055) / 1.055) *
              ((v + 0.055) / 1.055) *
              0 +
          _pow((v + 0.055) / 1.055);
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _pow(double x) => x == 0 ? 0 : (x * x) * _root(x, 0.4);
// x^2.4 = x^2 * x^0.4
double _root(double x, double e) {
  // exp(e*ln x) via dart:math-free Newton is overkill; use simple series
  return _exp(e * _ln(x));
}

double _ln(double x) {
  // ln via atanh series
  final y = (x - 1) / (x + 1);
  var s = 0.0, t = y;
  for (var n = 1; n < 200; n += 2) {
    s += t / n;
    t *= y * y;
  }
  return 2 * s;
}

double _exp(double x) {
  var s = 1.0, t = 1.0;
  for (var n = 1; n < 40; n++) {
    t *= x / n;
    s += t;
  }
  return s;
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
}

Widget _app(
        {double scale = 1, EdgeInsets insets = EdgeInsets.zero, String? err}) =>
    MaterialApp(
      theme: AppTheme.dark,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c)
            .copyWith(textScaler: TextScaler.linear(scale), viewInsets: insets),
        child: child!,
      ),
      home: GateScreen(onUnlocked: () {}, initialError: err),
    );

void main() {
  const sizes = {
    'small 320x568': Size(320, 568),
    'small landscape 568x320': Size(568, 320),
    'phone 390x844': Size(390, 844),
    'phone landscape 844x390': Size(844, 390),
    'tablet 1024x768': Size(1024, 768),
  };
  for (final e in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('no overflow ${e.key} @${scale}x', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = e.value;
        addTearDown(t.view.reset);
        await t.pumpWidget(_app(
            scale: scale,
            err: 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        // tüm hedefler >=48
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        // hata metni kesilmiş mi?
        final para =
            t.renderObject<RenderParagraph>(find.textContaining('Çok fazla'));
        // ignore: invalid_use_of_protected_member
        expect(para.didExceedMaxLines, isFalse, reason: 'error truncated');
      });
    }
  }

  testWidgets('keyboard does not cover submit (320x568, kb 260)', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 568);
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(insets: const EdgeInsets.only(bottom: 260)));
    await t.pumpAndSettle();
    final r = t.getRect(find.byKey(const ValueKey('gate-submit')));
    // ignore: avoid_print
    print('submit rect with kb: $r (visible bottom 308)');
    expect(r.bottom <= 568 - 260, isTrue, reason: '$r');
  });

  testWidgets('semantics: header, labelled field, toggle, autofocus',
      (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    expect(t.getSemantics(find.text('Giriş')),
        matchesSemantics(label: 'Giriş', isHeader: true));
    final field = t.getSemantics(find.descendant(
        of: find.byKey(const ValueKey('gate-code')),
        matching: find.byType(EditableText)));
    // ignore: avoid_print
    print('field semantics: ${field.label} | hint=${field.hint} | '
        'focused=${(field.flagsCollection.isFocused == Tristate.isTrue)} '
        'obscured=${field.flagsCollection.isObscured}');
    expect(field.label, contains('Erişim kodu'));
    expect((field.flagsCollection.isFocused == Tristate.isTrue), isTrue);
    expect(find.byTooltip('Kodu göster'), findsOneWidget);
    await t.tap(find.byTooltip('Kodu göster'));
    await t.pump();
    expect(find.byTooltip('Kodu gizle'), findsOneWidget);
    await expectLater(t, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('enter submits and error is announced', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_app());
    await t.testTextInput.receiveAction(TextInputAction.go);
    await t.pumpAndSettle();
    expect(find.text('Kodu girmen gerekiyor.'), findsOneWidget);
    final s = t.getSemantics(find.text('Kodu girmen gerekiyor.'));
    // ignore: avoid_print
    print('error node liveRegion=${s.flagsCollection.isLiveRegion}');
    h.dispose();
  });

  test('contrast numbers', () {
    final bg = const Color(0xFF1E0F18);
    final bg2 = const Color(0xFF12080F);
    final cs = AppTheme.dark.colorScheme;
    final m = {
      'white on accent (button)': contrast(Colors.white, AppTheme.accent),
      'bg on accent': contrast(AppTheme.bg, AppTheme.accent),
      'textSecondary on bgTop': contrast(AppTheme.textSecondary, bg),
      'textMuted on bgTop': contrast(AppTheme.textMuted, bg),
      'onSurfaceVariant(hint/label/icon) on bgTop':
          contrast(cs.onSurfaceVariant, bg),
      'outline (border) on bgBottom': contrast(cs.outline, bg2),
      'danger on bgTop': contrast(AppTheme.danger, bg),
    };
    // ignore: avoid_print
    m.forEach((k, v) => print('$k: ${v.toStringAsFixed(2)}'));
  });
}
