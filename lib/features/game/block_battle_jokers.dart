import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/services/sfx_service.dart';
import '../../core/widgets/pixel_logo.dart';
import '../../core/widgets/pixel_text.dart';
import 'block_battle_core.dart';
import 'block_battle_session.dart';
import 'block_blast_engine.dart';
import 'salt_sprite.dart';

/// 1v1 jokerleri: maç öncesi seçim ekranı, oyundaki joker düğmesi,
/// genişletme çarkı ve dondurma/genişletme/tuz efektleri.

const kJokerFreeze = [
  '................',
  '..kkkkkkkkkkkk..',
  '.kWWWBBBBBBBBBk.',
  '.kWBBBBBWBBBBnk.',
  '.kWBBWBBWBBWBnk.',
  '.kBBBBWBWBWBBnk.',
  '.kBBBBBWWWBBBnk.',
  '.kBBWWWWWWWWBnk.',
  '.kBBBBBWWWBBBnk.',
  '.kBBBBWBWBWBBnk.',
  '.kBBBWBBWBBWBnk.',
  '.kBBBBBBWBBBbnk.',
  '.kBbBBBBBBBbbnk.',
  '.knnnnnnnnnnnnk.',
  '..kkkkkkkkkkkk..',
  '................',
];

const kJokerExpand = [
  'kkkkk......kkkkk',
  'kYYYk......kYYYk',
  'kYkk........kkYk',
  'kYk..........kYk',
  'kk..kkkkkkkk..kk',
  '....kbbbbbbk....',
  '....kbBBBBbk....',
  '....kbBWBBbk....',
  '....kbBBBBbk....',
  '....kbBBBBbk....',
  '....kbbbbbbk....',
  'kk..kkkkkkkk..kk',
  'kYk..........kYk',
  'kYkk........kkYk',
  'kYYYk......kYYYk',
  'kkkkk......kkkkk',
];

/// Yansıt: el aynası.
const kJokerReflect = [
  '....kkkkkkkk....',
  '...kVVVVVVVVk...',
  '..kVvvvvvvvvVk..',
  '..kVvBWBBBBvVk..',
  '..kVvWBBBBBvVk..',
  '..kVvBBBBBBvVk..',
  '..kVvBBBBBWvVk..',
  '..kVvBBBBWBvVk..',
  '..kVvBBBWBBvVk..',
  '..kVvBBBBBBvVk..',
  '..kVvvvvvvvvVk..',
  '...kVVVVVVVVk...',
  '....kkkmmkkk....',
  '......kmmk......',
  '......kmmk......',
  '......kkkk......',
];

const kJokerCoin = [
  '.....kkkkkk.....',
  '...kkYYYYYYkk...',
  '..kYYyyyyyyyyk..',
  '.kYyyyyyyyyyydk.',
  '.kYyyyyYyyyyydk.',
  'kYyyyyYYYyyyyydk',
  'kYyyYYYYYYYyyydk',
  'kYyyyYYYYYyyyydk',
  'kYyyyYYyYYyyyydk',
  'kYyyYYyyyYYyyydk',
  'kYyyyyyyyyyyyddk',
  '.kyyyyyyyyyyydk.',
  '.kyyyyyyyyyyddk.',
  '..kyyyyyyyyddk..',
  '...kkddddddkk...',
  '.....kkkkkk.....',
];

/// Altı kollu piksel kar tanesi (15×15).
final List<String> kSnowflake = () {
  final g = List.generate(15, (_) => List.filled(15, '.'));
  void dot(int x, int y) {
    if (x >= 0 && x < 15 && y >= 0 && y < 15) g[y][x] = 'W';
  }

  for (var d = 0; d <= 6; d++) {
    dot(7 + d, 7);
    dot(7 - d, 7);
    dot(7, 7 + d);
    dot(7, 7 - d);
    if (d <= 4) {
      dot(7 + d, 7 + d);
      dot(7 - d, 7 - d);
      dot(7 + d, 7 - d);
      dot(7 - d, 7 + d);
    }
  }
  // Kolların ucunda V dallar.
  for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
    final x = 7 + dx * 4, y = 7 + dy * 4;
    dot(x + dx + dy, y + dy + dx);
    dot(x + dx - dy, y + dy - dx);
  }
  g[7][7] = 'B';
  return [for (final row in g) row.join()];
}();

