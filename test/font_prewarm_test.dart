import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/utils/font_prewarm.dart';

/// Paketteki yazı tiplerinde olmayan emoji ve semboller.
final _symbol = RegExp(
    '[\u{1F000}-\u{1FAFF}←-⇿⌀-⏿■-◿'
    '☀-➿⬀-⯿]',
    unicode: true);

void main() {
  test('lib/ altındaki her emoji ve sembol önceden ısıtılır', () {
    final missing = <String, String>{};
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      for (final m in _symbol.allMatches(file.readAsStringSync())) {
        final ch = m.group(0)!;
        if (!kAppSymbols.contains(ch)) missing[ch] = file.path;
      }
    }
    expect(missing, isEmpty,
        reason: 'Bunları lib/core/utils/font_prewarm.dart içindeki '
            'kAppSymbols\'a ekle');
  });

  test('ısıtma web dışında hiçbir şey yapmaz ve hata vermez', () {
    expect(prewarmFallbackFonts, returnsNormally);
  });
}
