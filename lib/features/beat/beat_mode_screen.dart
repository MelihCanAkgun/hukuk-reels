import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/sfx_service.dart';
import '../surprise/pixel_font.dart';
import '../surprise/pixel_sprites.dart';

/// "Yanlış Soruları Döv" modu 🏏
///
/// Sopayı al, sıra sıra kaydırıp istediğin yanlış soruya vur. Her vuruşta
/// ekran çatlar ve sorunun harfleri dağılır. 10 vuruştan sonra hangi şıkkı
/// işaretlersen doğru cevap o olur (soru pes eder).
///
/// Performans: soru metni bir kez dizilir ve harfler tek bir CustomPainter
/// ile çizilir; sopa, patlama ve kıymıklar önbelleğe alınmış piksel
/// resimlerle ayrı bir katmanda boyanır. Vuruşta yalnızca bu katmanlar
/// yeniden boyanır, metin yeniden dizilmez.
class BeatModeScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  const BeatModeScreen({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _BeatPager(questions: questions),
      ),
    );
  }
}

class _BeatPager extends StatefulWidget {
  final List<QuizQuestion> questions;
  const _BeatPager({required this.questions});

  @override
  State<_BeatPager> createState() => _BeatPagerState();
}

class _BeatPagerState extends State<_BeatPager> {
  final _controller = PageController();
  final _page = ValueNotifier<int>(0);
  int? _firstDefeatedIndex;

  /// İlk dövülen sorunun index'ini kaydeder; bu kartın ilk dövülen olup
  /// olmadığını döndürür.
  bool _registerDefeat(int index) {
    _firstDefeatedIndex ??= index;
    return _firstDefeatedIndex == index;
  }

  @override
  void dispose() {
    _controller.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final pad = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          itemCount: total,
          // Sayfa değişince yalnızca sayaç yenilenir, kartlar değil.
          onPageChanged: (i) {
            _page.value = i;
            HapticFeedback.selectionClick();
          },
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(top: pad.top + 60),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth < 480 ? c.maxWidth : 480.0;
                  return Center(
                    child: SizedBox(
                      width: w,
                      height: c.maxHeight,
                      child: _BeatCard(
                        key: ValueKey(widget.questions[index].id),
                        question: widget.questions[index],
                        index: index,
                        registerDefeat: _registerDefeat,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        // Üst bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(8, pad.top + 6, 16, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Geri',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary),
                ),
                const _BatIcon(size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Yanlış Soruları Döv',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _page,
                    builder: (context, page, _) => Text(
                      '${page + 1} / $total',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Piksel resim önbelleği ─────────────────────────

/// Piksel dizilerini bir kez [ui.Picture]'a kaydeder; her karede yüzlerce
/// kare çizmek yerine hazır resim çizilir.
class _Sprites {
  static final Map<String, ui.Picture> _cache = {};

  static ui.Picture of(String name, List<String> rows, double px) {
    return _cache.putIfAbsent('$name@$px', () {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final paint = Paint()..isAntiAlias = false;
      for (var y = 0; y < rows.length; y++) {
        final row = rows[y];
        for (var x = 0; x < row.length; x++) {
          final ch = row[x];
          if (ch == '.') continue;
          paint.color = kSpritePalette[ch]!;
          // Komşu karelerin arasında ince boşluk kalmasın diye hafif taşır.
          c.drawRect(Rect.fromLTWH(x * px, y * px, px + 0.35, px + 0.35), paint);
        }
      }
      return rec.endRecording();
    });
  }

  static Size sizeOf(List<String> rows, double px) =>
      Size(rows.first.length * px, rows.length * px);
}

/// Üst bardaki küçük piksel sopa.
class _BatIcon extends StatelessWidget {
  const _BatIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BatIconPainter()),
      );
}

class _BatIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final px = size.height / kBatSprite.length * 1.25;
    final s = _Sprites.sizeOf(kBatSprite, px);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.75);
    canvas.translate(-s.width / 2, -s.height / 2);
    canvas.drawPicture(_Sprites.of('bat', kBatSprite, px));
  }

  @override
  bool shouldRepaint(_BatIconPainter old) => false;
}

// ───────────────────────── Kart ─────────────────────────

/// Tek bir "dövülebilir" soru kartı.
class _BeatCard extends StatefulWidget {
  final QuizQuestion question;
  final int index;
  final bool Function(int index) registerDefeat;
  const _BeatCard({
    super.key,
    required this.question,
    required this.index,
    required this.registerDefeat,
  });