const jokerNames = {
  'freeze': 'DONDURMA',
  'expand': 'GENİŞLETME',
  'reflect': 'YANSIT',
  'salt': 'BİLLUR TUZ',
};
const jokerEffects = {
  'freeze': 'Rakibin tahtası 8 sn donar',
  'expand': 'Tahtan seçtiğin köşeye doğru 15 sn 9×9 olur',
  'reflect': '30 sn rakibin jokeri ona döner. Rakip görmez',
  'salt': 'Rakibin tahtasının ortasına 20 sn tuzluk',
};
const jokerLabels = {
  'freeze': 'DONDUR',
  'expand': 'GENİŞLET',
  'reflect': 'YANSIT',
  'salt': 'TUZLA',
};
const jokerColors = {
  'freeze': _ice,
  'expand': _gold,
  'reflect': Color(0xFFDCC8FF),
  'salt': Color(0xFF7FD3F0),
};
const cornerNames = {
  'tl': 'SOL ÜST',
  'tr': 'SAĞ ÜST',
  'bl': 'SOL ALT',
  'br': 'SAĞ ALT',
};

class JokerSprite extends StatelessWidget {
  const JokerSprite(this.kind, {super.key, this.size = 32, this.dim = false});
  final String kind;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final logo = switch (kind) {
      'freeze' => PixelLogo(kJokerFreeze, size: size),
      'reflect' => PixelLogo(kJokerReflect, size: size),
      'salt' => PixelLogo(kSaltSprite, size: size, palette: kSaltPalette),
      _ => PixelLogo(kJokerExpand, size: size),
    };
    return dim
        ? Opacity(
            opacity: .35,
            child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  .33, .33, .33, 0, 0, //
                  .33, .33, .33, 0, 0, //
                  .33, .33, .33, 0, 0, //
                  0, 0, 0, 1, 0,
                ]),
                child: logo))
        : logo;
  }
}

const _gold = Color(0xFFFFD36A);
const _ink = Color(0xFF070F1E);
const _panel = Color(0xFF101F3B);
const _edge = Color(0xFF3A5C92);
const _ice = Color(0xFFA9D6FF);

// ── Maç öncesi seçim ──

/// Yazı-tura ilk seçeni belirler (sunucu, yarı yarıya); sırası gelen oyuncu
/// 15 saniye içinde jokerini seçer, diğerine kalan verilir.
class BattleDraft extends StatefulWidget {
  const BattleDraft({super.key, required this.session});
  final BlockBattleSession session;

  @override
  State<BattleDraft> createState() => _BattleDraftState();
}

