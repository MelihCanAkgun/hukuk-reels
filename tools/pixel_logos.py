#!/usr/bin/env python3
"""Pixel-art logo üreticisi.

Tek kaynak: buradaki sprite'lar hem Flutter tarafına
(`lib/core/widgets/pixel_logo_data.dart`) hem de PWA ikon / splash
PNG'lerine (`web/icons/`) dönüştürülür.

    python3 tools/pixel_logos.py            # Dart + ikonlar
    python3 tools/pixel_logos.py --preview out.png
"""
import argparse
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# '.' = boş. Uygulamanın tozpembe / plum temasına uyumlu palet.
PALETTE = {
    'k': 0x2B1220,  # kontur
    'W': 0xFFFFFF,
    'p': 0xFF80AB,  # toz pembe (accent)
    'P': 0xFFC2D6,
    'q': 0xD63F78,
    'y': 0xFFD36A,  # altın
    'Y': 0xFFF3B0,
    'd': 0xC0892E,
    'b': 0x4FA3FF,
    'B': 0xA9D6FF,
    'n': 0x2A5BA8,
    'g': 0x45D6A0,
    'G': 0xA8F0D0,
    'e': 0x1E8A63,
    'o': 0xFF9A3C,
    'r': 0xED343D,
    'R': 0xFFAD9B,
    'c': 0x9C98A6,  # tekir kedi
    'C': 0xE4E0EA,
    's': 0x5C5866,
    'v': 0xB48CFF,
    'V': 0xDCC8FF,
    'm': 0x7A4FCF,
    'l': 0x8A5A3A,
}


def grid(w, h):
    return [['.'] * w for _ in range(h)]


def stamp(g, x0, y0, rows):
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != '.':
                g[y0 + y][x0 + x] = ch


def rows_of(g):
    return [''.join(r) for r in g]


def block(main, light, dark, size=8):
    """Kabartmalı tek blok (Block Blast parçası)."""
    s = size
    out = []
    for y in range(s):
        row = ''
        for x in range(s):
            if x in (0, s - 1) or y in (0, s - 1):
                row += 'k'
            elif y == 1 or x == 1:
                row += light if not (y == s - 2 and x == 1) else main
            elif y == s - 2 or x == s - 2:
                row += dark
            else:
                row += main
        out.append(row)
    out[2] = out[2][:2] + 'W' + out[2][3:]
    return out


# ───────────────────────── Sprite'lar ─────────────────────────

def block_blast():
    g = grid(16, 16)
    stamp(g, 0, 0, block('p', 'P', 'q'))
    stamp(g, 0, 8, block('b', 'B', 'n'))
    stamp(g, 8, 8, block('y', 'Y', 'd'))
    # boş köşede küçük parıltı
    stamp(g, 9, 1, [
        '..Y...',
        '..Y...',
        'YYWYY.',
        '..Y...',
        '..Y...',
    ])
    return rows_of(g)


CAT_FACE = [
    '.k.........k.',
    'kck.......kck',
    'kPck.....kcPk',
    'kPcckkkkkccPk',
    'kcccscscsccck',
    'kccccscscccck',
    'kccWkcccWkcck',
    'kcckkccckkcck',
    'kCCcccqcccCCk',
    '.kCCCkCkCCCk.',
    '..kCCCCCCCk..',
    '...kkkkkkk...',
]


def flappy_cat():
    g = grid(16, 16)
    stamp(g, 0, 3, CAT_FACE)
    # kanat (kafanın sağında, yukarı kalkık)
    stamp(g, 11, 4, [
        '.kk..',
        'kWWk.',
        'kWWWk',
        'kCWWk',
        'kCCWk',
        '.kkk.',
    ])
    # uçuş "whoosh"
    stamp(g, 14, 12, ['P.', '.P'])
    stamp(g, 0, 0, ['P...', '.P..'])
    return rows_of(g)


def subway_silly():
    g = grid(16, 16)
    stamp(g, 0, 0, [
        '..k.........k...',
        '.kpk.......kpk..',
        '.kPpkkkkkkkpPk..',
        'kbbbbbbbbbbbbbk.',
        'kbkkkkkkkkkkkbk.',
        'kbkBBBBBBBBBkbk.',
        'kbkBkWBBBkWBkbk.',
        'kbkBkkBqBkkBkbk.',
        'kbkBBBBBBBBBkbk.',
        'kbkkkkkkkkkkkbk.',
        'kbyybbbbbbbyybk.',
        'kbyybbbbbbbyybk.',
        'knnnnnnnnnnnnnk.',
        '.kkkkkkkkkkkkk..',
    ])
    # 16 genişlikte ortala, altına raylar
    out = ['.' + r[:-1] for r in rows_of(g)[:14]]
    return out + ['....c.......c...', '...clllllllllc..']


