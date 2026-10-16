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
    'L': 0xD9A066,
    'w': 0xF4ECE0,  # kağıt
    'a': 0x6B6F80,
    'A': 0xB8BCC8,
    'S': 0xF6CBA4,  # ten
    'h': 0x4A2618,  # koyu kahve saç
    'u': 0x6E4A2E,  # kahve saç
    'M': 0x8E2350,  # bordo
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


# ── Şekil yardımcıları: dolguyu çiz, kontur otomatik eklensin ──

import math


def rot_rect(g, cx, cy, length, width, ang, ch):
    """Ekseni `ang` derece (ekran koordinatı, y aşağı) olan dikdörtgen."""
    c, s_ = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    for y in range(len(g)):
        for x in range(len(g[0])):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            u, v = dx * c + dy * s_, -dx * s_ + dy * c
            if abs(u) <= length / 2 and abs(v) <= width / 2:
                g[y][x] = ch


def rot_ellipse(g, cx, cy, a, b, ang, ch):
    c, s_ = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    for y in range(len(g)):
        for x in range(len(g[0])):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            u, v = dx * c + dy * s_, -dx * s_ + dy * c
            if (u / a) ** 2 + (v / b) ** 2 <= 1:
                g[y][x] = ch


def disk(g, cx, cy, r, ch):
    for y in range(len(g)):
        for x in range(len(g[0])):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                g[y][x] = ch