class _BattleDraftState extends State<BattleDraft>
    with SingleTickerProviderStateMixin {
  static const _coinMs = 1700;
  late final Ticker _ticker;
  int _ms = 0, _lastTick = -1;
  bool _landed = false, _sending = false;
  late final bool _skipCoin;

  BlockBattleSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    final end = s.state?['draftEnd'] as int? ?? s.now;
    // Seçime geç katılan (yenileme) yazı-turayı yeniden izlemez.
    _skipCoin = end - s.now < draftMs - _coinMs - 400 ||
        s.players.any((p) => s.jokersOf(p).isNotEmpty);
    _landed = _skipCoin;
    _ticker = createTicker((elapsed) {
      _ms = elapsed.inMilliseconds;
      if (!_landed && _ms >= _coinMs) {
        _landed = true;
        SfxService.instance.coin();
        HapticFeedback.mediumImpact();
      }
      // Sıra sendeyken son 5 saniye tıklar.
      final left = _secondsLeft;
      if (_landed && s.turn == s.me && left <= 5 && left != _lastTick) {
        _lastTick = left;
        if (left > 0) SfxService.instance.tick(rate: left <= 2 ? 1.3 : 1);
      }
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _landed = true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  int get _secondsLeft {
    final end = s.state?['draftEnd'] as int? ?? s.now;
    return max(0, ((end - s.now) / 1000).ceil());
  }

  String _name(int? id) =>
      s.players.where((p) => p['id'] == id).firstOrNull?['name'] as String? ??
      '?';

  Future<void> _pick(String kind) async {
    if (_sending) return;
    _sending = true;
    SfxService.instance.tick(rate: .8);
    HapticFeedback.selectionClick();
    await s.pickJoker(kind);
    _sending = false;
  }

  @override
  Widget build(BuildContext context) {
    final picker = s.state?['picker'] as int?;
    final turn = s.turn;
    final owners = {
      for (final p in s.players)
        for (final k in s.jokersOf(p)) k: p['id'] as int
    };
    final mineCount = s.myJokers.length;
    final done = turn == null;
    final status = !_landed
        ? 'YAZI TURA'
        : done
            ? 'MAÇ BAŞLIYOR'
            : turn == s.me
                ? 'SIRA SENDE · ${mineCount + 1}. JOKERİNİ SEÇ'
                : '${_name(turn)} SEÇİYOR';
    return LayoutBuilder(builder: (context, c) {
      final card = min(160.0, (c.maxWidth - 44) / 2);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Column(
            key: const ValueKey('joker-draft'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PixelText('JOKER SEÇİMİ', px: 3),
              const SizedBox(height: 18),
              _coin(picker),
              const SizedBox(height: 14),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _landed ? 1 : 0,
                child: Column(children: [
                  const Text('İLK SEÇİM',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54)),
                  const SizedBox(height: 4),
                  PixelText(_name(picker),
                      key: const ValueKey('draft-picker'),
                      color: picker == s.me ? _gold : Colors.white,
                      px: 3),
                ]),
              ),
              const SizedBox(height: 14),
              _timer(done),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final kind in jokerKinds)
                    _card(kind, card, owners[kind],
                        _landed && turn == s.me && owners[kind] == null),
                ],
              ),
              const SizedBox(height: 14),
              Text(status,
                  key: const ValueKey('draft-status'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                      color: turn == s.me && _landed ? _gold : Colors.white70)),
            ],
          ),
        ),
      );
    });
  }

  /// Dönen jeton: yarım turlarda iki oyuncunun adı değişir, ilk seçende durur.
  Widget _coin(int? picker) {
    final t = _landed ? 1.0 : min(1.0, _ms / _coinMs);
    // 8 yarım tur: son yüz ilk seçeni gösterir.
    final angle = Curves.easeOutCubic.transform(t) * pi * 8;
    final face = (angle / pi).floor().isEven;
    final other =
        s.players.where((p) => p['id'] != picker).firstOrNull?['id'] as int?;
    final shown = face ? picker : other;
    final lift = sin(t * pi) * 26;
    return SizedBox(
      height: 96,
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Transform.translate(
          offset: Offset(0, -lift),
          child: Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.diagonal3Values(max(.06, cos(angle).abs()), 1, 1),
            child: const PixelLogo(kJokerCoin, size: 64),
          ),
        ),
        const SizedBox(height: 6),
        if (!_landed)
          Text(_name(shown),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white60)),
      ]),
    );
  }

  Widget _timer(bool done) {
    final end = s.state?['draftEnd'] as int? ?? s.now;
    final left = max(0, end - s.now);
    final secs = _secondsLeft;
    final hot = !done && secs <= 5;
    return Column(key: const ValueKey('draft-timer'), children: [
      PixelText(done ? 'HAZIR' : '$secs',
          color: hot ? const Color(0xFFFF8B85) : Colors.white, px: 4),
      const SizedBox(height: 8),
      Container(
        width: 220,
        height: 10,
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _ink, width: 2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: done ? 1 : (left / draftMs).clamp(0.0, 1.0),
          child: Container(color: hot ? const Color(0xFFFF8B85) : _gold),
        ),
      ),
    ]);
  }

  Widget _card(String kind, double width, int? owner, bool selectable) {
    final mine = owner == s.me;
    final taken = owner != null;
    final pulse = selectable ? (sin(_ms / 140) + 1) / 2 : 0.0;
    final border = mine
        ? _gold
        : taken
            ? const Color(0xFF26324A)
            : selectable
                ? Color.lerp(_edge, _gold, pulse)!
                : _edge;
    return GestureDetector(
      key: ValueKey('joker-card-$kind'),
      onTap: selectable ? () => _pick(kind) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: mine ? 1.06 : 1,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFF2A2410) : _panel,
            border: Border.all(color: border, width: 3),
            boxShadow: [
              const BoxShadow(color: _ink, offset: Offset(0, 5)),
              if (selectable)
                BoxShadow(
                    color: _gold.withValues(alpha: .25 * pulse),
                    blurRadius: 14,
                    spreadRadius: 1),
            ],
          ),
          child: Column(children: [
            JokerSprite(kind, size: 44, dim: taken && !mine),
            const SizedBox(height: 8),
            FittedBox(
                child: PixelText(jokerNames[kind]!,
                    color: jokerColors[kind]!, px: 2)),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: Center(
                child: Text(jokerEffects[kind]!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 10.5, height: 1.25, color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: taken
                  ? Text(mine ? 'SENİN' : _name(owner),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: mine ? _gold : Colors.white38))
                  : selectable
                      ? const Text('SEÇ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: _gold))
                      : null,
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Oyun içi joker düğmesi ──

/// Oyuncunun jokeri. Dondurma, yansıt, tuz: dokun. Genişletme: basılı tut,
/// çarkta bir köşeye kaydır ve bırak (ya da dokun, sonra köşeye dokun).
class JokerButton extends StatefulWidget {
  const JokerButton({
    super.key,
    required this.session,
    required this.kind,
    required this.onTap,
    required this.onExpandDown,
    required this.onExpandMove,
    required this.onExpandUp,
  });

  final BlockBattleSession session;
  final String kind;
  final VoidCallback onTap;
  final ValueChanged<Offset> onExpandDown, onExpandMove;
  final VoidCallback onExpandUp;

  @override
  State<JokerButton> createState() => _JokerButtonState();
}

class _JokerButtonState extends State<JokerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  int? _pointer;
  Offset _down = Offset.zero;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final kind = widget.kind;
    final used = s.jokerUsed(s.mine, kind);
    final ready = s.jokerReady(kind);
    final urgent = ready && s.stuck && kind == 'expand';
    // Kullanılmış ama etkisi süren joker (yalnız kendi ekranında).
    final active = switch (kind) {
      'reflect' => s.effectLeft('reflectUntil'),
      'expand' => s.effectLeft('expandUntil'),
      _ => null,
    };
    if (ready && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
    return Listener(
      key: ValueKey('battle-joker-$kind'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (!ready || _pointer != null) return;
        _pointer = e.pointer;
        _down = e.position;
        if (kind == 'expand') widget.onExpandDown(e.position);
      },
      onPointerMove: (e) {
        if (e.pointer != _pointer || kind != 'expand') return;
        widget.onExpandMove(e.position);
      },
      onPointerUp: (e) {
        if (e.pointer != _pointer) return;
        _pointer = null;
        if (kind == 'expand') {
          widget.onExpandUp();
        } else if ((e.position - _down).distance < 24) {
          widget.onTap();
        }
      },
      onPointerCancel: (e) {
        if (e.pointer != _pointer) return;
        _pointer = null;
        if (kind == 'expand') widget.onExpandUp();
      },
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          final accent = urgent
              ? Color.lerp(const Color(0xFFFF5C5C), _gold, t)!
              : jokerColors[kind] ?? _gold;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    used && active == null ? const Color(0xFF0B1426) : _panel,
                border: Border.all(
                    color: ready
                        ? Color.lerp(_edge, accent, .4 + .6 * t)!
                        : active != null
                            ? accent
                            : const Color(0xFF26324A),
                    width: 3),
                boxShadow: [
                  const BoxShadow(color: _ink, offset: Offset(0, 4)),
                  if (ready)
                    BoxShadow(
                        color: accent.withValues(alpha: .18 + .3 * t),
                        blurRadius: 10 + 6 * t),
                ],
              ),
              child: Stack(alignment: Alignment.center, children: [
                Transform.scale(
                    scale: ready ? 1 + .06 * t : 1,
                    child: JokerSprite(kind,
                        size: 26, dim: !ready && active == null)),
                if (used && active == null)
                  const Icon(Icons.close_rounded,
                      size: 26, color: Color(0xAAFF8B85)),
              ]),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    active != null
                        ? '${kind == 'expand' ? '9×9' : 'AKTİF'} · ${(active / 1000).ceil()}'
                        : used
                            ? 'KULLANILDI'
                            : jokerLabels[kind] ?? '',
                    key: ValueKey('battle-joker-label-$kind'),
                    style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                        color:
                            ready || active != null ? accent : Colors.white38)),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Genişletme çarkı ──

/// Silah seçme çarkı gibi dört bölme: hangi köşe seçilirse tahta o yöne
/// büyür. [selected] parmağın yönüne göre ekran tarafından verilir.
class ExpandWheel extends StatelessWidget {
  const ExpandWheel(
      {super.key,
      required this.size,
      required this.selected,
      required this.onTapCorner,
      required this.onCancel,
      this.seconds});

  final double size;
  final String? selected;

  /// Takılıyken köşe seçmek için kalan saniye (süre dolunca tahta gider).
  final int? seconds;
  final ValueChanged<String> onTapCorner;
  final VoidCallback onCancel;

  static const _angles = {
    'tl': -3 * pi / 4,
    'tr': -pi / 4,
    'br': pi / 4,
    'bl': 3 * pi / 4
  };

  /// Çark merkezine göre konumdan köşe; merkez göbekte ya da dışarıda null.
  static String? cornerAt(Offset fromCenter, double radius,
      {double outer = 1.15}) {
    final d = fromCenter.distance;
    if (d < radius * .3 || d > radius * outer) return null;
    return (fromCenter.dy < 0 ? 't' : 'b') + (fromCenter.dx < 0 ? 'l' : 'r');
  }

  @override
  Widget build(BuildContext context) {
    final r = size / 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .7, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        key: const ValueKey('expand-wheel'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final corner = cornerAt(d.localPosition - Offset(r, r), r);
          corner == null ? onCancel() : onTapCorner(corner);
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(children: [
            Positioned.fill(
                child: CustomPaint(painter: _WheelPainter(selected))),
            for (final e in _angles.entries)
              Positioned(
                left: r + cos(e.value) * r * .67 - 50,
                top: r + sin(e.value) * r * .67 + r * .13,
                width: 100,
                child: Center(
                  child: PixelText(cornerNames[e.key]!,
                      key: ValueKey('wheel-${e.key}'),
                      color: selected == e.key ? _ink : Colors.white,
                      px: max(1.0, (size / 170).floorToDouble())),
                ),
              ),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                JokerSprite('expand', size: r * .32),
                const SizedBox(height: 4),
                Text(selected == null ? 'KÖŞE SEÇ' : 'BIRAK',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: _gold)),
                if (seconds != null)
                  Text('$seconds',
                      key: const ValueKey('wheel-seconds'),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF8B85))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.selected);
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2, center = Offset(r, r);
    final inner = r * .34;
    const gap = .07;
    for (final e in ExpandWheel._angles.entries) {
      final on = e.key == selected;
      final outer = on ? r : r * .95;
      final start = e.value - pi / 4 + gap / 2, sweep = pi / 2 - gap;
      final path = Path()
        ..arcTo(
            Rect.fromCircle(center: center, radius: outer), start, sweep, true)
        ..arcTo(Rect.fromCircle(center: center, radius: inner), start + sweep,
            -sweep, false)
        ..close();
      canvas.drawPath(path.shift(const Offset(0, 5)), Paint()..color = _ink);
      canvas.drawPath(
          path, Paint()..color = on ? _gold : const Color(0xEE101F3B));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = on ? const Color(0xFFFFF3B0) : _edge);
      // Bölmedeki küçük tahta: yeni satır ve sütun parlak.
      final mid = center +
          Offset(cos(e.value), sin(e.value)) * r * .67 -
          Offset(0, r * .06);
      final cell = (r * .034).floorToDouble().clamp(2.0, 9.0);
      final top = e.key[0] == 't', left = e.key[1] == 'l';
      final origin = mid - Offset(cell * 4.5, cell * 4.5);
      final paint = Paint()..isAntiAlias = false;
      for (var y = 0; y < 9; y++) {
        for (var x = 0; x < 9; x++) {
          final fresh = (top ? y == 0 : y == 8) || (left ? x == 0 : x == 8);
          paint.color = fresh
              ? (on ? const Color(0xFFB0261E) : _gold)
              : (on ? const Color(0xFF8A6A1C) : const Color(0xFF4F86D6));
          canvas.drawRect(
              Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell,
                  cell - 1, cell - 1),
              paint);
        }
      }
    }
    canvas.drawCircle(
        center, inner - 6, Paint()..color = const Color(0xFF0B1630));
    canvas.drawCircle(
        center,
        inner - 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _gold);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.selected != selected;
}

// ── Efektler ──

/// Genişleyen tahtada yeni satır ve sütun köşeden başlayarak yanar.
class ExpandFlashPainter extends CustomPainter {
  ExpandFlashPainter(this.t, this.corner, this.n) : super();
  final double t; // 0..1 (900 ms)
  final String corner;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    final row = corner[0] == 't' ? 0 : n - 1,
        col = corner[1] == 'l' ? 0 : n - 1;
    final ms = t * 900;
    final paint = Paint()..isAntiAlias = false;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (r != row && c != col) continue;
        final order = (r - row).abs() + (c - col).abs();
        final u = ((ms - order * 40) / 520).clamp(0.0, 1.0);
        if (u <= 0 || u >= 1) continue;
        final grow = Curves.easeOutBack.transform(min(1, u * 3));
        final rect = Rect.fromCenter(
            center: Offset((c + .5) * cell, (r + .5) * cell),
            width: cell * grow,
            height: cell * grow);
        final fade = 1 - Curves.easeInQuad.transform(u);
        paint.color = Color.lerp(Colors.white, _gold, min(1, u * 1.4))!
            .withValues(alpha: fade);
        canvas.drawRect(rect.deflate(cell * .08), paint);
        // Piksel kıvılcım: hücrenin köşelerinden dışa.
        final spark = cell * (.2 + .5 * u);
        final px = max(2.0, (cell / 10).roundToDouble());
        paint.color = Colors.white.withValues(alpha: fade);
        for (final d in const [
          Offset(-1, -1),
          Offset(1, -1),
          Offset(-1, 1),
          Offset(1, 1)
        ]) {
          canvas.drawRect(
              Rect.fromCenter(
                  center: rect.center + d * spark, width: px, height: px),
              paint);
        }
      }
    }
    // Çerçeve parlaması.
    canvas.drawRect(
        (Offset.zero & size).deflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = _gold.withValues(alpha: (1 - t) * .9));
  }

  @override
  bool shouldRepaint(ExpandFlashPainter old) => old.t != t;
}