def battle():
    g = grid(16, 16)
    stamp(g, 0, 6, block('p', 'P', 'q', size=6))
    stamp(g, 10, 6, block('b', 'B', 'n', size=6))
    stamp(g, 4, 1, [
        '...kkkk',
        '..kyYYk',
        '..kyyk.',
        '.kyyk..',
        '.kyyYkk',
        'kyyyyyk',
        'kkkyyk.',
        '..kyyk.',
        '..kyk..',
        '.kyk...',
        '.kyk...',
        'kyk....',
        'kk.....',
    ])
    return rows_of(g)


def gamepad():
    # D-pad solda, düğmeler sağda (altın + mavi + yeşil).
    return [
        '..kkkkk..kkkkk..',
        '.kpppppkkpppppk.',
        'kpppkpppppppbppk',
        'kppkWkppppppkpPk',
        'kpkWWWkppppykgpk',
        'kppkWkppppppkpPk',
        'kpppkppppppppppk',
        'kpppppkkkkkpppqk',
        '.kqqqk.....kqqk.',
        '..kkk.......kk..',
    ]


def scales(letters=False):
    """Adalet terazisi. letters=True → kefelerde H ve R (uygulama ikonu)."""
    W, H = 25, 21
    g = grid(W, H)
    c = 12
    g[0][c] = 'Y'
    for x in (c - 1, c, c + 1):
        g[1][x] = 'y'
    g[1][c] = 'Y'
    for y in range(2, 18):
        g[y][c] = 'y'
    for y in range(2, 18):
        g[y][c + 1] = 'd' if y > 3 else g[y][c + 1]
    for x in range(3, 23):
        g[3][x] = 'Y'
        g[4][x] = 'd'
    g[3][c] = g[4][c] = 'y'
    g[3][c + 1] = 'Y'
    g[4][c + 1] = 'd'
    for hx in (4, 20):
        g[2][hx] = 'y'
        # zincirler
        offs = [(5, 0), (6, 1), (7, 1), (8, 2), (9, 2), (10, 3), (11, 3), (12, 4)]
        for y, o in offs:
            g[y][hx - o] = 'd'
            g[y][hx + o] = 'd'
        g[5][hx] = 'd'
        # kefe
        for x in range(hx - 4, hx + 5):
            g[13][x] = 'Y'
        for x in range(hx - 4, hx + 5):
            g[14][x] = 'y'
        for x in range(hx - 3, hx + 4):
            g[15][x] = 'd'
    if letters:
        H_ = ['p.p', 'p.p', 'ppp', 'p.p', 'p.p']
        R_ = ['pp.', 'p.p', 'pp.', 'p.p', 'p.p']
        for y in range(5):
            for x in range(3):
                for hx, L in ((4, H_), (20, R_)):
                    if L[y][x] != '.':
                        g[8 + y][hx - 1 + x] = 'q'
    # taban
    for x in range(c - 1, c + 3):
        g[17][x] = 'y'
    for x in range(c - 3, c + 5):
        g[18][x] = 'Y'
    for x in range(c - 5, c + 7):
        g[19][x] = 'y'
    for x in range(c - 5, c + 7):
        g[20][x] = 'd'
    return rows_of(g)


def scales_small():
    W = 15
    g = grid(W, 15)
    c = 7
    g[0][c] = 'Y'
    for y in range(1, 12):
        g[y][c] = 'y'
    for x in range(1, 14):
        g[2][x] = 'Y'
    g[2][c] = 'y'
    for hx in (3, 11):
        for y, o in ((3, 0), (4, 1), (5, 1), (6, 2), (7, 2)):
            g[y][hx - o] = 'd'
            g[y][hx + o] = 'd'
        for x in range(hx - 3, hx + 4):
            g[8][x] = 'Y'
        for x in range(hx - 2, hx + 3):
            g[9][x] = 'y'
        for x in range(hx - 1, hx + 2):
            g[10][x] = 'd'
    for x in range(c - 1, c + 2):
        g[12][x] = 'y'
    for x in range(c - 3, c + 4):
        g[13][x] = 'Y'
    for x in range(c - 4, c + 5):
        g[14][x] = 'd'
    return rows_of(g)


def tulip():
    return [
        '.kk.kkk.kk.',
        'kPpkpPpkppk',
        'kPppPpppppk',
        'kPpppppppqk',
        'kpppppppqqk',
        '.kpppppqqk.',
        '..kkqqqkk..',
        '....kgk....',
        '.kk.kgk....',
        'kGgkkgk.kk.',
        'kGggkgkkggk',
        '.kGggggggk.',
        '..kkkgkkk..',
        '....kgk....',
        '....kek....',
    ]


def heart():
    # 1v1 Battle can kalbi ile aynı biçim.
    return [
        '.kk...kk.',
        'krrkkkrrk'.replace('kkk', 'k.k'),
        'krRrkrrrk',
        'krrrrrrrk',
        '.krrrrrk.',
        '..krrrk..',
        '...krk...',
        '....k....',
    ]


def star():
    return [
        '....k....',
        '...kyk...',
        '...kYk...',
        'kkkyYykkk',
        'kYYyyyyyk',
        '.kyyyyyk.',
        '..kyyyk..',
        '.kyykyyk.',
        '.kyk.kyk.',
        'kkk...kkk',
    ]


