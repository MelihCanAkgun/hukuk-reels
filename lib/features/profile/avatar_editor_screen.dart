import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pixel_logo.dart';
import '../game/arcade/arcade_sprites.dart';
import '../surprise/pixel_sprites.dart';
import '../../core/widgets/pressable.dart';

typedef _Sticker = (List<String>, Map<String, Color>);

/// Sprite'ın boş (saydam) kenarlarını kırpar; çıkartma kutusu çizime otursun.
List<String> _trim(List<String> rows) {
  bool emptyRow(String r) => !r.split('').any((c) => c != '.');
  var top = 0, bottom = rows.length;
  while (top < bottom && emptyRow(rows[top])) {
    top++;
  }
  while (bottom > top && emptyRow(rows[bottom - 1])) {
    bottom--;
  }
  final body = rows.sublist(top, bottom);
  if (body.isEmpty) return rows;
  var left = body.first.length, right = 0;
  for (final r in body) {
    for (var x = 0; x < r.length; x++) {
      if (r[x] != '.') {
        if (x < left) left = x;
        if (x + 1 > right) right = x + 1;
      }
    }
  }
  return [for (final r in body) r.substring(left, right)];
}

/// Fotoğrafa eklenebilen piksel-art çıkartmalar, gruplar hâlinde.
final List<(String, List<_Sticker>)> kAvatarStickerGroups = [
  (
    'Hukuk',
    [
      (kLogoQuestionBank, kLogoPalette),
      (kLogoGavel, kLogoPalette),
      (kLogoLawBook, kLogoPalette),
      (kLogoCourthouse, kLogoPalette),
      (kLogoPetition, kLogoPalette),
      (kLogoBriefcase, kLogoPalette),
      (kLogoQuill, kLogoPalette),
    ]
  ),
  (
    'Oyun',
    [
      (kLogoTrophy, kLogoPalette),
      (kLogoCrown, kLogoPalette),
      (kLogoCoin, kLogoPalette),
      (kLogoGem, kLogoPalette),
      (kLogoJoystick, kLogoPalette),
      (kLogoArcade, kLogoPalette),
      (kLogoGames, kLogoPalette),
      (kLogoDice, kLogoPalette),
      (kLogoSword, kLogoPalette),
      (kLogoPotion, kLogoPalette),
      (kLogoAlien, kLogoPalette),
      (kLogoBlockBlast, kLogoPalette),
      (kLogoBattle, kLogoPalette),
      (kLogoFlappyCat, kLogoPalette),
      (kLogoSubwaySilly, kLogoPalette),
    ]
  ),
  (
    'Arcade',
    [
      (_trim(kSprFlappyCatUp), kArcadePalette),
      (_trim(kSprFlappyCatMid), kArcadePalette),
      (_trim(kSprFlappyCatDead), kArcadePalette),
      (_trim(kSprGoldFish0), kArcadePalette),
      (_trim(kSprMedalBronze), kArcadePalette),
      (_trim(kSprMedalSilver), kArcadePalette),
      (_trim(kSprMedalGold), kArcadePalette),
      (_trim(kSprMedalPlatinum), kArcadePalette),
      (_trim(kSprCloud), kArcadePalette),
      (_trim(kSprPipeCap), kArcadePalette),
      (_trim(kSprGroundTile), kArcadePalette),
      (_trim(kSprRunner0), kArcadePalette),
      (_trim(kSprRunnerJump), kArcadePalette),
      (_trim(kSprRunnerSlide), kArcadePalette),
      (_trim(kSprGuard0), kArcadePalette),
      (_trim(kSprTrainPink), kArcadePalette),
      (_trim(kSprTrainBlue), kArcadePalette),
      (_trim(kSprTrainMint), kArcadePalette),
      (_trim(kSprBarrier), kArcadePalette),
      (_trim(kSprHighBar), kArcadePalette),
      (_trim(kSprCoin0), kArcadePalette),
      (_trim(kSprMagnet), kArcadePalette),
      (_trim(kSprSneaker), kArcadePalette),
      (_trim(kSprDouble), kArcadePalette),
      (_trim(kSprHeart), kArcadePalette),
    ]
  ),
  (
    'Sevimli',
    [
      (kLogoHeart, kLogoPalette),
      (kLogoStar, kLogoPalette),
      (kLogoTulip, kLogoPalette),
      (kLogoPlane, kLogoPalette),
      (kLoveFaceSprite, kSpritePalette),
      (kBurstSprite, kSpritePalette),
      (kBatSprite, kSpritePalette),
    ]
  ),
];