/// Donmuş tahta: buz kenarlardan içeri yayılır, ortada kar tanesi ve kalan
/// saniye; süre bitince buz parçalanıp dağılır.
class FreezeOverlay extends StatefulWidget {
  const FreezeOverlay(
      {super.key, required this.until, required this.now, required this.n});
  final int until, now, n;

  @override
  State<FreezeOverlay> createState() => _FreezeOverlayState();
}

class _FreezeOverlayState extends State<FreezeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final int _total;

  @override
  void initState() {
    super.initState();
    _total = max(1, widget.until - widget.now);
    _c = AnimationController(
        vsync: this, duration: Duration(milliseconds: _total + 450))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * (_total + 450);
            final left = ((_total - ms) / 1000).ceil();
            return Stack(fit: StackFit.expand, children: [
              CustomPaint(
                  painter: _FrostPainter(ms, _total.toDouble(), widget.n)),
              if (ms < _total)
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Transform.rotate(
                        angle: ms / 2400,
                        child: PixelLogo(kSnowflake, size: 72)),
                    const SizedBox(height: 8),
                    const PixelText('DONDUN', color: Colors.white, px: 3),
                    const SizedBox(height: 6),
                    PixelText('$left',
                        key: const ValueKey('freeze-left'), color: _ice, px: 4),
                  ]),
                ),
            ]);
          },
        ),
      );
}

