#!/usr/bin/env python3
"""Flappy Silly Cat + Subway Silly piksel-art sprite üreticisi.

Tek kaynak: sprite'lar burada (çoğu basit şekil yardımcılarıyla) çizilir,
`lib/features/game/arcade/arcade_sprites.dart` dosyasına yazılır.

    python3 tools/game_sprites.py                 # Dart verisi
    python3 tools/game_sprites.py --preview a.png # büyütülmüş önizleme
"""
import argparse
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART = os.path.join(ROOT, 'lib', 'features', 'game', 'arcade', 'arcade_sprites.dart')

# '.' = boş. Uygulamanın tozpembe / plum temasıyla uyumlu.
PALETTE = {
    'k': 0x2B1220,  # kontur
    'W': 0xFFFFFF,
    'p': 0xFF80AB,  # toz pembe
    'P': 0xFFC2D6,
    'q': 0xD63F78,
    'Q': 0x8E2350,
    'y': 0xFFD36A,  # altın
    'Y': 0xFFF3B0,
    'd': 0xC0892E,
    'D': 0x7F5418,
    'b': 0x4FA3FF,
    'B': 0xA9D6FF,
    'n': 0x2A5BA8,
    'N': 0x1B3A70,
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
    'a': 0x6B6F80,
    'A': 0xB8BCC8,
    'S': 0xF6CBA4,  # ten
    'h': 0x3A2418,
    'x': 0x1A0A14,  # göz bebeği / derin gölge
    'z': 0xC8C4D0,  # bronz yerine gümüş tonu
    'u': 0xCD7F32,  # bronz
    'U': 0xF0B27A,
    't': 0x3D2E1F,  # travers
}


# ───────────────────────── yardımcılar ─────────────────────────
def grid(w, h):
    return [['.'] * w for _ in range(h)]


def put(g, x, y, ch):
    if 0 <= y < len(g) and 0 <= x < len(g[0]):
        g[y][x] = ch


def rect(g, x, y, w, h, ch):
    for j in range(y, y + h):
        for i in range(x, x + w):
            put(g, i, j, ch)


def ellipse(g, cx, cy, rx, ry, ch, only=None):
    for j in range(len(g)):
        for i in range(len(g[0])):
            if ((i + 0.5 - cx) / rx) ** 2 + ((j + 0.5 - cy) / ry) ** 2 <= 1.0:
                if only is None or g[j][i] in only:
                    g[j][i] = ch


def stamp(g, x, y, rows):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != '.':
                put(g, x + i, y + j, ch)


def outline(g, ch='k'):
    """Dolu piksellere komşu boş piksellere kontur ekler (4-komşu)."""
    h, w = len(g), len(g[0])
    marks = []
    for j in range(h):
        for i in range(w):
            if g[j][i] != '.':
                continue
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ii, jj = i + di, j + dj
                if 0 <= ii < w and 0 <= jj < h and g[jj][ii] not in '.' + ch:
                    marks.append((i, j))
                    break
    for i, j in marks:
        g[j][i] = ch


def rows_of(g):
    return [''.join(r) for r in g]


def flip(rows):
    return [r[::-1] for r in rows]


def recolor(rows, mapping):
    return [''.join(mapping.get(c, c) for c in r) for r in rows]


# ───────────────────────── Flappy Silly Cat ─────────────────────────
# Melek kanadı: sola (geriye) uzanan tek bir elle çizilmiş kanat; çırpış
# kareleri bu kanadın omuz noktası etrafında döndürülmesiyle üretilir.
# Üst kenar öncü kenar, alt kenar dalgalı tüy uçları. 'C' tüy ayrımı.
ANGEL_WING = [
    '...........WWWW..',
    '........WWWWWWWWW',
    '.....WWWWWWWWWWWW',
    '...WWWCWWCWWCWWWW',
    '..WWCWWCWWCWWWWW.',
    '.WWWWWWWWWWWWWW..',
    'WWAWWAWWAWWAWW...',
    'WWAWWAWWAWWAW....',
    'CWACWACWACWA.....',
    '.A.CA.CA.CA......',
]
WING_PIVOT = (15.0, 2.5)  # omuz (kanat tuvalinde)