class _Placed {
  _Placed(this.rows, this.palette, this.center, this.size);
  final List<String> rows;
  final Map<String, Color> palette;
  Offset center; // çerçeveye göre 0..1
  double size; // çerçeve kenarına oranla kutu kenarı
  double angle = 0; // radyan, saat yönünde
}

/// Profil fotoğrafı düzenleyici: fotoğrafı kare çerçevede kaydır /
/// yakınlaştır, piksel çıkartma ekle, taşı ve boyutlandır. Sonuç, tam
/// çözünürlükte çizim için bir "spec" haritası olarak döner (çizim JS'de).
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({
    super.key,
    required this.preview,
    required this.srcWidth,
    required this.srcHeight,
    this.admin = false,
  });

  final Uint8List preview;
  final int srcWidth;
  final int srcHeight;

  /// Oyuncu 1: indirme / çözünürlük bilgileri yalnız ona gösterilir.
  final bool admin;

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  static const _minZoom = 0.4, _maxZoom = 5.0;
  static const _minSticker = 0.06, _maxSticker = 1.0;
  static const _corners = [
    Offset(0.15, 0.15),
    Offset(0.85, 0.15),
    Offset(0.15, 0.85),
    Offset(0.85, 0.85),
  ];

  late final ImageProvider _image = MemoryImage(widget.preview);
  double _zoom = 1;
  Offset _center = const Offset(0.5, 0.5);
  final List<_Placed> _stickers = [];
  int? _sel;
  double _frame = 1;

  // Hareket başlangıcı
  int? _target; // çıkartma indeksi; -1 = fotoğraf
  Offset _focal0 = Offset.zero;
  double _zoom0 = 1, _size0 = 0, _angle0 = 0;
  int _group = 0;
  Offset _center0 = Offset.zero;

  double get _minSide =>
      (widget.srcWidth < widget.srcHeight ? widget.srcWidth : widget.srcHeight)
          .toDouble();
  Size get _imgSize => Size(
      widget.srcWidth / _minSide * _zoom, widget.srcHeight / _minSide * _zoom);

  Offset _clampCenter(Offset c) {
    final s = _imgSize;
    double axis(double v, double len) {
      final lo = len >= 1 ? 1 - len / 2 : len / 2;
      final hi = len >= 1 ? len / 2 : 1 - len / 2;
      return v.clamp(lo, hi).toDouble();
    }

    return Offset(axis(c.dx, s.width), axis(c.dy, s.height));
  }

  int? _hit(Offset p) {
    for (var i = _stickers.length - 1; i >= 0; i--) {
      final s = _stickers[i];
      final half = s.size / 2 + 0.02;
      // Noktayı çıkartmanın kendi (döndürülmemiş) eksenine çevir.
      final d = p - s.center;
      final c = math.cos(-s.angle), sn = math.sin(-s.angle);
      final lx = d.dx * c - d.dy * sn, ly = d.dx * sn + d.dy * c;
      if (lx.abs() <= half && ly.abs() <= half) {
        return i;
      }
    }
    return null;
  }

  void _onScaleStart(ScaleStartDetails d) {
    final p = d.localFocalPoint / _frame;
    final hit = _hit(p);
    _focal0 = p;
    if (hit != null) {
      // Dokunulan çıkartma öne gelir.
      final s = _stickers.removeAt(hit);
      _stickers.add(s);
      _target = _stickers.length - 1;
      _center0 = s.center;
      _size0 = s.size;
      _angle0 = s.angle;
      setState(() => _sel = _target);
    } else {
      _target = -1;
      _center0 = _center;
      _zoom0 = _zoom;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final t = _target;
    if (t == null) return;
    final p = d.localFocalPoint / _frame;
    final delta = p - _focal0;
    setState(() {
      if (t >= 0) {
        final s = _stickers[t];
        s.size = (_size0 * d.scale).clamp(_minSticker, _maxSticker).toDouble();
        // İki parmakla çevirince döner.
        if (d.pointerCount > 1) s.angle = _wrap(_angle0 + d.rotation);
        final c = _center0 + delta;
        s.center = Offset(c.dx.clamp(0.0, 1.0), c.dy.clamp(0.0, 1.0));
      } else {
        _zoom = (_zoom0 * d.scale).clamp(_minZoom, _maxZoom).toDouble();
        // Parmakların ortası sabit kalacak şekilde yakınlaştır.
        final k = _zoom / _zoom0;
        _center = _clampCenter(_focal0 + (_center0 - _focal0) * k + delta);
      }
    });
  }

  static double _wrap(double a) {
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a < -math.pi) {
      a += 2 * math.pi;
    }
    return a;
  }

  void _setAngle(double a) {
    final sel = _sel;
    if (sel == null) return;
    // Düz konuma yakınsa tam düz yap.
    setState(() => _stickers[sel].angle = a.abs() < 0.06 ? 0 : _wrap(a));
  }

  void _addSticker(_Sticker sticker) {
    final (rows, palette) = sticker;
    final used = _stickers.map((s) => s.center).toSet();
    final spot = _corners.firstWhere((c) => !used.contains(c),
        orElse: () => const Offset(0.5, 0.5));
    setState(() {
      _stickers.add(_Placed(rows, palette, spot, 0.24));
      _sel = _stickers.length - 1;
    });
  }

  void _setSize(double v) {
    setState(() {
      final sel = _sel;
      if (sel != null) {
        _stickers[sel].size = v;
      } else {
        final old = _zoom;
        _zoom = v;
        // Çerçeve ortası sabit kalsın.
        const mid = Offset(0.5, 0.5);
        _center = _clampCenter(mid + (_center - mid) * (_zoom / old));
      }
    });
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Map<String, dynamic> _spec() {
    final s = _imgSize;
    return {
      // Çerçevedeki doğal piksel sayısı: fotoğraf büyütülmez, küçültülmez.
      'out': (_minSide / _zoom).round(),
      'bg': _hex(AppTheme.bg),
      'img': {
        'x': _center.dx - s.width / 2,
        'y': _center.dy - s.height / 2,
        'w': s.width,
        'h': s.height,
      },
      'stickers': [
        for (final st in _stickers)
          {
            'rows': st.rows,
            'palette': {
              for (final e in st.palette.entries) e.key: _hex(e.value)
            },
            'x': st.center.dx - st.size / 2,
            'y': st.center.dy - st.size / 2,
            'size': st.size,
            'rot': st.angle,
          }
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final sel = _sel;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Fotoğrafı düzenle',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_spec()),
              child: const Text('Kaydet'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final side = (c.maxWidth - 32 < c.maxHeight - 16
                        ? c.maxWidth - 32
                        : c.maxHeight - 16)
                    .clamp(120.0, 560.0);
                _frame = side;
                return Center(child: _frameView(side));
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                sel != null
                    ? 'Çıkartmayı sürükle; iki parmakla ya da kaydırıcılarla '
                        'boyutlandır ve döndür.'
                    : widget.admin
                        ? 'Fotoğrafı sürükle ve iki parmakla yakınlaştır. Kırpma yalnız '
                            'profil içindir; indirilen fotoğraf orijinal boyutunda '
                            '(${widget.srcWidth}×${widget.srcHeight} px) kalır.'
                        : 'Fotoğrafı sürükle ve iki parmakla yakınlaştır. Daire içi '
                            'profilde görünür.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  Icon(
                      sel != null
                          ? Icons.photo_size_select_small_rounded
                          : Icons.zoom_in_rounded,
                      color: AppTheme.textSecondary,
                      size: 20),
                  Expanded(
                    child: Slider(
                      value: sel != null ? _stickers[sel].size : _zoom,
                      min: sel != null ? _minSticker : _minZoom,
                      max: sel != null ? _maxSticker : _maxZoom,
                      onChanged: _setSize,
                    ),
                  ),
                  if (sel != null) ...[
                    IconButton(
                      tooltip: 'Çıkartmayı sil',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.danger),
                      onPressed: () => setState(() {
                        _stickers.removeAt(sel);
                        _sel = null;
                      }),
                    ),
                    IconButton(
                      tooltip: 'Tamam',
                      icon: const Icon(Icons.check_rounded,
                          color: AppTheme.success),
                      onPressed: () => setState(() => _sel = null),
                    ),
                  ] else
                    IconButton(
                      tooltip: 'Fotoğrafı sıfırla',
                      icon: const Icon(Icons.restart_alt_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: () => setState(() {
                        _zoom = 1;
                        _center = const Offset(0.5, 0.5);
                      }),
                    ),
                ],
              ),
            ),
            if (sel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.rotate_right_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    Expanded(
                      child: Slider(
                        value: _stickers[sel].angle,
                        min: -math.pi,
                        max: math.pi,
                        onChanged: _setAngle,
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${(_stickers[sel].angle * 180 / math.pi).round()}°',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ),
                    IconButton(
                      tooltip: '90° döndür',
                      icon: const Icon(Icons.rotate_90_degrees_cw_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: () =>
                          _setAngle(_stickers[sel].angle + math.pi / 2),
                    ),
                  ],
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
              child: Row(
                children: [
                  for (var g = 0; g < kAvatarStickerGroups.length; g++) ...[
                    ChoiceChip(
                      label: Text(kAvatarStickerGroups[g].$1),
                      selected: _group == g,
                      onSelected: (_) => setState(() => _group = g),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 76,
              child: ListView.separated(
                key: ValueKey(_group),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                itemCount: kAvatarStickerGroups[_group].$2.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Semantics(
                  button: true,
                  label: 'Çıkartma ekle',
                  child: Pressable(
                    onTap: () =>
                        _addSticker(kAvatarStickerGroups[_group].$2[i]),
                    child: Container(
                      width: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: PixelLogo(kAvatarStickerGroups[_group].$2[i].$1,
                          size: 40,
                          palette: kAvatarStickerGroups[_group].$2[i].$2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frameView(double side) {
    final s = _imgSize;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: (_) => _target = null,
      onTapUp: (d) {
        final hit = _hit(d.localPosition / side);
        if (hit != _sel) setState(() => _sel = hit);
      },
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border.all(color: AppTheme.border),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: (_center.dx - s.width / 2) * side,
                top: (_center.dy - s.height / 2) * side,
                width: s.width * side,
                height: s.height * side,
                child: Image(
                  image: _image,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              for (var i = 0; i < _stickers.length; i++)
                Positioned(
                  left: (_stickers[i].center.dx - _stickers[i].size / 2) * side,
                  top: (_stickers[i].center.dy - _stickers[i].size / 2) * side,
                  width: _stickers[i].size * side,
                  height: _stickers[i].size * side,
                  child: Transform.rotate(
                    angle: _stickers[i].angle,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: i == _sel
                            ? Border.all(color: AppTheme.accent, width: 1.5)
                            : null,
                      ),
                      child: PixelLogo(_stickers[i].rows,
                          size: _stickers[i].size * side,
                          palette: _stickers[i].palette),
                    ),
                  ),
                ),
              // Profilde görünen daire (yalnız kılavuz, kaydedilmez).
              IgnorePointer(
                child: CustomPaint(
                  size: Size.square(side),
                  painter: _CircleGuidePainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawCircle(
      Offset(r, r),
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_CircleGuidePainter old) => false;
}