def outlined(rows):
    """1 piksellik kenar boşluğu ekler ve dolgunun çevresine 'k' kontur çizer."""
    w, h = len(rows[0]) + 2, len(rows) + 2
    g = [['.'] * w for _ in range(h)]
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.':
                g[y + 1][x + 1] = ch
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] != '.':
                continue
            if any(0 <= y + dy < h and 0 <= x + dx < w and g[y + dy][x + dx] not in '.k'
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[y][x] = 'k'
    return rows_of(out)


# ── Hukuk ──

def gavel():
    g = grid(15, 15)
    rot_rect(g, 9.2, 9.2, 8, 1.8, 45, 'L')          # sap
    rot_rect(g, 5, 5, 8, 4.2, -45, 'l')             # baş
    rot_rect(g, 5, 5, 8, 1.4, -45, 'L')             # parlama
    for t in (-3, 3):
        rot_rect(g, 5 + t * 0.707, 5 - t * 0.707, 1.4, 4.6, -45, 'y')
    for x in range(7, 15):
        g[13][x] = 'L'
        g[14][x] = 'l'
    return outlined(rows_of(g))


def law_book():
    return outlined([
        'mqqqqqqqqqq',
        'mqyyyyyyyyq',
        'mqyqqqqqqyq',
        'mqyqqyyqqyq',
        'mqyqyqqqqyq',
        'mqyqqyyqqyq',
        'mqyqyqqyqyq',
        'mqyqqyyqqyq',
        'mqyqqqqyqyq',
        'mqyqqyyqqyq',
        'mqyqqqqqqyq',
        'mqyyyyyyyyq',
        'mqqqqqqqqqq',
        'mwwwwwwwwwq',
    ])


def courthouse():
    return outlined([
        '.......Y.......',
        '......YyY......',
        '....YYyyyYY....',
        '..YYyyyyyyyYY..',
        'YYYYYYYYYYYYYYY',
        'ddddddddddddddd',
        '.AC.AC...AC.AC.',
        '.AC.AC...AC.AC.',
        '.AC.AClllAC.AC.',
        '.AC.AClllAC.AC.',
        '.AC.AClllAC.AC.',
        'YYYYYYYYYYYYYYY',
        'ddddddddddddddd',
    ])


def petition():
    return outlined([
        'wwwwwwwwwww',
        'waaaaaaaaaw',
        'wwwwwwwwwww',
        'waaaaaaawww',
        'wwwwwwwwwww',
        'waaaaaaaaaw',
        'wwwwwwwwwww',
        'waaaaawwwww',
        'wwwwwwwwwww',
        'wwwwwwrrrww',
        'wwwwwrRrrrw',
        'wwwwwrrrrrw',
        'wwwwwwrrrww',
        '......r.r..',
        '.....r...r.',
    ])


def briefcase():
    return outlined([
        '.....llll.....',
        '....l....l....',
        'LLLLLLLLLLLLLL',
        'llllllllllllll',
        'llllllyylllll' + 'l',
        'dddddyYYyddddd',
        'llllllyyllllll',
        'llllllllllllll',
        'llllllllllllll',
        'llllllllllllll',
        'dddddddddddddd',
    ])


def quill():
    g = grid(14, 15)
    for x in range(0, 6):
        for y in range(11, 15):
            g[y][x] = 'n'
    for x in range(1, 5):
        g[10][x] = 'a'
    g[11][1] = 'b'
    rot_ellipse(g, 8.8, 5.2, 6.6, 2.9, -45, 'W')
    rot_ellipse(g, 9.6, 4.4, 4.0, 1.6, -45, 'C')
    rot_rect(g, 8.4, 5.6, 10, 0.8, -45, 'A')
    rot_rect(g, 3.6, 10.4, 3.4, 1.0, -45, 'a')
    return outlined(rows_of(g))


# ── Oyun ──

def trophy():
    return outlined([
        '..YYYYYYYYY..',
        'yyYyyyyyyydyy',
        'y.Yyyyyyyyd.y',
        'y.Yyyyyyyyd.y',
        '.yYyyyyyyydy.',
        '...Yyyyyyd...',
        '....yyyyd....',
        '.....yyd.....',
        '.....Yyd.....',
        '.....yyd.....',
        '...ddddddd...',
        '..lllllllll..',
        '..LLLLLLLLL..',
    ])


def coin():
    g = grid(12, 12)
    disk(g, 6, 6, 6, 'd')
    disk(g, 5.6, 5.6, 5.2, 'y')
    disk(g, 6, 6, 3.6, 'Y')
    disk(g, 6.2, 6.2, 3.0, 'y')
    for y in range(3, 9):
        g[y][5] = 'd'
        g[y][6] = 'd'
    g[3][4] = g[4][4] = 'W'
    return outlined(rows_of(g))


def crown():
    return outlined([
        'Y.....Y.....Y',
        'yy...yYy...yy',
        'yyy.yyyyy.yyy',
        'yyyyyyyyyyyyy',
        'yyryyybyyyryy',
        'yyyyyyyyyyyyy',
        'ddddddddddddd',
    ])


def joystick():
    return outlined([
        '....rrr....',
        '...rRrrr...',
        '...rrrrr...',
        '....rrr....',
        '.....a.....',
        '.....a.....',
        '.....a.....',
        '..AAAAAAA..',
        '.AAAAAAAAA.',
        'aaaaaaaaaaa',
        'sssssssssss',
    ])


def arcade():
    return outlined([
        '.vvvvvvvvv.',
        'vVVVVVVVVVv',
        'vVyyyyyyyVv',
        'vvvvvvvvvvv',
        'vkkkkkkkkkv',
        'vkbBbbbgbkv',
        'vkbbbybbbkv',
        'vkbbbbbbbkv',
        'vkkkkkkkkkv',
        'mmmmmmmmmmm',
        'mmammmrmbmm',
        'vvvvvvvvvvv',
        'vvvvyyyvvvv',
        'vvvvvvvvvvv',
        'vvvvvvvvvvv',
        'mmmmmmmmmmm',
    ])


def dice():
    return outlined([
        '.WWWWWWWWWW.',
        'WWWWWWWWWWWC',
        'WWkkWWWWkkWC',
        'WWkkWWWWkkWC',
        'WWWWWWWWWWWC',
        'WWWWWkkWWWWC',
        'WWWWWkkWWWWC',
        'WWWWWWWWWWWC',
        'WWkkWWWWkkWC',
        'WWkkWWWWkkWC',
        'WWWWWWWWWWWC',
        '.CCCCCCCCCC.',
    ])


def sword():
    g = grid(15, 15)
    rot_rect(g, 9.0, 6.0, 12, 2.4, -45, 'C')
    rot_rect(g, 9.4, 5.6, 12, 0.9, -45, 'W')
    rot_rect(g, 3.9, 11.1, 6, 1.6, 45, 'y')
    rot_rect(g, 2.6, 12.4, 3.2, 1.6, -45, 'l')
    disk(g, 1.2, 13.8, 1.2, 'y')
    return outlined(rows_of(g))


def gem():
    return outlined([
        '..BBBBBBB..',
        '.BWBBbBBbb.',
        'BWBBbbbBbbn',
        'bbbbbbbbbnn',
        '.bbbbbbbnn.',
        '..bbbbbnn..',
        '...bbbnn...',
        '....bnn....',
        '.....n.....',
    ])


def alien():
    return outlined([
        '.G.......G.',
        '..g.....g..',
        '...ggggg...',
        '..gGggggg..',
        '.gkkgggkkg.',
        '.gkWgggkWg.',
        '.ggggggggg.',
        '..ggkkkgg..',
        '...ggggg...',
    ])


def potion():
    return outlined([
        '...lll...',
        '...lll...',
        '...CCC...',
        '...CWC...',
        '..CCCCC..',
        '.CWCCCCC.',
        'CWpppPppC',
        'CppppppqC',
        'CpPppppqC',
        'CppppppqC',
        '.CppppqC.',
        '..CCCCC..',
    ])


def plane():
    # Sağa uçan pembe uçak (kavuşma sayacı).
    return outlined([
        '.Pp...............',
        '.Ppp..............',
        '.pppp.............',
        'PPPPPPPPPPPPPPPP..',
        'pppBBpBBpBBpBBppb.',
        'ppppppppppppppppbb',
        'qqqqqqqqqqqqqqqqq.',
        '.qqqqqqqqqqqqqqq..',
        '........PPPq......',
        '......PPPq........',
    ])


def couple():
    # Sarılan çift: solda erkek (kısa saç, mavi tişört), sağda kız (uzun saç,
    # pembe elbise, fiyonk). Başlar birbirine yaslı, kollar birbirine sarılı.
    return outlined([
        '.......r.r........',
        '.......rrr........',
        '........r.........',
        '..................',
        '...uuuu....pp.....',
        '..uuuuuu.hhpphh...',
        '..uSSSSu.hhhhhhh..',
        '..SSkSSS.hSSSShhh.',
        '..SSSSRS.RSkSSShh.',
        '...SSSS...SSSShhh.',
        '..bbbbbSSSpppphhh.',
        '.bbbbbbSSppppppphh',
        '.bSbbbbbbppppppShh',
        '.bSbbbbbbpppppppSh',
        '.bbbbbbb.ppppppppp',
        '..nnnnnn.ppppppppp',
        '..nn..nn..SS...SS.',
        '..kk..kk..kk...kk.',
    ])


def pin(color, light):
    return outlined([
        '.' + light * 2 + color * 2 + '.',
        light + color * 4 + 'q' if color == 'p' else light + color * 4 + 'n',
        color * 5 + ('q' if color == 'p' else 'n'),
        '.' + color * 3 + ('q' if color == 'p' else 'n') + '.',
        '...a..',
        '...a..',
    ])


def bow():
    return outlined([
        'pp.....pp',
        'pPp...pPp',
        'ppppqpppp',
        'pPppqppPp',
        'pp..q..pp',
        '...q.q...',
        '..q...q..',
    ])


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
    'gavel': gavel(),
    'lawBook': law_book(),
    'courthouse': courthouse(),
    'petition': petition(),
    'briefcase': briefcase(),
    'quill': quill(),
    'trophy': trophy(),
    'coin': coin(),
    'crown': crown(),
    'joystick': joystick(),
    'arcade': arcade(),
    'dice': dice(),
    'sword': sword(),
    'gem': gem(),
    'alien': alien(),
    'potion': potion(),
    'plane': plane(),
    'couple': couple(),
    'pinPink': pin('p', 'P'),
    'pinBlue': pin('b', 'B'),
    'bow': bow(),
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
        px, per = 10, 8
        nrows = -(-len(tiles) // per)
        sheet = Image.new('RGBA', (per * 20 * px, nrows * 20 * px), (0x29, 0x15, 0x21, 255))
        for i, (_, rows) in enumerate(tiles):
            render(rows, px, sheet, (i % per) * 20 * px + px, (i // per) * 20 * px + px)
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
