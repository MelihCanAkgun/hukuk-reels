import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// 5×7 piksel yazı tipi: oyun içi ödül yazıları (COMBO!, SSS…) ve küçük
/// piksel rozetleri için. Yalnız gereken büyük harfler, rakamlar ve birkaç
/// işaret var; tanımsız karakter boşluk sayılır.
const Map<String, List<String>> _glyphs = {
  'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
  'C': ['.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.'],
  'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
  'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
  'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
  'G': ['.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.###.'],
  'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
  'I': ['###', '.#.', '.#.', '.#.', '.#.', '.#.', '###'],
  'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
  'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
  'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
  'N': ['#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#', '#...#'],
  'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
  'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
  'S': ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
  'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
  'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '##.##', '#...#'],
  'X': ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
  'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
  'Z': ['#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'],
  '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  '3': ['####.', '....#', '....#', '.###.', '....#', '....#', '####.'],
  '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  '6': ['.###.', '#....', '#....', '####.', '#...#', '#...#', '.###.'],
  '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
  '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  '9': ['.###.', '#...#', '#...#', '.####', '....#', '....#', '.###.'],
  '!': ['##', '##', '##', '##', '##', '..', '##'],
  '+': ['.....', '..#..', '..#..', '#####', '..#..', '..#..', '.....'],
  '×': ['.....', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '.....'],
  '·': ['..', '..', '..', '##', '##', '..', '..'],
  ' ': ['..', '..', '..', '..', '..', '..', '..'],
};

/// Bir yazının piksel katmanları (gölge, kontur, üç tonlu dolgu), harf
/// harf. Birimler piksel karesidir; [paint] her kareyi [px] boyunda çizer.
/// Kontur her harfin çevresine 1 kare taşar, gölge 1 kare aşağıdadır.
class PixelTextLayout {
  PixelTextLayout(
    String text, {
    required Color color,
    Color? light,
    Color? dark,
    this.outline = const Color(0xFF141B33),
    this.shadow = const Color(0xFF070B18),
  })  : light = light ?? Color.lerp(color, const Color(0xFFFFFFFF), .55)!,
        dark = dark ?? Color.lerp(color, const Color(0xFF000000), .28)!,
        fill = color {
    var x = 1;
    for (final rune in text.toUpperCase().runes) {
      final rows = _glyphs[String.fromCharCode(rune)] ?? _glyphs[' ']!;
      final g = _Glyph(x, rows.first.length);
      for (var y = 0; y < rows.length; y++) {
        for (var cx = 0; cx < rows[y].length; cx++) {
          if (rows[y][cx] != '#') continue;
          final ux = (x + cx).toDouble(), uy = y + 1.0;
          g.outline.addRect(Rect.fromLTWH(ux - 1, uy - 1, 3, 3));
          (y < 2 ? g.light : (y < 5 ? g.fill : g.dark))
              .addRect(Rect.fromLTWH(ux, uy, 1, 1));
        }
      }
      g.shadow = g.outline.shift(const Offset(1, 1));
      _letters.add(g);
      x += rows.first.length + 1;
    }
    width = x + 1; // son harften sonraki boşluk yerine sağ kontur + gölge
  }

  final Color fill, light, dark, outline, shadow;
  final List<_Glyph> _letters = [];

  /// Kontur ve gölge dahil kare cinsinden boyut.
  late final int width;
  static const int height = 10;
  int get letterCount => _letters.length;

  /// [origin] sol üst köşedir. [lift] harf başına yukarı kayma (kare
  /// cinsinden; dalga/zıplama). [tint] verilirse harf başına dolgu rengi.
  void paint(Canvas canvas, Offset origin, double px,
      {double Function(int letter)? lift, Color Function(int letter)? tint}) {
    final paint = Paint()..isAntiAlias = false;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(px);
    // Gölgeler önce: komşu harfin konturu üstüne binmesin.
    for (var pass = 0; pass < 3; pass++) {
      for (var i = 0; i < _letters.length; i++) {
        final dy = (lift?.call(i) ?? 0).roundToDouble();
        canvas.save();
        canvas.translate(0, -dy);
        _pass(canvas, _letters[i], pass, paint, tint?.call(i));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _pass(Canvas canvas, _Glyph g, int pass, Paint paint, Color? tint) {
    switch (pass) {
      case 0:
        canvas.drawPath(g.shadow, paint..color = shadow);
      case 1:
        canvas.drawPath(g.outline, paint..color = outline);
      default:
        final base = tint ?? fill;
        final up = tint == null
            ? light
            : Color.lerp(base, const Color(0xFFFFFFFF), .55)!;
        final down = tint == null
            ? dark
            : Color.lerp(base, const Color(0xFF000000), .28)!;
        canvas.drawPath(g.light, paint..color = up);
        canvas.drawPath(g.fill, paint..color = base);
        canvas.drawPath(g.dark, paint..color = down);
    }
  }

  /// [letter] harfinin kontur ve gölge dahil kutusu (kare cinsinden; x
  /// yazının solundan).
  Rect letterBox(int letter) {
    final g = _letters[letter];
    return Rect.fromLTWH(g.x - 1.0, 0, g.w + 3.0, height.toDouble());
  }

  /// [letter] harfini tek başına, [px] boyunda ve [dpr] çözünürlüğünde bir
  /// görüntüye çizer. Animasyonda her karede yüzlerce kareden oluşan yolu
  /// yeniden çizmek yerine bu hazır görüntü çizilir (iPhone'da akıcılık).
  ui.Image letterImage(int letter, double px, double dpr, {Color? tint}) {
    final box = letterBox(letter);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(px * dpr)
      ..translate(-box.left, 0);
    final paint = Paint()..isAntiAlias = false;
    for (var pass = 0; pass < 3; pass++) {
      _pass(canvas, _letters[letter], pass, paint, tint);
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
        (box.width * px * dpr).ceil(), (box.height * px * dpr).ceil());
    picture.dispose();
    return image;
  }
}

class _Glyph {
  _Glyph(this.x, this.w);
  final int x, w;
  final outline = Path(), light = Path(), fill = Path(), dark = Path();
  late final Path shadow;
}

/// Arayüzde küçük piksel yazı (rozet, başlık).
class PixelText extends StatelessWidget {
  const PixelText(
    this.text, {
    super.key,
    this.color = const Color(0xFFFFD568),
    this.px = 2,
  });

  final String text;
  final Color color;
  final double px;

  @override
  Widget build(BuildContext context) {
    final layout = PixelTextLayout(text, color: color);
    return Semantics(
      label: text,
      child: SizedBox(
        width: layout.width * px,
        height: PixelTextLayout.height * px,
        child: CustomPaint(painter: _PixelTextPainter(layout, px)),
      ),
    );
  }
}

class _PixelTextPainter extends CustomPainter {
  _PixelTextPainter(this.layout, this.px);
  final PixelTextLayout layout;
  final double px;

  @override
  void paint(Canvas canvas, Size size) => layout.paint(canvas, Offset.zero, px);

  @override
  bool shouldRepaint(_PixelTextPainter old) =>
      old.layout != layout || old.px != px;
}
