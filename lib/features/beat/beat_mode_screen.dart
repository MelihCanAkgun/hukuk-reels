import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/quiz_question.dart';

/// "Yanlış Soruları Döv" modu 🏏
///
/// Sopayı al, sıra sıra kaydırıp istediğin yanlış soruya vur. Her vuruşta
/// ekran çatlar ve sorunun harfleri dağılır. 10 vuruştan sonra hangi şıkkı
/// işaretlersen doğru cevap o olur (soru pes eder).
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
  int _page = 0;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final pad = MediaQuery.of(context).padding;

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          itemCount: total,
          onPageChanged: (i) {
            setState(() => _page = i);
            HapticFeedback.selectionClick();
          },
          itemBuilder: (context, index) {
            final topInset = pad.top + 60;
            return Padding(
              padding: EdgeInsets.only(top: topInset),
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
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary),
                ),
                const Text('🏏', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                const Text(
                  'Yanlış Soruları Döv',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '${_page + 1} / $total',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  final List<Offset> _cracks = [];
  int _hits = 0;
  int? _selected; // pes ettikten sonra seçilen (zorla doğru) şık
  Offset _lastHit = Offset.zero;
  bool _showResist = false;
  bool _isFirst = false; // bu kart, ilk dövülen soru mu?
  bool _apologyAccepted = false; // özür kabul edildi mi?

  static const String _apologyMsg =
      'Yüce Hukuk Profesörü Arife Hanım, siz yanlış işaretlemediniz, ben '
      'yanlışmışım… Tüm yaşantım, tüm bildiklerim birer yalanmış. Lütfen SİZ '
      'bana öğretin, hangi şıkkım doğru? 😭';

  late final AnimationController _shake;
  late final AnimationController _bat;

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
        vsync: this, duration: const Duration(milliseconds: 460));
    _bat = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
  }

  @override
  void dispose() {
    _shake.dispose();
    _bat.dispose();
    super.dispose();
  }

  void _hit(Offset pos) {
    if (_defeated) {
      // Pes etti; artık şık seçilmeli. Yine de küçük bir tepki ver.
      _bat.forward(from: 0);
      return;
    }
    setState(() {
      _hits++;
      _lastHit = pos;
      _cracks.add(pos);
    });
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
    _bat.forward(from: 0);
    if (_hits == kHitsNeeded) _onDefeated();
  }

  void _onDefeated() {
    final isFirst = widget.registerDefeat(widget.index);
    setState(() => _isFirst = isFirst);
    // İlk dövülen soru için özür pop-up'ı.
    if (isFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
          setState(() => _apologyAccepted = true);
        },
        onDecline: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _selectOption(int index) {
    if (!_defeated) {
      // Daha pes etmedi: direnç göster.
      HapticFeedback.lightImpact();
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
        final decay = 1 - t;
        final dx = sin(t * pi * 10) * 11 * decay;
        final dy = cos(t * pi * 9) * 7 * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: Stack(
        children: [
          _card(),
          _batWidget(),
          if (_showResist) _resistBubble(),
        ],
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _defeated ? AppTheme.success : AppTheme.border,
          width: _defeated ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.16),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Vuruş alanı (şıklar hariç her yer) — en altta
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // onTapUp: gerçek dokunuşta vurur; kaydırma (sonraki soruya
                // geçiş) yanlışlıkla vuruş saymaz.
                onTapUp: (d) => _hit(d.localPosition),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge(),
                  const SizedBox(height: 8),
                  _hitMeter(),
                  const SizedBox(height: 14),
                  // Dağılan soru metni — özür kabul edildiyse özür mesajı.
                  IgnorePointer(
                    child: (_isFirst && _apologyAccepted)
                        ? _apologyMessage()
                        : _ShatterText(
                            text: q.question,
                            intensity: _intensity,
                          ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(q.options.length, (i) => _option(i)),
                  const Spacer(),
                  _footerHint(),
                ],
              ),
            ),
            // Çatlak katmanı (özür kabul edilince temizlenir)
            if (!(_isFirst && _apologyAccepted))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _CrackPainter(_cracks)),
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
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
          ),
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
    return Row(
      children: [
        const Text('🏏', style: TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        Text(
          'Karta vur:  $_hits / $kHitsNeeded',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _intensity,
              minHeight: 5,
              backgroundColor: AppTheme.border.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(_accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _apologyMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        _apologyMsg,
        style: const TextStyle(
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

  /// Salınan sopa + vuruş patlaması.
  Widget _batWidget() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _bat,
          builder: (context, _) {
            final t = _bat.value;
            final swing = sin(t * pi); // 0→1→0
            final angle = -0.5 + 1.2 * swing; // havadan aşağı iner
            return Stack(
              children: [
                // Vuruş patlaması (son vuruş noktasında)
                if (t > 0 && t < 1 && !_defeated)
                  Positioned(
                    left: _lastHit.dx - 30,
                    top: _lastHit.dy - 30,
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.6 + swing * 0.9,
                        child: const Text('💥',
                            style: TextStyle(fontSize: 52)),
                      ),
                    ),
                  ),
                // Sopa (sağ alt köşede salınır)
                Positioned(
                  right: 6,
                  bottom: 8,
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomRight,
                    child: _batArt(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Sopa görseli: PNG (AppConfig.batImage) varsa onu, yoksa 🏏 emojisini.
  Widget _batArt() {
    if (AppConfig.batImage.isEmpty) {
      return const Text('🏏', style: TextStyle(fontSize: 76));
    }
    return Image.asset(
      AppConfig.batImage,
      height: AppConfig.batSize,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Text('🏏', style: TextStyle(fontSize: 76)),
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

/// Vuruş noktalarından yayılan cam çatlağı efekti.
class _CrackPainter extends CustomPainter {
  final List<Offset> points;
  _CrackPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final faint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (final p in points) {
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
          canvas.drawLine(cur, next, faint);
          canvas.drawLine(cur, next, line);
          cur = next;
        }
        ends.add(cur);
      }
      // Halka (örümcek ağı) bağlantıları
      for (var i = 0; i < ends.length; i++) {
        if (rnd.nextBool()) {
          final a = Offset.lerp(p, ends[i], 0.55)!;
          final b = Offset.lerp(p, ends[(i + 1) % ends.length], 0.55)!;
          canvas.drawLine(a, b, line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CrackPainter old) => old.points.length != points.length;
}

/// Yoğunluğa (0..1) göre harfleri dağıtan metin. Kelimeler satırda bütün
/// kalır; her harf ayrı ayrı uçar.
class _ShatterText extends StatelessWidget {
  final String text;
  final double intensity;
  const _ShatterText({required this.text, required this.intensity});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 19,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    );

    if (intensity <= 0) {
      return Text(text, style: style);
    }

    final words = text.split(' ');
    var charIndex = 0;
    return Wrap(
      spacing: 7,
      runSpacing: 2,
      children: [
        for (final word in words)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final ch in word.split(''))
                _ShatterChar(
                  ch: ch,
                  seed: charIndex++,
                  intensity: intensity,
                  style: style,
                ),
            ],
          ),
      ],
    );
  }
}

class _ShatterChar extends StatelessWidget {
  final String ch;
  final int seed;
  final double intensity;
  final TextStyle style;
  const _ShatterChar({
    required this.ch,
    required this.seed,
    required this.intensity,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final rnd = Random(seed * 9973 + ch.codeUnitAt(0));
    final dirX = rnd.nextDouble() * 2 - 1;
    final dirY = rnd.nextDouble() * 2 - 1;
    final rot = (rnd.nextDouble() * 2 - 1);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      tween: Tween(end: intensity),
      builder: (context, v, child) {
        final dx = dirX * 46 * v;
        final dy = dirY * 26 * v + v * v * 34; // hafifçe aşağı düşsün
        return Opacity(
          opacity: (1 - v * 0.85).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(angle: rot * 1.1 * v, child: child),
          ),
        );
      },
      child: Text(ch, style: style),
    );
  }
}

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
