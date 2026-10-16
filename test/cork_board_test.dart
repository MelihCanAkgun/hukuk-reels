import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/widgets/fit_text.dart';
import 'package:hukuk_reels/features/home/home_store.dart';
import 'package:hukuk_reels/features/home/cork_board.dart';

Note _note(int player, String text) => Note.fromJson({
      'id': player,
      'player': player,
      'name': player == 1 ? 'mqcan 😎' : 'ari',
      'text': text,
      'expires': DateTime.now()
              .add(const Duration(hours: 20))
              .millisecondsSinceEpoch ~/
          1000,
    });

void main() {
  test('longer text gets a smaller font, never larger than the box', () {
    const style = TextStyle(fontFamily: 'PixelifySans', height: 1.15);
    const box = Size(140, 150);
    final short = FitText.fit('Seni seviyorum', style, box, maxSize: 26);
    final long = FitText.fit('Seni seviyorum ' * 12, style, box, maxSize: 26);
    expect(long, lessThan(short));
    expect(short, lessThanOrEqualTo(26));
    // Words are not split while a smaller size keeps them whole.
    const wordStyle = TextStyle(fontSize: 10);
    final whole = FitText.fit(
        'görüşürüz hazır ol', wordStyle, const Size(100, 300),
        maxSize: 40);
    final p = TextPainter(
      text: TextSpan(
          text: 'görüşürüz', style: wordStyle.copyWith(fontSize: whole)),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(p.width, lessThanOrEqualTo(100));
  });

  testWidgets('notes never overflow the paper, whatever the text',
      (tester) async {
    final texts = [
      'Hi',
      'x' * 200, // tek uzun kelime
      List.filled(8, 'satır satır').join('\n'),
      'Kavuşmamıza az kaldı! ' * 9,
    ];
    for (final size in const [Size(110, 150), Size(150, 200), Size(240, 210)]) {
      for (final player in [1, 2]) {
        for (final text in texts) {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: NotePaper(note: _note(player, text), onDelete: () {}),
                ),
              ),
            ),
          ));
          expect(tester.takeException(), isNull,
              reason: '$size / player $player / ${text.length} chars');
          final fit = tester.widget<Text>(find.descendant(
              of: find.byType(FitText), matching: find.byType(Text)));
          expect(fit.style!.fontSize, inInclusiveRange(8, 26));
          // Text'in ekranda kullandığı stil, ölçümde kullanılanla aynı.
          final ctx = tester.element(find.byType(FitText));
          expect(fit.style, DefaultTextStyle.of(ctx).style.merge(fit.style));
        }
      }
    }
  });
}