# Kanat açısı (derece; + = saat yönü, ekran koordinatı). 0 = düz geriye.
WING_ANGLES = {
    'up': 84,
    'upMid': 56,
    'mid': 28,
    'downMid': -2,
    'down': -32,
}


def rotate_wing(rows, deg, size=30, at=(19, 17)):
    """En-yakın-komşu döndürme: kanadın omzu tuvalde [at] noktasına gelir."""
    g = grid(size, size)
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    px, py = WING_PIVOT
    h, w = len(rows), len(rows[0])
    for j in range(size):
        for i in range(size):
            dx, dy = i + 0.5 - at[0], j + 0.5 - at[1]
            # ters döndürme (ekranda saat yönü pozitif açı)
            sx = dx * ca + dy * sa + px
            sy = -dx * sa + dy * ca + py
            si, sj = int(math.floor(sx)), int(math.floor(sy))
            if 0 <= si < w and 0 <= sj < h and rows[sj][si] != '.':
                g[j][i] = rows[sj][si]
    return g


def wing_frame(deg, back=False):
    g = rotate_wing(ANGEL_WING, deg)
    if back:  # arka kanat: daha koyu
        g = [[{'W': 'C', 'C': 'A', 'A': 'a'}.get(c, c) for c in r] for r in g]
    outline(g)
    return rows_of(g)


def flappy_cat(wing='mid', dead=False):
    """Melek kanatlı, haleli tekir kedi (sağa bakar)."""
    w, h = 40, 40
    ox, oy = 11, 12           # gövdenin tuvaldeki yeri
    g = grid(w, h)
    body = grid(26, 20)
    # kuyruk (solda, yukarı kıvrık)
    for (x, y) in [(2, 12), (2, 11), (1, 10), (1, 9), (1, 8), (2, 7), (3, 6), (2, 13), (3, 13)]:
        put(body, x, y, 'c')
    put(body, 3, 6, 's')
    put(body, 1, 9, 's')
    ellipse(body, 9.5, 12.0, 6.6, 4.6, 'c')
    ellipse(body, 10.5, 14.4, 4.6, 2.4, 'C', only='c')
    for x in (6, 9, 12):
        put(body, x, 8, 's')
        put(body, x, 9, 's')
    ellipse(body, 17.5, 9.0, 5.6, 5.2, 'c')
    ellipse(body, 18.5, 12.2, 3.8, 1.8, 'C', only='c')
    stamp(body, 12, 2, ['c...', 'cc..', 'cPc.', 'cPcc'])
    stamp(body, 19, 1, ['..c.', '.ccc', '.cPc', 'ccPc'])
    for x in (15, 17, 19):
        put(body, x, 4, 's')
        put(body, x, 5, 's')
    if dead:
        stamp(body, 14, 7, ['k.k', '.k.', 'k.k'])
        stamp(body, 19, 7, ['k.k', '.k.', 'k.k'])
        stamp(body, 16, 12, ['kkk'])
        put(body, 17, 13, 'r')
    else:
        stamp(body, 14, 6, ['xxx', 'xWx', 'xxx', '.x.'])
        stamp(body, 19, 6, ['xxx', 'xWx', 'xxx', '.x.'])
        put(body, 14, 6, 'W')
        put(body, 19, 6, 'W')
        stamp(body, 17, 10, ['qq', '.k'])
        stamp(body, 16, 12, ['k.k'])
        put(body, 17, 12, 'k')
    put(body, 13, 10, 'P')
    put(body, 22, 10, 'P')
    stamp(body, 15, 15, ['CC', 'CC'])
    stamp(body, 5, 15, ['CC', 'CC'])
    outline(body)
    stamp(g, ox, oy, rows_of(body))
    # hale (başın üstünde; ölünce eğilir)
    halo = ['.yyyyy.', 'yY...Yy', '.yyyyy.'] if not dead else \
           ['..yyy..', '.y..Yy.', '..yyy..']
    hg = grid(9, 5)
    stamp(hg, 1, 1, halo)
    outline(hg)
    stamp(g, ox + 13, oy - 6, rows_of(hg))
    deg = 64 if dead else WING_ANGLES[wing]
    # omuz: gövdenin sırtı (gövde koordinatı ~ (11, 8)); kanat tuvalinde (18, 16)
    sx, sy = ox + 11 - 19, oy + 7 - 17
    # arka kanat önce (biraz daha geride ve açıda), sonra gövde, sonra ön kanat
    out = grid(w, h)
    stamp(out, sx + 3, sy - 1, wing_frame(deg + 10, back=True))
    stamp(out, 0, 0, rows_of(g))
    stamp(out, sx, sy, wing_frame(deg))
    return rows_of(out)