class _FrostPainter extends CustomPainter {
  _FrostPainter(this.ms, this.total, this.n);
  final double ms, total;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    final paint = Paint()..isAntiAlias = false;
    final rng = Random(7);
    final px = max(2.0, (cell / 9).roundToDouble());
    final melting = ms > total;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final edge = min(min(r, c), min(n - 1 - r, n - 1 - c));
        final seed = rng.nextDouble();
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        if (!melting) {
          final grow = ((ms - edge * 55) / 140).clamp(0.0, 1.0);
          if (grow <= 0) continue;
          paint.color = const Color(0xFFBFE6FF).withValues(alpha: .42 * grow);
          canvas.drawRect(rect, paint);
          // Kristal pikselleri.
          paint.color = Colors.white.withValues(alpha: .75 * grow);
          canvas.drawRect(
              Rect.fromLTWH(rect.left + px, rect.top + px, px * 2, px), paint);
          canvas.drawRect(
              Rect.fromLTWH(rect.left + px, rect.top + px * 2, px, px), paint);
          if (seed > .55) {
            canvas.drawRect(
                Rect.fromLTWH(
                    rect.right - px * 3, rect.bottom - px * 3, px, px),
                paint);
          }
        } else {
          // Parçalanma: buz kareleri dışarı savrulup düşer.
          final u = ((ms - total) / 450).clamp(0.0, 1.0);
          final dir = Offset(c - (n - 1) / 2, r - (n - 1) / 2);
          final fly = dir * cell * .35 * u + Offset(0, cell * 1.6 * u * u);
          final side = cell * (.5 - .3 * u) * (.7 + seed * .6);
          paint.color = const Color(0xFFD7F0FF).withValues(alpha: 1 - u);
          canvas.drawRect(
              Rect.fromCenter(
                  center: rect.center + fly, width: side, height: side),
              paint);
        }
      }
    }
    if (!melting) {
      canvas.drawRect(
          (Offset.zero & size).deflate(2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = _ice.withValues(alpha: min(1, ms / 200)));
    }
  }

  @override
  bool shouldRepaint(_FrostPainter old) => old.ms != ms;
}