SPRITES = {
    'blockBlast': block_blast(),
    'flappyCat': flappy_cat(),
    'subwaySilly': subway_silly(),
    'battle': battle(),
    'games': gamepad(),
    'questionBank': scales_small(),
    'tulip': tulip(),
    'heart': heart(),
    'star': star(),
}


def validate(name, rows):
    w = len(rows[0])
    for i, r in enumerate(rows):
        if len(r) != w:
            sys.exit(f'{name}: satır {i} genişliği {len(r)} != {w}')
        for ch in r:
            if ch != '.' and ch not in PALETTE:
                sys.exit(f'{name}: bilinmeyen renk {ch!r}')


# ───────────────────────── Çıktılar ─────────────────────────

def to_dart():
    lines = [
        '// GENERATED by tools/pixel_logos.py — elle düzenleme; scripti çalıştır.',
        "// Piksel-art logolar ('.' = boş).",
        "import 'dart:ui';",
        '',
        'const Map<String, Color> kLogoPalette = {',
    ]
    for k, v in PALETTE.items():
        lines.append(f"  '{k}': Color(0xFF{v:06X}),")
    lines += ['};', '']
    for name, rows in SPRITES.items():
        const = 'kLogo' + name[0].upper() + name[1:]
        lines.append(f'const List<String> {const} = [')
        for r in rows:
            lines.append(f"  '{r}',")
        lines += ['];', '']
    return '\n'.join(lines)


def rgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)


def render(rows, px, img=None, ox=0, oy=0):
    w, h = len(rows[0]), len(rows)
    if img is None:
        img = Image.new('RGBA', (w * px, h * px), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == '.':
                continue
            img.paste(rgb(PALETTE[ch]), (ox + x * px, oy + y * px,
                                         ox + (x + 1) * px, oy + (y + 1) * px))
    return img


ICON_BG_OUT = (0xF4, 0x9C, 0xBC, 255)
ICON_BG_IN = (0xFF, 0xC4, 0xD8, 255)


def app_icon_rows():
    """33x33 ızgara: pembe zemin, piksel altın halka, ortada H•R terazisi."""
    N = 33
    g = [['o_' for _ in range(N)] for _ in range(N)]
    c = 16
    for y in range(N):
        for x in range(N):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if d < 13.4:
                g[y][x] = 'i_'
            elif d < 14.5:
                g[y][x] = 'y'
    sc = scales(letters=True)
    for y, r in enumerate(sc):
        for x, ch in enumerate(r):
            if ch != '.':
                g[6 + y][4 + x] = ch
    return g


def render_icon(size):
    g = app_icon_rows()
    N = len(g)
    big = Image.new('RGBA', (N, N))
    for y in range(N):
        for x in range(N):
            ch = g[y][x]
            col = ICON_BG_OUT if ch == 'o_' else ICON_BG_IN if ch == 'i_' else rgb(PALETTE[ch])
            big.putpixel((x, y), col)
    # Tam sayı ölçekle keskin büyüt, sonra hedef boyuta (gerekirse) en yakın komşu.
    k = max(1, -(-size // N))
    big = big.resize((N * k, N * k), Image.NEAREST)
    return big.resize((size, size), Image.NEAREST)


def render_splash(w, h):
    img = Image.new('RGBA', (w, h), (0x17, 0x0B, 0x12, 255))
    px = max(4, round(min(w, h) * 0.34 / 25))
    sc = scales(letters=True)
    sw, sh = len(sc[0]) * px, len(sc) * px
    render(sc, px, img, (w - sw) // 2, (h - sh) // 2)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview')
    args = ap.parse_args()
    for n, r in SPRITES.items():
        validate(n, r)
    validate('scalesLetters', scales(letters=True))

    if args.preview:
        tiles = list(SPRITES.items())
        px = 12
        sheet = Image.new('RGBA', (len(tiles) * 18 * px + 520, 36 * px), (0x29, 0x15, 0x21, 255))
        x = px
        for _, rows in tiles:
            render(rows, px, sheet, x, px)
            x += (len(rows[0]) + 2) * px
        sheet.paste(render_icon(256), (x, px))
        sheet.paste(render_icon(32).resize((128, 128), Image.NEAREST), (x + 270, px))
        sheet.save(args.preview)
        print('preview →', args.preview)
        return

    out = os.path.join(ROOT, 'lib/core/widgets/pixel_logo_data.dart')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, 'w') as f:
        f.write(to_dart())
    print('dart →', out)

    icons = os.path.join(ROOT, 'web/icons')
    for s in (72, 96, 128, 144, 152, 167, 180, 192, 512):
        render_icon(s).save(os.path.join(icons, f'icon-{s}x{s}.png'), optimize=True)
    render_icon(32).save(os.path.join(icons, 'favicon.png'), optimize=True)
    for w, h in ((750, 1334), (1170, 2532), (1290, 2796), (1640, 2360)):
        render_splash(w, h).save(os.path.join(icons, f'splash-{w}x{h}.png'), optimize=True)
    print('icons →', icons)


if __name__ == '__main__':
    main()