def golden_fish(frame=0):
    body = [
        '.....yyyy....',
        '...yyYYyyy...',
        '.dyyYyyyyxy.y',
        'ddyyyyyyyyyyy',
        '.ddyyyyyyyy.y',
        '...ddddddd...',
    ] if frame == 0 else [
        '.....yyyy....',
        '...yyYYyyy...',
        '.dyyYyyyyxyy.',
        'ddyyyyyyyyyyy',
        '.ddyyyyyyyyy.',
        '...ddddddd...',
    ]
    # balık sağa baksın: ağız sağda, kuyruk solda
    g = grid(15, 8)
    stamp(g, 1, 1, flip(body))
    outline(g)
    return rows_of(g)


def medal(fill, light, dark):
    g = grid(16, 18)
    # kurdele
    stamp(g, 4, 0, ['qq....pp', '.qq..pp.', '..qqpp..', '...qp...'])
    ellipse(g, 8, 11, 6.5, 6.5, fill)
    ellipse(g, 8, 11, 4.5, 4.5, light)
    ellipse(g, 8.6, 11.6, 3.8, 3.8, fill)
    # yıldız
    stamp(g, 6, 8, ['..Y..', '.YYY.', 'YYYYY', '.YYY.', '.Y.Y.'])
    for (x, y) in [(3, 14), (4, 15), (5, 16), (12, 13), (13, 12)]:
        put(g, x, y, dark)
    outline(g)
    return rows_of(g)


def cloud(w=28, h=12, seed=0):
    g = grid(w, h)
    blobs = [(7, 7, 5, 4), (13, 5, 6, 5), (20, 7, 5, 4), (24, 8, 3.5, 3)]
    for (cx, cy, rx, ry) in blobs:
        ellipse(g, cx, cy, rx, ry, 'W')
    for j in range(h):
        for i in range(w):
            if g[j][i] == 'W' and (j >= h - 3):
                g[j][i] = 'C'
    rect(g, 0, h - 1, w, 1, '.')
    return rows_of(g)


def pipe_cap():
    w = 30
    row = 'k' + 'PWPpppppppppppppppppqqqqQQ' + 'QQk'
    row = row[:w - 1] + 'k'
    rows = ['k' * w]
    for _ in range(9):
        rows.append(row)
    rows.append('k' * w)
    # bant
    rows[3] = 'k' + 'y' * (w - 2) + 'k'
    rows[4] = 'k' + 'd' * (w - 2) + 'k'
    return rows


def pipe_body():
    w = 26
    row = 'k' + 'PWPPpppppppppppppqqqqqQQQ'[:w - 2] + 'k'
    return [row]