/// Fırlatılan buz küpü ya da tuzluk: joker düğmesinden rakibin tahtasına yay
/// çizerek döner; arkasında kar/tuz pikselleri bırakır, çarpınca dağılır.
class IceProjectile extends StatefulWidget {
  const IceProjectile(
      {super.key,
      required this.from,
      required this.to,
      required this.onDone,
      this.kind = 'freeze'});
  final Offset from, to;
  final String kind;
  final VoidCallback onDone;

  @override
  State<IceProjectile> createState() => _IceProjectileState();
}

class _IceProjectileState extends State<IceProjectile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 760))
    ..forward().whenComplete(() {
      if (mounted) widget.onDone();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _at(double t) {
    final a = widget.from, b = widget.to;
    final peak = Offset((a.dx + b.dx) / 2, min(a.dy, b.dy) - 70);
    return a * (1 - t) * (1 - t) + peak * 2 * t * (1 - t) + b * t * t;
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final flight = min(1.0, _c.value / .6);
            final burst = ((_c.value - .6) / .4).clamp(0.0, 1.0);
            final pos = _at(Curves.easeIn.transform(flight));
            return CustomPaint(
              size: Size.infinite,
              painter: _ProjectilePainter(
                  [for (var i = 1; i <= 6; i++) _at(max(0, flight - i * .05))],
                  burst > 0 ? widget.to : null,
                  burst),
              child: burst > 0
                  ? const SizedBox.expand()
                  : Stack(children: [
                      Positioned(
                        left: pos.dx - 15,
                        top: pos.dy - 15,
                        child: Transform.rotate(
                            angle: flight * pi * 3,
                            child: JokerSprite(widget.kind, size: 30)),
                      ),
                    ]),
            );
          },
        ),
      );
}

