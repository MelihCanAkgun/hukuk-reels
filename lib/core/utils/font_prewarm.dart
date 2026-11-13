import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Uygulamanın ekranlarında geçen emoji ve semboller. Bunlar paketteki yazı
/// tiplerinde (Inter, Pixelify Sans) yoktur; Flutter web, ilk karşılaştığında
/// yedek yazı tipini (Noto Color Emoji vb.) parça parça indirir ve her parça
/// gelince bütün metinleri yeniden dizer. Yavaş bağlantıda bu, kullanım
/// sırasında rastgele takılma ve boş kutu şeklinde emoji demektir.
///
/// [prewarmFallbackFonts] açılıştan hemen sonra hepsini bir kez dizdirir:
/// indirme ve yeniden dizme kullanıcı bir ekrana girmeden biter. Servis
/// çalışanı (web/sw.js) bu parçaları kalıcı önbelleğe alır; sonraki
/// açılışlarda ağ gerekmez.
///
/// `test/font_prewarm_test.dart` lib/ altındaki bütün emoji ve sembollerin
/// burada olduğunu denetler: yeni bir emoji kullanınca buraya da ekle.
const kAppSymbols =
    '→↔⏱○●★♥⚔⚡✈✓✕✗⭐🌷🍿🎉🎞🎬🎲🏃🏆🏏👆👇👈👉👋👤💌💕💖💗💞💥💪💬📌📚📺'
    '🔁🔍🔥😅😆😈😎😘😝😟😤😭😿🙄🙈🛠🤔🥰🥹🥺🧠🪓🫂'
    // Bildirim ve mesajlarda sık geçenler (oyuncu adı, not, yorum).
    '❤🧡💛💚💙💜🖤🤍💘💝😀😂🤣😊😍😉😋😜🤗😴😢😡👍👏🙏✨🎁🎂🌹☕🍕🍫🐱🐶🌙☀⏳🪙🎮🎯';

bool _done = false;

/// Yedek yazı tiplerini önceden yükletir (yalnız web; bir kez).
void prewarmFallbackFonts() {
  if (!kIsWeb || _done) return;
  _done = true;
  try {
    // Motor, eksik karakterleri metin eklenirken saptar ve yedek yazı tipini
    // arka planda indirir; dizim ekrana çizilmez.
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 14))
      ..addText(kAppSymbols);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 2000));
    paragraph.dispose();
  } catch (_) {
    // Isıtma başarısız olursa yazı tipleri eskisi gibi gerektiğinde iner.
  }
}