  @override
  State<_BeatCard> createState() => _BeatCardState();
}

class _BeatCardState extends State<_BeatCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const int kHitsNeeded = 10;

  // Çatlak çizgileri vuruş ANINDA bir kez hesaplanır (her karede yeniden
  // üretilmez).
  final List<({Offset a, Offset b})> _crackSegs = [];
  int _hits = 0;
  int? _selected; // pes ettikten sonra seçilen (zorla doğru) şık
  bool _showResist = false;
  bool _isFirst = false; // bu kart, ilk dövülen soru mu?
  bool _apologyAccepted = false; // özür kabul edildi mi?

  /// Vuruş efektlerinin (sopa, patlama, kıymık) ortak durumu.
  final _fx = _HitFx();

  static const String _apologyMsg =
      'Yüce Hukuk Profesörü Arife Hanım, siz yanlış işaretlemediniz, ben '
      'yanlışmışım… Tüm yaşantım, tüm bildiklerim birer yalanmış. Lütfen SİZ '
      'bana öğretin, hangi şıkkım doğru? 😭';

  late final AnimationController _shake;
  late final AnimationController _swing;
  late final AnimationController _scatter;

  bool get _defeated => _hits >= kHitsNeeded;
  double get _intensity => (_hits / kHitsNeeded).clamp(0.0, 1.0);
  Color get _accent => widget.question.category.color;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _swing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _scatter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
  }

  @override
  void dispose() {
    _shake.dispose();
    _swing.dispose();
    _scatter.dispose();
    super.dispose();
  }

  void _hit(Offset pos) {
    _fx.hit(pos, seed: _hits * 7919 + pos.dx.round() * 31 + pos.dy.round());
    if (_defeated) {
      // Pes etti; artık şık seçilmeli. Yine de küçük bir tepki ver.
      _fx.label = null;
      SfxService.instance.bonk(_hits);
      _swing.forward(from: 0);
      return;
    }
    final hits = _hits + 1;
    _fx.label = hits >= kHitsNeeded ? 'K.O.!' : 'BONK!';
    setState(() {
      _hits = hits;
      _addCrackAt(pos);
    });
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
    _swing.forward(from: 0);
    _scatter.animateTo(_intensity, curve: Curves.easeOut);
    if (_hits == kHitsNeeded) {
      SfxService.instance.ko();
      _onDefeated();
    } else {
      SfxService.instance.bonk(_hits);
    }
  }

  /// Vuruş noktasından yayılan çatlak çizgilerini üretir (tek seferlik).
  void _addCrackAt(Offset p) {
    final rnd = Random((p.dx * 53 + p.dy * 17).toInt());
    final spokes = 5 + rnd.nextInt(4);
    final ends = <Offset>[];
    for (var i = 0; i < spokes; i++) {
      final ang = (i / spokes) * 2 * pi + rnd.nextDouble() * 0.7;
      final len = 26 + rnd.nextDouble() * 78;
      final segs = 2 + rnd.nextInt(2);
      var cur = p;
      for (var s = 0; s < segs; s++) {
        final na = ang + (rnd.nextDouble() - 0.5) * 0.55;
        final next = cur + Offset(cos(na), sin(na)) * (len / segs);
        _crackSegs.add((a: cur, b: next));
        cur = next;
      }
      ends.add(cur);
    }
    // Halka (örümcek ağı) bağlantıları
    for (var i = 0; i < ends.length; i++) {
      if (rnd.nextBool()) {
        final s1 = Offset.lerp(p, ends[i], 0.55)!;
        final s2 = Offset.lerp(p, ends[(i + 1) % ends.length], 0.55)!;
        _crackSegs.add((a: s1, b: s2));
      }
    }
  }

  void _onDefeated() {
    final isFirst = widget.registerDefeat(widget.index);
    setState(() => _isFirst = isFirst);
    // İlk dövülen soru için özür pop-up'ı.
    if (isFirst) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _showApologyDialog();
      });
    }
  }

  void _showApologyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ApologyDialog(
        questionNo: widget.index + 1,
        onAccept: () {
          Navigator.of(ctx).pop();
          setState(() {
            _apologyAccepted = true;
            _crackSegs.clear();
          });
        },
        onDecline: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _selectOption(int index) {
    if (!_defeated) {
      // Daha pes etmedi: direnç göster.
      HapticFeedback.lightImpact();
      SfxService.instance.nope();
      _shake.forward(from: 0);
      setState(() => _showResist = true);
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _showResist = false);
      });
      return;
    }
    if (_selected != null) return;
    setState(() => _selected = index);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        if (t == 0 || t == 1) return child!;
        final decay = 1 - t;
        // Piksel hissi için sarsıntı tam piksellere oturur.
        final dx = (sin(t * pi * 10) * 9 * decay).roundToDouble();
        final dy = (cos(t * pi * 9) * 6 * decay).roundToDouble();
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      // RepaintBoundary: sarsıntı sırasında kart içeriği yeniden boyanmaz,
      // önbelleğe alınmış katman sadece taşınır.
      child: RepaintBoundary(
        child: Stack(
          children: [
            _card(),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _HitFxPainter(_fx, _swing),
                  ),
                ),
              ),
            ),
            if (_showResist) _resistBubble(),
          ],
        ),
      ),
    );
  }

  Widget _card() {
    final q = widget.question;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.bgElevated],
        ),
        borderRadius: BorderRadius.circular(22),
        // Bulanık gölge yerine çizgi: her vuruşta yeniden boyanırken ucuz.
        border: Border.all(
          color: _defeated ? AppTheme.success : _accent.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Vuruş alanı (şıklar hariç her yer) — en altta
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // onTapUp: gerçek dokunuşta vurur; kaydırma (sonraki soruya
                // geçiş) yanlışlıkla vuruş saymaz.
                onTapUp: (d) => _hit(d.localPosition + const Offset(2, 2)),
              ),
            ),
            // İçerik: sığmazsa taşmak yerine orantılı küçülür (uzun soru,
            // özür mesajı veya küçük ekran).
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, c) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: c.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _badge(),
                        const SizedBox(height: 10),
                        _hitMeter(),
                        const SizedBox(height: 14),
                        // Dağılan soru metni — özür kabul edildiyse özür mesajı.
                        IgnorePointer(
                          child: (_isFirst && _apologyAccepted)
                              ? _apologyMessage()
                              : _ShatterText(
                                  text: q.question, intensity: _scatter),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(q.options.length, (i) => _option(i)),
                        const SizedBox(height: 8),
                        _footerHint(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Çatlak katmanı (özür kabul edilince temizlenir)
            if (!(_isFirst && _apologyAccepted))
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CrackPainter(_crackSegs),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge() {
    final cat = widget.question.category;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cat.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, color: cat.color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              cat.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cat.color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sorunun "canı": 10 piksel blok. Her vuruşta biri söner.
  Widget _hitMeter() {
    if (_defeated) {
      return Row(
        children: [
          Text(_isFirst ? '🥹' : '😈', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _isFirst
                  ? 'İstediğin şıkkı seçebilirsin'
                  : 'DÖVÜLDÜ! Şıkkı seç, doğrusu o olsun.',
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }
    final left = kHitsNeeded - _hits;
    return Row(
      children: [
        const Text(
          'SORU CANI',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        for (var i = 0; i < kHitsNeeded; i++)
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < left ? _accent : AppTheme.border.withValues(alpha: 0.6),
              border: Border.all(
                color: i < left
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _apologyMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        _apologyMsg,
        style: TextStyle(
          fontSize: 16.5,
          height: 1.5,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _option(int index) {
    final q = widget.question;
    final isChosen = _selected == index;

    Color bg = AppTheme.surfaceHigh;
    Color borderColor = AppTheme.border;
    Color fg = AppTheme.textPrimary;
    Color badgeBg = AppTheme.bg;
    Color badgeFg = AppTheme.textSecondary;
    IconData? trailing;

    if (_defeated && isChosen) {
      bg = AppTheme.success.withValues(alpha: 0.16);
      borderColor = AppTheme.success;
      badgeBg = AppTheme.success;
      badgeFg = Colors.white;
      trailing = Icons.check_circle_rounded;
    } else if (_defeated && _selected != null) {
      fg = AppTheme.textMuted;
      borderColor = AppTheme.border.withValues(alpha: 0.5);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onTap: () => _selectOption(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _letters[index],
                  style: TextStyle(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.options[index],
                  style: TextStyle(
                    color: fg,
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: AppTheme.success, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerHint() {
    final String txt;
    if (_defeated && _selected != null) {
      txt = '✓ Senin dediğin doğru! 😈 (yukarı kaydır → sıradaki)';
    } else if (_defeated) {
      txt = 'Pes etti! Bir şık seç, doğrusu o olsun.';
    } else {
      txt = 'Sopayla karta vur — harfler dağılsın 🪓';
    }
    return Row(
      children: [
        Icon(
          _defeated ? Icons.emoji_events_rounded : Icons.sports_cricket_rounded,
          color: _defeated ? AppTheme.success : AppTheme.textMuted,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            txt,
            style: TextStyle(
              color: _defeated ? AppTheme.success : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resistBubble() {
    return Positioned(
      left: 0,
      right: 0,
      top: 90,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'Daha ${kHitsNeeded - _hits} kez döv! 🪓',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Vuruş efektleri ─────────────────────────

/// Son vuruşun konumu ve kıymık yönleri (painter bunu okur).
class _HitFx {
  Offset at = Offset.zero;
  bool active = false;
  String? label;
  final List<(Offset, Color)> chips = [];

  static const _chipColors = [
    Color(0xFFF2C48A),
    Color(0xFFD99A55),
    Color(0xFFA8662E),
    Color(0xFFFFFFFF),
    Color(0xFFFFD84D),
  ];

  void hit(Offset p, {required int seed}) {
    at = p;
    active = true;
    final rnd = Random(seed);
    chips
      ..clear()
      ..addAll(List.generate(9, (i) {
        final a = -pi / 2 + (rnd.nextDouble() - 0.5) * 2.6;
        final v = 120 + rnd.nextDouble() * 160;
        return (Offset(cos(a) * v, sin(a) * v), _chipColors[i % 5]);
      }));
  }
}

/// Sopa (beklerken sağ altta, vuruşta tıklanan yere iner), piksel patlama,
/// "BONK!" yazısı ve tahta kıymıkları. Yalnız [swing] ilerledikçe boyanır.
class _HitFxPainter extends CustomPainter {
  _HitFxPainter(this.fx, this.swing) : super(repaint: swing);
  final _HitFx fx;
  final Animation<double> swing;

  static const double _batPx = 3.5;
  static final _chipPaint = Paint()..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    final t = swing.value;
    final animating = fx.active && t > 0 && t < 1;
    final bat = _Sprites.of('bat', kBatSprite, _batPx);
    final batSize = _Sprites.sizeOf(kBatSprite, _batPx);

    if (!animating) {
      // Bekleme: sağ alt köşede yaslanmış sopa.
      _drawBat(canvas, bat, batSize,
          Offset(size.width - 22, size.height - 14), -0.42);
      return;
    }

    // Vuruş anı ~%28'de: sopa sağ-yukarıdan iner, değer, hafifçe geri seker.
    const contact = 0.28;
    double angle;
    if (t < contact) {
      final k = Curves.easeIn.transform(t / contact);
      angle = 1.6 * (1 - k);
    } else {
      final k = (t - contact) / (1 - contact);
      angle = 0.38 * sin(k * pi) * (1 - k);
    }
    // Retro his: açı 0.12 rad'lık adımlara oturur.
    angle = (angle / 0.12).round() * 0.12;
    // Sopanın ucu tıklanan noktaya değecek şekilde sap aşağı-sağda durur.
    final handle = fx.at + Offset(batSize.height * 0.5, batSize.height * 0.78);
    _drawBat(canvas, bat, batSize, handle, angle - 0.58);

    if (t < contact) return;
    final k = (t - contact) / (1 - contact); // 0..1 vuruş sonrası

    // Kıymıklar
    for (final (v, color) in fx.chips) {
      final p = fx.at + v * (k * 0.45) + Offset(0, 520 * k * k * 0.2);
      final s = (k < 0.8 ? 5.0 : 3.0);
      _chipPaint.color = color;
      canvas.drawRect(
          Rect.fromLTWH(p.dx.roundToDouble(), p.dy.roundToDouble(), s, s),
          _chipPaint);
    }

    // Patlama yıldızı: büyür, küçülür (piksel boyu adım adım).
    const steps = [3.0, 5.0, 6.0, 5.0, 4.0, 3.0, 2.0];
    final px = steps[(k * (steps.length - 1)).floor()];
    final burst = _Sprites.of('burst', kBurstSprite, px);
    final bs = _Sprites.sizeOf(kBurstSprite, px);
    canvas.save();
    canvas.translate((fx.at.dx - bs.width / 2).roundToDouble(),
        (fx.at.dy - bs.height / 2).roundToDouble());
    canvas.drawPicture(burst);
    canvas.restore();

    // "BONK!" / "K.O.!" yukarı süzülür.
    final label = fx.label;
    if (label != null && k < 0.85) {
      const lpx = 3.0;
      final w = pixelLineWidth(label) * lpx;
      final origin = Offset(
        (fx.at.dx - w / 2).clamp(4.0, max(4.0, size.width - w - 4)),
        fx.at.dy - 70 - 28 * k,
      );
      paintPixelText(canvas, label, origin, lpx,
          label == 'K.O.!' ? const Color(0xFFFFD84D) : const Color(0xFFFFFFFF),
          shadow: const Color(0xFFB8285A));
    }
  }

  void _drawBat(Canvas canvas, ui.Picture bat, Size batSize, Offset handle,
      double angle) {
    canvas.save();
    canvas.translate(handle.dx, handle.dy);
    canvas.rotate(angle);
    // Sapın ucu (resmin alt ortası) dönme noktasıdır.
    canvas.translate(-batSize.width / 2, -batSize.height);
    canvas.drawPicture(bat);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HitFxPainter old) => old.fx != fx;
}

/// Önceden hesaplanmış çatlak çizgilerini çizer. Üretim _addCrackAt'te bir
/// kez yapılır; burada yalnızca hazır segmentler çizilir.
class _CrackPainter extends CustomPainter {
  final List<({Offset a, Offset b})> segments;
  final int count;
  _CrackPainter(this.segments) : count = segments.length;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final faint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (final s in segments) {
      path
        ..moveTo(s.a.dx, s.a.dy)
        ..lineTo(s.b.dx, s.b.dy);
    }
    canvas.drawPath(path, faint);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_CrackPainter old) => old.count != count;
}

// ───────────────────────── Dağılan metin ─────────────────────────

/// Yoğunluğa (0..1) göre harfleri dağıtan metin.
///
/// Metin genişliğe göre bir kez dizilir; her harfin konumu ve kendi küçük
/// paragrafı saklanır. Animasyon sırasında yalnızca CustomPainter yeniden
/// boyanır — widget kurulmaz, metin yeniden dizilmez.
class _ShatterText extends StatefulWidget {
  final String text;
  final Animation<double> intensity;
  const _ShatterText({required this.text, required this.intensity});

  @override
  State<_ShatterText> createState() => _ShatterTextState();
}

class _ShatterTextState extends State<_ShatterText> {
  static const _style = TextStyle(
    fontSize: 19,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

  _ShatterLayout? _layout;

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      var layout = _layout;
      if (layout == null ||
          layout.width != width ||
          layout.text != widget.text ||
          layout.scaler != scaler) {
        layout?.dispose();
        layout = _layout = _ShatterLayout(widget.text, width, _style, scaler);
      }
      return SizedBox(
        width: width,
        height: layout.height,
        child: CustomPaint(
          painter: _ShatterPainter(layout, widget.intensity),
        ),
      );
    });
  }
}

class _Glyph {
  _Glyph(this.painter, this.origin, this.dir, this.spin);
  final TextPainter painter;
  final Offset origin;
  final Offset dir;
  final double spin;
}

class _ShatterLayout {
  _ShatterLayout(this.text, this.width, TextStyle style, this.scaler) {
    final full = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: width);
    height = full.height + 4;
    var offset = 0;
    var index = 0;
    for (final ch in text.characters) {
      final start = offset;
      offset += ch.length;
      if (ch.trim().isEmpty) continue;
      final boxes = full.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: offset));
      if (boxes.isEmpty) continue;
      final box = boxes.first;
      final rnd = Random(index++ * 9973 + ch.codeUnitAt(0));
      final painter = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      glyphs.add(_Glyph(
        painter,
        Offset(box.left, box.top),
        Offset(rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1),
        rnd.nextDouble() * 2 - 1,
      ));
    }
    full.dispose();
  }

  final String text;
  final double width;
  final TextScaler scaler;
  late final double height;
  final List<_Glyph> glyphs = [];

  void dispose() {
    for (final g in glyphs) {
      g.painter.dispose();
    }
  }
}

class _ShatterPainter extends CustomPainter {
  _ShatterPainter(this.layout, this.intensity) : super(repaint: intensity);
  final _ShatterLayout layout;
  final Animation<double> intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final v = intensity.value;
    final fade = v <= 0 ? 1.0 : (1 - v * 0.85).clamp(0.0, 1.0);
    final layered = fade < 0.999;
    if (layered) {
      // Tek bir saydamlık katmanı: harf başına ayrı katman açılmaz.
      canvas.saveLayer(
        Rect.fromLTWH(-80, -60, size.width + 160, size.height + 160),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade),
      );
    }
    for (final g in layout.glyphs) {
      if (v <= 0) {
        g.painter.paint(canvas, g.origin);
        continue;
      }
      final w = g.painter.width, h = g.painter.height;
      final dx = g.dir.dx * 46 * v;
      final dy = g.dir.dy * 26 * v + v * v * 34;
      canvas.save();
      canvas.translate(g.origin.dx + dx + w / 2, g.origin.dy + dy + h / 2);
      canvas.rotate(g.spin * 1.1 * v);
      g.painter.paint(canvas, Offset(-w / 2, -h / 2));
      canvas.restore();
    }
    if (layered) canvas.restore();
  }

  @override
  bool shouldRepaint(_ShatterPainter old) => old.layout != layout;
}

// ───────────────────────── Özür penceresi ─────────────────────────

/// İlk dövülen sorunun "özür dileme" pop-up'ı.
class _ApologyDialog extends StatelessWidget {
  final int questionNo;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _ApologyDialog({
    required this.questionNo,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥹', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 14),
            Text(
              '$questionNo. soru sizden özür dilemek istiyor',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'Kabul etme',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppTheme.pinkGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Kabul et',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
