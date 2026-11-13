import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pixel_logo.dart';

/// Haftalık meydan okumanın kupaları. Her hafta sıradaki tasarım ödüldür
/// (hafta numarası mod 7; sunucudaki `TROPHIES` ile aynı sıra ve adlar).
/// Sprite'lar [kLogoPalette] harfleriyle çizilir ('.' = boş).
class WeeklyTrophy {
  const WeeklyTrophy(this.name, this.sprite, this.color, this.dark);

  final String name;
  final List<String> sprite;

  /// Rozet çerçevesinin rengi ve gölgesi.
  final Color color, dark;
}

const kWeeklyTrophies = [
  WeeklyTrophy('Altın Kupa', _cup, Color(0xFFFFD36A), Color(0xFF8A5A14)),
  WeeklyTrophy('Yıldız Kupası', _star, Color(0xFF4FA3FF), Color(0xFF1D3F7A)),
  WeeklyTrophy('Kalp Kupası', _heart, Color(0xFFFF80AB), Color(0xFF8C1D4A)),
  WeeklyTrophy('Taç Kupası', _crown, Color(0xFFB48CFF), Color(0xFF4A2A8C)),
  WeeklyTrophy('Elmas Kupa', _gem, Color(0xFFA9D6FF), Color(0xFF2A5BA8)),
  WeeklyTrophy('Şimşek Kupası', _bolt, Color(0xFFFF9A3C), Color(0xFF8A3A10)),
  WeeklyTrophy('Tokmak Kupası', _gavel, Color(0xFF45D6A0), Color(0xFF14573F)),
];

WeeklyTrophy weeklyTrophy(int index) =>
    kWeeklyTrophies[index % kWeeklyTrophies.length];

const _cup = [
  '...kkkkkkkkk...',
  '.kkYYYYYYYYYkk.',
  'kyyYyyyyyyydyyk',
  'kykYyyWyyyydkyk',
  'kykYyWyyyyydkyk',
  '.kyYyyyyyyydyk.',
  '..kkYyyyyydkk..',
  '....kyyyydk....',
  '.....kyydk.....',
  '.....kYydk.....',
  '....kkyydkk....',
  '...kdddddddk...',
  '..klllllllllk..',
  '..kLLLLLLLLLk..',
  '...kkkkkkkkk...',
];

const _star = [
  '.......k.......',
  '......kYk......',
  '.....kYyyk.....',
  'kkkkkkYyyykkkkk',
  'kYYYyyyyyyyyydk',
  '.kyyyWyyyyyydk.',
  '..kyyyyyyyydk..',
  '..kyyyyyyyydk..',
  '.kyyyydkdyyydk.',
  '.kyydk...kyydk.',
  '.kkkk.....kkkk.',
  '...kkkkkkkkk...',
  '..kBBBBBBBBBk..',
  '..knnnnnnnnnk..',
  '...kkkkkkkkk...',
];

const _heart = [
  '..kkk.....kkk..',
  '.kPppk...kpppk.',
  'kPWpppk.kpppppk',
  'kPpppppkppppppk',
  'kpppppppppppqqk',
  'kppppppppppppqk',
  '.kppppppppppqk.',
  '..kppppppppqk..',
  '...kppppppqk...',
  '....kppppqk....',
  '.....kppqk.....',
  '......kqk......',
  '...kkkkkkkkk...',
  '..kMMMMMMMMMk..',
  '...kkkkkkkkk...',
];

const _crown = [
  '.k.....k.....k.',
  'kYk...kYk...kYk',
  'kyyk.kyYyk.kyyk',
  'kyyykyyyyykyyyk',
  'kyYyyyyyyyyyyyk',
  'kyyryyybyyyryyk',
  'kyyyyyyyyyyyyyk',
  'kdddddddddddddk',
  '.kkkkkkkkkkkkk.',
  '.kVvvvvvvvvvmk.',
  'kVvvvvvvvvvvvmk',
  'kmmmmmmmmmmmmmk',
  '.kkkkkkkkkkkkk.',
];

const _gem = [
  '...kkkkkkkkk...',
  '..kBBBWBBbbnk..',
  '.kBBWkBBbkbbnk.',
  'kBBBkBBBbbkbbnk',
  'kkkkkkkkkkkkkkk',
  'kbbbbkbbbkbbnnk',
  '.kbbbkbbbkbnnk.',
  '..kbbbkbkbnnk..',
  '...kbbkbknnk...',
  '....kbbbnnk....',
  '.....kbnnk.....',
  '......knk......',
  '...kkkkkkkkk...',
  '..kCCCCCCCCCk..',
  '..kAAAAAAAAAk..',
  '...kkkkkkkkk...',
];

const _bolt = [
  '.......kkkkkk..',
  '......kYYyyk...',
  '.....kYyyyk....',
  '....kYyyyk.....',
  '...kYyyykkkkk..',
  '..kYyyyyyyyyk..',
  '..kkkkkyyyok...',
  '......kyyok....',
  '.....kyyok.....',
  '....kyook......',
  '...kyok........',
  '...kkk.........',
  '...kkkkkkkkk...',
  '..koooooooook..',
  '..krrrrrrrrrk..',
  '...kkkkkkkkk...',
];

const _gavel = [
  '....kk.........',
  '...kyyk........',
  '...klyyk.......',
  '..kllLyyk......',
  'kkllLllyk......',
  'kyllLllkk......',
  'kyyLllLLk......',
  '.kyylkLLLk.....',
  '..kyykkLLLk....',
  '...kk..kLLLk...',
  '........kLLLk..',
  '.........kLLk..',
  '...kkkkkkkkk...',
  '..kGGGGGGGGGk..',
  '..keeeeeeeeek..',
  '...kkkkkkkkk...',
];

/// Kupa rozeti: sert gölgeli piksel çerçeve içinde kupa. [won] değilse
/// (henüz kazanılmamış) soluk ve gri.
class TrophyBadge extends StatelessWidget {
  const TrophyBadge({
    super.key,
    required this.trophy,
    this.size = 64,
    this.won = true,
    this.count = 0,
  });

  final WeeklyTrophy trophy;
  final double size;
  final bool won;

  /// Aynı kupadan birden fazla kazanıldıysa köşede "×2".
  final int count;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(
        color: won
            ? Color.alphaBlend(
                trophy.color.withValues(alpha: .16), AppTheme.surface)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(size * .12),
        border: Border.all(
            color: won ? trophy.color : AppTheme.border,
            width: size >= 56 ? 2 : 1.5),
        boxShadow: [
          BoxShadow(
              color: won ? trophy.dark : const Color(0xFF0B0408),
              offset: Offset(size >= 56 ? 3 : 2, size >= 56 ? 3 : 2)),
        ],
      ),
      child: Opacity(
        opacity: won ? 1 : .28,
        child: PixelLogo(trophy.sprite, size: size * .72),
      ),
    );
    if (count < 2) return badge;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        badge,
        Positioned(
          right: -5,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: trophy.dark,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: trophy.color, width: 1),
            ),
            child: Text('×$count',
                style: const TextStyle(
                    fontFamily: AppTheme.pixelFont,
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