def ground_tile():
    w, h = 16, 18
    g = grid(w, h)
    rect(g, 0, 0, w, 1, 'k')
    rect(g, 0, 1, w, 2, 'G')
    rect(g, 0, 3, w, 2, 'g')
    for x in range(0, w, 4):
        put(g, x, 3, 'G')
        put(g, x + 1, 2, 'g')
    rect(g, 0, 5, w, 1, 'e')
    rect(g, 0, 6, w, h - 6, 'L')
    for j in range(6, h):
        for i in range(w):
            if (i + j) % 8 in (0, 1):
                g[j][i] = 'l'
    return rows_of(g)


# ───────────────────────── Subway Silly ─────────────────────────
def runner(frame=0, pose='run'):
    """Arkadan görünen koşan tekir kedi (hoodie ile)."""
    w, h = 22, 28
    g = grid(w, h)
    bob = [0, 1, 0, 1][frame % 4] if pose == 'run' else 0
    if pose == 'slide':
        # yere yapışmış, yayvan
        ellipse(g, 11, 22.5, 9.5, 4.2, 'p')
        ellipse(g, 11, 17.5, 6.0, 4.6, 'c')
        stamp(g, 5, 12, ['c..', 'cc.', 'ccc'])
        stamp(g, 14, 12, ['..c', '.cc', 'ccc'])
        for x in (9, 11, 13):
            put(g, x, 15, 's')
            put(g, x, 16, 's')
        rect(g, 3, 25, 4, 2, 's')
        rect(g, 15, 25, 4, 2, 's')
        # kuyruk düz arkada
        for x in range(9, 13):
            put(g, x, 26, 'c')
        outline(g)
        return rows_of(g)
    top = 1 + bob
    if pose == 'jump':
        top = 0
    # baş (arkadan)
    ellipse(g, 11, top + 7.4, 6.0, 5.2, 'c')
    stamp(g, 5, top, ['c...', 'cc..', 'cPc.', 'cPcc'])
    stamp(g, 14, top, ['...c', '..cc', '.cPc', 'ccPc'])
    # tekir "M" deseni + yanak tüyleri
    for (x, y) in [(11, 3), (11, 4), (11, 5), (9, 4), (13, 4), (8, 6), (14, 6)]:
        put(g, x, top + y, 's')
    put(g, 4, top + 9, 'c')
    put(g, 18, top + 9, 'c')
    # hoodie gövde
    by = top + 12
    ellipse(g, 11, by + 4.5, 6.4, 5.4, 'p')
    rect(g, 6, by - 1, 10, 2, 'q')        # kapüşon kenarı
    ellipse(g, 11, by + 6.5, 3.6, 2.2, 'q', only='p')  # cep
    put(g, 9, by + 2, 'W')
    put(g, 13, by + 2, 'W')               # ip uçları
    # kollar
    if pose == 'jump':
        stamp(g, 2, by - 3, ['c.', 'pp', 'pp', '.p'])
        stamp(g, 18, by - 3, ['.c', 'pp', 'pp', 'p.'])
    else:
        sw = [0, 1, 0, -1][frame % 4]
        stamp(g, 3, by + 1 + sw, ['pp', 'pp', 'cc'])
        stamp(g, 17, by + 1 - sw, ['pp', 'pp', 'cc'])
    # bacaklar / ayakkabı
    ly = by + 9
    if pose == 'jump':
        stamp(g, 6, ly - 1, ['nn..', 'nnn.', '.WWW'])
        stamp(g, 12, ly - 1, ['..nn', '.nnn', 'WWW.'])
    else:
        lift = [(0, 3), (2, 2), (3, 0), (2, 2)][frame % 4]
        stamp(g, 7, ly, ['nnn'] * (4 - lift[0] // 1 if lift[0] < 3 else 1) + ['WWW'])
        stamp(g, 12, ly, ['nnn'] * (4 - lift[1] // 1 if lift[1] < 3 else 1) + ['WWW'])
    # kuyruk (sallanır)
    sway = [0, 1, 0, -1][frame % 4] if pose == 'run' else 0
    for k, (dx, dy) in enumerate([(0, 0), (1, 0), (2, -1), (3, -2), (3, -3), (3, -4), (2, -5)]):
        put(g, 15 + dx, by + 8 + dy + (sway if k > 2 else 0), 's' if k in (2, 4) else 'c')
    outline(g)
    return rows_of(g)


def guard(frame=0):
    """Kovalayan bekçi (arkadan)."""
    w, h = 22, 30
    g = grid(w, h)
    bob = frame % 2
    ellipse(g, 11, 6 + bob, 5.0, 4.6, 'h')          # ense / saç
    rect(g, 5, 2 + bob, 12, 3, 'N')                  # kasket
    rect(g, 4, 4 + bob, 14, 1, 'k')
    put(g, 10, 3 + bob, 'y')
    put(g, 11, 3 + bob, 'y')
    rect(g, 9, 10 + bob, 4, 2, 'S')                  # boyun
    ellipse(g, 11, 16 + bob, 7.0, 5.6, 'n')          # ceket
    rect(g, 10, 12 + bob, 2, 9, 'N')
    rect(g, 4, 14 + bob - frame % 2, 2, 5, 'n')
    rect(g, 16, 14 + bob + frame % 2 - 1, 2, 5, 'n')
    rect(g, 4, 19 + bob - frame % 2, 2, 1, 'S')
    rect(g, 16, 18 + bob + frame % 2, 2, 1, 'S')
    if frame % 2 == 0:
        rect(g, 7, 21, 3, 6, 'N')
        rect(g, 12, 21, 3, 4, 'N')
        rect(g, 7, 27, 3, 1, 'x')
        rect(g, 12, 25, 3, 1, 'x')
    else:
        rect(g, 7, 22, 3, 4, 'N')
        rect(g, 12, 22, 3, 6, 'N')
        rect(g, 7, 26, 3, 1, 'x')
        rect(g, 12, 28, 3, 1, 'x')
    outline(g)
    return rows_of(g)


def train_front(color='p', light='P', dark='q', deep='Q'):
    w, h = 32, 36
    g = grid(w, h)
    rect(g, 1, 2, 30, 33, color)
    rect(g, 1, 2, 30, 2, light)
    rect(g, 2, 1, 28, 1, light)
    # cam
    rect(g, 4, 6, 24, 11, 'n')
    rect(g, 5, 7, 22, 9, 'b')
    for i in range(5):
        put(g, 6 + i, 7 + i, 'B')
        put(g, 7 + i, 7 + i, 'B')
        put(g, 16 + i, 7 + i, 'B')
    rect(g, 15, 6, 2, 11, 'n')
    # hat göstergesi
    rect(g, 10, 3, 12, 2, 'x')
    stamp(g, 12, 3, ['y.yy.y', 'y.y..y'])
    # beyaz şerit
    rect(g, 1, 19, 30, 2, 'W')
    rect(g, 1, 21, 30, 1, light)
    # farlar
    stamp(g, 3, 23, ['YYy', 'YYy'])
    stamp(g, 26, 23, ['yYY', 'yYY'])
    # alt gövde
    rect(g, 1, 27, 30, 8, dark)
    rect(g, 6, 28, 20, 4, deep)
    for x in range(7, 26, 3):
        rect(g, x, 29, 1, 2, 'k')
    rect(g, 0, 33, 32, 2, 'a')
    rect(g, 3, 35, 6, 1, 'k')
    rect(g, 23, 35, 6, 1, 'k')
    outline(g)
    return rows_of(g)


def barrier():
    """Alçak engel: üzerinden atla."""
    w, h = 32, 16
    g = grid(w, h)
    rect(g, 1, 3, 30, 6, 'W')
    for i in range(1, 31):
        for j in range(3, 9):
            if (i + j) % 8 < 4:
                g[j][i] = 'r'
    rect(g, 4, 9, 3, 6, 'a')
    rect(g, 25, 9, 3, 6, 'a')
    rect(g, 2, 14, 7, 1, 'A')
    rect(g, 23, 14, 7, 1, 'A')
    stamp(g, 4, 1, ['yy', 'YY'])
    stamp(g, 26, 1, ['yy', 'YY'])
    outline(g)
    return rows_of(g)


def high_bar():
    """Yüksek kiriş: altından kay."""
    w, h = 32, 40
    g = grid(w, h)
    rect(g, 2, 0, 3, 40, 'a')
    rect(g, 27, 0, 3, 40, 'a')
    rect(g, 2, 0, 1, 40, 'A')
    rect(g, 27, 0, 1, 40, 'A')
    rect(g, 1, 3, 30, 12, 'y')
    for i in range(1, 31):
        for j in range(3, 15):
            if (i - j) % 8 < 4:
                g[j][i] = 'x'
    # "kay" oku
    rect(g, 11, 5, 10, 8, 'W')
    stamp(g, 12, 6, ['...rr...', '...rr...', '...rr...', 'rrrrrrrr', '.rrrrrr.', '..rrrr..'])
    rect(g, 1, 38, 6, 2, 's')
    rect(g, 25, 38, 6, 2, 's')
    outline(g)
    return rows_of(g)


def coin(frame):
    widths = [5.5, 4.2, 2.4, 1.0, 2.4, 4.2]
    g = grid(12, 12)
    rx = widths[frame % 6]
    ellipse(g, 6, 6, rx, 5.5, 'd')
    if rx > 1.5:
        ellipse(g, 6, 6, max(0.6, rx - 1.3), 4.3, 'y')
        ellipse(g, 6 - rx * 0.25, 4.5, max(0.5, rx * 0.35), 1.6, 'Y', only='y')
    else:
        rect(g, 5, 1, 2, 10, 'y')
    outline(g)
    return rows_of(g)


def magnet():
    g = grid(14, 14)
    stamp(g, 1, 1, [
        'rrrr..rrrr',
        'rrrr..rrrr',
        'rrrr..rrrr',
        'rrrr..rrrr',
        'rrrr..rrrr',
        'rrrrrrrrrr',
        '.rrrrrrrr.',
        '..rrrrrr..',
    ])
    rect(g, 1, 1, 4, 2, 'A')
    rect(g, 7, 1, 4, 2, 'A')
    rect(g, 1, 1, 1, 2, 'W')
    rect(g, 7, 1, 1, 2, 'W')
    put(g, 2, 7, 'R')
    put(g, 3, 8, 'R')
    outline(g)
    return rows_of(g)


def sneaker():
    g = grid(16, 12)
    stamp(g, 2, 3, [
        '...pppp....',
        '..pPPPpp...',
        '..pppppppp.',
        '.ppppppppppp',
        'WWWWWWWWWWWW',
        '.AAAAAAAAAA.',
    ])
    put(g, 6, 5, 'W')
    put(g, 7, 5, 'W')
    put(g, 8, 6, 'W')
    # kanat
    stamp(g, 0, 0, ['W...', 'WW..', 'WWW.', '.WW.', '..W.'])
    outline(g)
    return rows_of(g)


def double_badge():
    g = grid(16, 14)
    ellipse(g, 8, 7, 7.0, 6.2, 'v')
    ellipse(g, 8, 7, 5.6, 4.9, 'm')
    stamp(g, 3, 4, [
        'WWW.....',
        '..W.W.W.',
        'WWW..W..',
        'W...W.W.',
        'WWW.....',
    ])
    stamp(g, 11, 4, ['..', '..'])
    outline(g)
    return rows_of(g)


def heart():
    return [
        '.kk.kk.',
        'krrkrrk',
        'krRrrrk',
        'krrrrrk',
        '.krrrk.',
        '..krk..',
        '...k...',
    ]


SPRITES = {
    'flappyCatUp': flappy_cat('up'),
    'flappyCatUpMid': flappy_cat('upMid'),
    'flappyCatMid': flappy_cat('mid'),
    'flappyCatDownMid': flappy_cat('downMid'),
    'flappyCatDown': flappy_cat('down'),
    'flappyCatDead': flappy_cat(dead=True),
    'goldFish0': golden_fish(0),
    'goldFish1': golden_fish(1),
    'medalBronze': medal('u', 'U', 'D'),
    'medalSilver': medal('A', 'W', 'a'),
    'medalGold': medal('y', 'Y', 'd'),
    'medalPlatinum': medal('B', 'W', 'b'),
    'cloud': cloud(),
    'pipeCap': pipe_cap(),
    'pipeBody': pipe_body(),
    'groundTile': ground_tile(),
    'runner0': runner(0),
    'runner1': runner(1),
    'runner2': runner(2),
    'runner3': runner(3),
    'runnerJump': runner(pose='jump'),
    'runnerSlide': runner(pose='slide'),
    'guard0': guard(0),
    'guard1': guard(1),
    'trainPink': train_front(),
    'trainBlue': train_front('b', 'B', 'n', 'N'),
    'trainMint': train_front('g', 'G', 'e', 'N'),
    'barrier': barrier(),
    'highBar': high_bar(),
    'coin0': coin(0),
    'coin1': coin(1),
    'coin2': coin(2),
    'coin3': coin(3),
    'coin4': coin(4),
    'coin5': coin(5),
    'magnet': magnet(),
    'sneaker': sneaker(),
    'double': double_badge(),
    'heart': heart(),
}


def validate():
    for name, rows in SPRITES.items():
        w = len(rows[0])
        assert all(len(r) == w for r in rows), name
        for r in rows:
            for c in r:
                assert c == '.' or c in PALETTE, (name, c)


def write_dart():
    used = sorted({c for rows in SPRITES.values() for r in rows for c in r} - {'.'})
    lines = [
        '// GENERATED by tools/game_sprites.py — elle düzenlemeyin.',
        "// '.' = boş piksel.",
        "import 'dart:ui';",
        '',
        'const Map<String, Color> kArcadePalette = {',
    ]
    for c in used:
        lines.append(f"  '{c}': Color(0xFF{PALETTE[c]:06X}),")
    lines.append('};')
    for name, rows in SPRITES.items():
        const = 'kSpr' + name[0].upper() + name[1:]
        lines.append('')
        lines.append(f'const List<String> {const} = [')
        for r in rows:
            lines.append(f"  '{r}',")
        lines.append('];')
    os.makedirs(os.path.dirname(DART), exist_ok=True)
    with open(DART, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'{len(SPRITES)} sprite → {os.path.relpath(DART, ROOT)}')


def preview(path, scale=6):
    from PIL import Image
    pad = 4
    items = list(SPRITES.items())
    cols = 8
    cw = max(len(r[0]) for _, r in items) + pad
    ch = max(len(r) for _, r in items) + pad
    rows_n = math.ceil(len(items) / cols)
    img = Image.new('RGB', (cols * cw * scale, rows_n * ch * scale), (0x2A, 0x14, 0x30))
    px = img.load()
    for k, (_, rows) in enumerate(items):
        ox, oy = (k % cols) * cw, (k // cols) * ch
        for j, r in enumerate(rows):
            for i, c in enumerate(r):
                if c == '.':
                    continue
                col = PALETTE[c]
                rgb = ((col >> 16) & 255, (col >> 8) & 255, col & 255)
                for a in range(scale):
                    for b in range(scale):
                        px[(ox + i) * scale + a, (oy + j) * scale + b] = rgb
    img.save(path)
    print('preview →', path)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview')
    args = ap.parse_args()
    validate()
    if args.preview:
        preview(args.preview)
    else:
        write_dart()