class _ProjectilePainter extends CustomPainter {
  _ProjectilePainter(this.trail, this.hit, this.burst);
  final List<Offset> trail;
  final Offset? hit;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    if (hit == null) {
      for (var i = 0; i < trail.length; i++) {
        final side = 6.0 - i * .8;
        paint.color = Colors.white.withValues(alpha: .7 - i * .1);
        canvas.drawRect(
            Rect.fromCenter(center: trail[i], width: side, height: side),
            paint);
      }
      return;
    }
    final rng = Random(3);
    for (var i = 0; i < 18; i++) {
      final a = i / 18 * pi * 2 + rng.nextDouble() * .3;
      final d = 8 +
          46 *
              Curves.easeOutCubic.transform(burst) *
              (.6 + rng.nextDouble() * .6);
      final side = (6 * (1 - burst)).roundToDouble() + 1;
      paint.color =
          (i.isEven ? Colors.white : _ice).withValues(alpha: 1 - burst);
      canvas.drawRect(
          Rect.fromCenter(
              center: hit! + Offset(cos(a), sin(a)) * d,
              width: side,
              height: side),
          paint);
    }
  }

  @override
  bool shouldRepaint(_ProjectilePainter old) => true;
}

// ── Billur tuz ──

/// Tahtadaki billur tuz hücrelerini (sütunda üst üste) tek bir piksel
/// tuzluk olarak çizer. [inset]: hücre kenar boşluğu.
void paintSalt(Canvas canvas, List<List<int?>> grid, double cell,
    {double inset = 1}) {
  const salt = BlockBlastEngine.saltCell;
  final n = grid.length;
  for (var c = 0; c < n; c++) {
    for (var r = 0; r < n; r++) {
      if (grid[r][c] != salt) continue;
      var end = r;
      while (end + 1 < n && grid[end + 1][c] == salt) {
        end++;
      }
      _paintSaltSprite(
          canvas,
          Rect.fromLTWH(c * cell + inset, r * cell + inset, cell - 2 * inset,
              (end - r + 1) * cell - 2 * inset));
      r = end;
    }
  }
}

void _paintSaltSprite(Canvas canvas, Rect box) {
  final rows = kSaltSprite.length, cols = kSaltSprite.first.length;
  final px = min(box.width / cols, box.height / rows);
  final origin = box.center - Offset(cols * px, rows * px) / 2;
  final paint = Paint()..isAntiAlias = false;
  for (var y = 0; y < rows; y++) {
    final row = kSaltSprite[y];
    for (var x = 0; x < cols; x++) {
      final ch = row[x];
      if (ch == '.') continue;
      paint.color = kSaltPalette[ch]!;
      canvas.drawRect(
          Rect.fromLTWH(
              origin.dx + x * px, origin.dy + y * px, px + .35, px + .35),
          paint);
    }
  }
}
