#!/usr/bin/env python3
"""Adliye Kulesi piksel-art üreticisi.

İki tür çıktı üretir (`lib/features/game/arcade/tower_sprites.dart`):

* Kat cephe modülleri: rol harfleriyle çizilir (O kontur, D koyu, M ana,
  L açık, H parlak, w/W cam, T/t süs, A/a ikinci süs). Her dönemin
  (ülke / adalet sarayı) kendi rol paleti vardır; aynı modül farklı
  renklerle değil, her dönem kendi mimarisiyle çizilir. Modüller yatayda
  dünyaya sabitlenerek döşenir: kesilen blok aynı deseni korur.
* Avukat kız, bayraklar, Themis heykeli, balon: ortak arcade paletiyle.

    python3 tools/tower_sprites.py
    python3 tools/tower_sprites.py --preview out.png
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import game_sprites as gs  # noqa: E402
from game_sprites import grid, put, rect, ellipse, stamp, outline, rows_of, flip  # noqa: E402

ROOT = gs.ROOT
DART = os.path.join(ROOT, 'lib', 'features', 'game', 'arcade', 'tower_sprites.dart')
FH = 16  # kat yüksekliği (piksel)

ROLES = 'ODMLHwWTtAa'

# ───────────────────────── Dönemler ─────────────────────────
# (anahtar, şehir, bina, bayrak, rol paleti)
ERAS = [
    ('tr', 'İstanbul', 'Sultanahmet Adliyesi', {
        'O': 0x4A2A20, 'D': 0xB8936A, 'M': 0xE8D2A8, 'L': 0xF5E6C8, 'H': 0xFFF6E2,
        'w': 0x24414F, 'W': 0x5E93A6, 'T': 0xB5452F, 't': 0x7A2A1E,
        'A': 0x2FA6A0, 'a': 0x1B6E73}),
    ('us', 'Washington', 'ABD Yüksek Mahkemesi', {
        'O': 0x3C3F52, 'D': 0xA9ADBE, 'M': 0xDCDFE8, 'L': 0xEEF0F6, 'H': 0xFFFFFF,
        'w': 0x2E3446, 'W': 0x5C6680, 'T': 0xC9B27A, 't': 0x8C7646,
        'A': 0x7D8499, 'a': 0x565C70}),
    ('uk', 'Londra', 'Kraliyet Adalet Divanı', {
        'O': 0x2E2A2C, 'D': 0x8C8273, 'M': 0xB9AD96, 'L': 0xD3C8B0, 'H': 0xEDE4CE,
        'w': 0x1F2A3A, 'W': 0x5B7896, 'T': 0x4E5560, 't': 0x30343C,
        'A': 0xA8463C, 'a': 0x6B2A24}),
    ('it', 'Roma', 'Adalet Sarayı (Palazzaccio)', {
        'O': 0x4B3626, 'D': 0xBFA27A, 'M': 0xE3CFA6, 'L': 0xF0E1BE, 'H': 0xFBF2DC,
        'w': 0x3A2E2A, 'W': 0x7A6658, 'T': 0x9C7B52, 't': 0x6E5434,
        'A': 0x6B8E5A, 'a': 0x445E38}),
    ('be', 'Brüksel', 'Adalet Sarayı', {
        'O': 0x1E1C22, 'D': 0x5E5A60, 'M': 0x86808A, 'L': 0xA49FA6, 'H': 0xC4C0C6,
        'w': 0x17161C, 'W': 0x3E4A5A, 'T': 0xE0B44C, 't': 0x9C7424,
        'A': 0x4E4A52, 'a': 0x343038}),
    ('de', 'Karlsruhe', 'Federal Anayasa Mahkemesi', {
        'O': 0x1C2430, 'D': 0x6E7C8C, 'M': 0xB4C0CC, 'L': 0xD6DEE6, 'H': 0xF4F8FC,
        'w': 0x3E7FA8, 'W': 0x9FD3EE, 'T': 0x2E3A48, 't': 0x1C2430,
        'A': 0xC9E9F7, 'a': 0x5FA8CF}),
    ('jp', 'Tokyo', 'Yüksek Mahkeme', {
        'O': 0x24221F, 'D': 0x6A655E, 'M': 0x948E85, 'L': 0xB3ADA3, 'H': 0xCFC9BF,
        'w': 0x1A1918, 'W': 0x45403A, 'T': 0x7C766D, 't': 0x4A4640,
        'A': 0xB8463A, 'a': 0x7A2A22}),
    ('eu', 'Strazburg', 'Avrupa İnsan Hakları Mahkemesi', {
        'O': 0x1F2330, 'D': 0x7C8494, 'M': 0xAEB5C2, 'L': 0xCDD3DD, 'H': 0xEEF1F6,
        'w': 0x22324A, 'W': 0x6E9BC8, 'T': 0xC8323A, 't': 0x861E26,
        'A': 0x8FA0B8, 'a': 0x58667E}),
]


def g16(w):
    return grid(w, FH)


def cornice(g, w, top='H', mid='L', dent=None, dent_dark='D'):
    rect(g, 0, 0, w, 1, top)
    rect(g, 0, 1, w, 1, mid)
    if dent:
        for x in range(w):
            put(g, x, 2, dent if x % 2 == 0 else dent_dark)


def base_band(g, w, a='D', b='O'):
    rect(g, 0, FH - 2, w, 1, a)
    rect(g, 0, FH - 1, w, 1, b)


def module_tr():
    """Osmanlı uyanış üslubu: sivri kemerli pencere, ablaklı (iki renkli)
    kemer taşları, çini pano, dişli saçak."""
    w = 16
    g = g16(w)
    rect(g, 0, 0, w, FH, 'M')
    cornice(g, w, 'H', 'L', dent='T', dent_dark='t')
    rect(g, 0, 3, w, 1, 'D')
    # pilastr
    rect(g, 0, 4, 2, 10, 'L')
    put(g, 0, 4, 'H')
    rect(g, 1, 4, 1, 10, 'D')
    # çini pano (kemer üstü)
    rect(g, 4, 4, 8, 1, 'A')
    put(g, 5, 4, 'a'); put(g, 8, 4, 'a'); put(g, 10, 4, 'a')
    # sivri kemer: kemer taşları sırayla T / H
    arch = [(7, 5), (8, 5), (6, 6), (9, 6), (5, 7), (10, 7), (5, 8), (10, 8)]
    for k, (x, y) in enumerate(arch):
        put(g, x, y, 'T' if k % 4 < 2 else 'H')
    # cam
    for y in range(6, 13):
        x0 = 7 if y == 6 else 6
        x1 = 8 if y == 6 else 9
        for x in range(x0, x1 + 1):
            put(g, x, y, 'w')
    put(g, 7, 7, 'W'); put(g, 6, 8, 'W'); put(g, 7, 8, 'W')
    rect(g, 7, 9, 2, 1, 'O')  # demir parmaklık
    rect(g, 7, 11, 2, 1, 'O')
    rect(g, 5, 9, 1, 4, 'D')
    rect(g, 10, 9, 1, 4, 'L')
    rect(g, 5, 13, 6, 1, 'L')  # denizlik
    put(g, 5, 13, 'H')
    base_band(g, w, 'D', 'O')
    rect(g, 2, FH - 2, w - 2, 1, 'T')
    return rows_of(g)


def module_us():
    """Korint sütunlu mermer revak: parlak sütunlar, arkada derin gölge."""
    w = 11
    g = g16(w)
    # sütunlar arası gölgeli revak
    rect(g, 0, 0, w, FH, 'a')
    rect(g, 6, 4, 5, 9, 'A')
    rect(g, 7, 6, 3, 6, 'w')  # arkadaki kapı
    rect(g, 7, 6, 3, 1, 'O')
    put(g, 8, 8, 'W')
    # arşitrav + friz
    rect(g, 0, 0, w, 1, 'H')
    rect(g, 0, 1, w, 1, 'L')
    rect(g, 0, 2, w, 1, 'D')
    # başlık (Korint): iki sıra, uçlarda volüt
    rect(g, 0, 3, 7, 1, 'H')
    put(g, 0, 3, 'L'); put(g, 6, 3, 'M')
    rect(g, 1, 4, 5, 1, 'L')
    put(g, 0, 4, 'T'); put(g, 6, 4, 'T')
    put(g, 2, 4, 'T'); put(g, 4, 4, 'T')
    # yivli gövde (soldan ışık)
    for y in range(5, 13):
        put(g, 1, y, 'H')
        put(g, 2, y, 'L')
        put(g, 3, y, 'M')
        put(g, 4, y, 'L' if y % 2 else 'M')
        put(g, 5, y, 'D')
    # kaide + basamak
    rect(g, 0, 13, 7, 1, 'L')
    put(g, 6, 13, 'D')
    rect(g, 0, FH - 2, w, 1, 'M')
    rect(g, 0, FH - 1, w, 1, 'O')
    return rows_of(g)


def module_uk():
    """Viktorya gotiği: payandalar, sivri lanset pencere, iz (tracery)."""
    w = 14
    g = g16(w)
    rect(g, 0, 0, w, FH, 'M')
    rect(g, 0, 0, w, 1, 'H')
    rect(g, 0, 1, w, 1, 'T')
    for x in range(0, w, 2):
        put(g, x, 2, 'L')
    # taş derzleri
    for y in (5, 9, 12):
        for x in range(w):
            if (x + y) % 5 == 0:
                put(g, x, y, 'D')
    # payanda (kademeli)
    rect(g, 0, 2, 3, 12, 'L')
    rect(g, 2, 2, 1, 12, 'D')
    put(g, 0, 2, 'H'); put(g, 1, 2, 'H')
    rect(g, 0, 7, 3, 1, 'D')
    put(g, 0, 7, 'L')
    # lanset pencere
    win = {4: (8, 8), 5: (7, 9), 6: (6, 10)}
    for y in range(4, 13):
        x0, x1 = win.get(y, (6, 10))
        for x in range(x0, x1 + 1):
            put(g, x, y, 'w')
    put(g, 8, 3, 'T')
    put(g, 7, 4, 'T'); put(g, 9, 4, 'T'); put(g, 6, 5, 'T'); put(g, 10, 5, 'T')
    rect(g, 5, 6, 1, 7, 'T')
    rect(g, 11, 6, 1, 7, 'T')
    rect(g, 8, 6, 1, 7, 'T')  # orta kayıt
    put(g, 7, 6, 'W'); put(g, 9, 7, 'W'); put(g, 6, 9, 'W')
    put(g, 8, 5, 'A')  # vitray yuvarlağı
    rect(g, 5, 13, 7, 1, 'L')
    base_band(g, w, 'D', 'O')
    return rows_of(g)


def module_it():
    """Traverten cephe: üçgen alınlıklı pencere, rustik derz, korkuluk."""
    w = 16
    g = g16(w)
    rect(g, 0, 0, w, FH, 'M')
    cornice(g, w, 'H', 'L')
    rect(g, 0, 2, w, 1, 'D')
    # rustik yatay derzler
    for y in (6, 10):
        for x in range(w):
            if x < 3 or x > 12:
                put(g, x, y, 'D')
    # alınlık
    for i in range(6):
        put(g, 5 + i, 4 - (i if i < 3 else 5 - i) // 1 * 0, 'T')
    rect(g, 4, 5, 8, 1, 'T')
    put(g, 7, 3, 'T'); put(g, 8, 3, 'T')
    put(g, 6, 4, 'T'); put(g, 9, 4, 'T'); put(g, 5, 4, 'L'); put(g, 10, 4, 'L')
    put(g, 7, 4, 'H'); put(g, 8, 4, 'H')
    # pencere + pervaz
    rect(g, 5, 6, 6, 6, 'L')
    rect(g, 6, 6, 4, 6, 'w')
    rect(g, 7, 6, 1, 6, 'O')
    rect(g, 6, 8, 4, 1, 'O')
    put(g, 6, 7, 'W'); put(g, 8, 7, 'W'); put(g, 6, 9, 'W')
    rect(g, 10, 6, 1, 6, 'D')
    # korkuluk (balüstrat)
    rect(g, 3, 12, 10, 1, 'L')
    for x in range(4, 12, 2):
        put(g, x, 13, 'H')
        put(g, x + 1, 13, 'D')
    base_band(g, w, 'T', 'O')
    return rows_of(g)


def module_be():
    """Brüksel: devasa yuvarlak kemer, rustik taş bloklar, yaldızlı kilit
    taşı."""
    w = 18
    g = g16(w)
    rect(g, 0, 0, w, FH, 'M')
    cornice(g, w, 'H', 'L', dent='T', dent_dark='t')
    # rustik bloklar
    for y in range(3, 14):
        for x in range(w):
            if y in (6, 9, 12) or ((x + (4 if (y // 3) % 2 else 0)) % 8 == 0):
                put(g, x, y, 'D')
    # yuvarlak kemer
    cx, r = 9.0, 6.2
    for y in range(4, 14):
        for x in range(w):
            d = math.hypot(x + 0.5 - cx, max(0, 9.5 - (y + 0.5)))
            if abs(x + 0.5 - cx) <= 5 and (y >= 10 or d <= r - 1.2):
                put(g, x, y, 'w' if d <= r - 2.2 or y >= 10 else 'A')
            elif abs(x + 0.5 - cx) <= 6 and (y >= 10 or d <= r):
                put(g, x, y, 'L' if x < cx else 'D')
    # iç pencere
    rect(g, 7, 7, 4, 6, 'W')
    rect(g, 9, 7, 1, 6, 'w')
    rect(g, 7, 9, 4, 1, 'w')
    put(g, 7, 7, 'H')
    # kilit taşı
    put(g, 8, 3, 'T'); put(g, 9, 3, 'T'); put(g, 8, 4, 't'); put(g, 9, 4, 'T')
    base_band(g, w, 'D', 'O')
    return rows_of(g)


def module_de():
    """Modernist cam-çelik cephe: ince kayıtlar, yansıma çizgileri."""
    w = 10
    g = g16(w)
    rect(g, 0, 0, w, FH, 'w')
    rect(g, 0, 0, w, 1, 'H')
    rect(g, 0, 1, w, 2, 'L')
    rect(g, 0, 3, w, 1, 'T')
    rect(g, 0, 4, 1, 10, 'L')
    rect(g, 5, 4, 1, 10, 'D')
    # yansıma çaprazları
    for k in range(9):
        x, y = 1 + k // 2, 13 - k
        if x < 5:
            put(g, x, y, 'W')
    for k in range(5):
        put(g, 6 + k // 2, 9 - k, 'A')
    put(g, 3, 5, 'A'); put(g, 4, 5, 'W'); put(g, 8, 11, 'W')
    rect(g, 0, 9, w, 1, 'a')
    base_band(g, w, 'T', 'O')
    return rows_of(g)


def module_jp():
    """Tokyo granit: kaba dokulu masif bloklar, dikey yarık pencereler."""
    w = 12
    g = g16(w)
    rect(g, 0, 0, w, FH, 'M')
    rect(g, 0, 0, w, 1, 'H')
    rect(g, 0, 1, w, 1, 'L')
    rect(g, 0, 2, w, 1, 'D')
    # granit benekleri (sabit desen)
    for y in range(3, 14):
        for x in range(w):
            v = (x * 7 + y * 13 + x * y) % 11
            if v == 0:
                put(g, x, y, 'D')
            elif v == 5:
                put(g, x, y, 'L')
    # derin yatay oluk
    rect(g, 0, 8, w, 1, 'T')
    # yarık pencere
    rect(g, 5, 3, 2, 11, 'w')
    put(g, 5, 4, 'W'); put(g, 5, 9, 'W')
    rect(g, 4, 3, 1, 11, 'D')
    rect(g, 7, 3, 1, 11, 'L')
    base_band(g, w, 'D', 'O')
    return rows_of(g)


def module_eu():
    """AİHM: paslanmaz çelik paneller, kırmızı kiriş, silindirik cam
    kule şeridi."""
    w = 16
    g = g16(w)
    rect(g, 0, 0, w, FH, 'M')
    rect(g, 0, 0, w, 1, 'H')
    rect(g, 0, 1, w, 2, 'T')
    rect(g, 0, 2, w, 1, 't')
    # çelik paneller (perçin çizgileri)
    for y in range(3, 14):
        put(g, 0, y, 'L')
        put(g, 4, y, 'D')
        put(g, 5, y, 'L')
    for x in range(0, 9):
        put(g, x, 8, 'D')
    for x in (2, 7):
        put(g, x, 5, 'D'); put(g, x, 11, 'D')
    # silindirik cam şerit: kenarlar koyu, ortası parlak
    shade = ['a', 'w', 'W', 'A', 'W', 'w', 'a']
    for i, c in enumerate(shade):
        rect(g, 9 + i, 3, 1, 11, c)
    for y in (6, 10):
        rect(g, 9, y, 7, 1, 'D')
    rect(g, 8, 3, 1, 11, 'O')
    base_band(g, w, 'D', 'O')
    return rows_of(g)


MODULES = {
    'tr': module_tr(),
    'us': module_us(),
    'uk': module_uk(),
    'it': module_it(),
    'be': module_be(),
    'de': module_de(),
    'jp': module_jp(),
    'eu': module_eu(),
}


# ───────────────────────── Avukat kız ─────────────────────────
def _girl_head(g, pose, blink):
    fall = pose.startswith('fall')
    # saç (arka): yüzü çevreler, omuzlara iner
    ellipse(g, 12, 8, 7.2, 7.4, 'h')
    rect(g, 5, 8, 14, 9 if not fall else 6, 'h')
    for x in (5, 18):
        put(g, x, 17, 'h') if not fall else None
    if fall:
        # saç telleri yukarı savrulur (dalgalı tutamlar)
        f = 1 if pose == 'fall1' else 0
        # saç telleri yukarı savrulur: dalgalı, uçları incelen tutamlar
        for k, x in enumerate(range(6, 18, 3)):
            ln = 2 + ((k + f) % 2)
            sway = 1 if (k + f) % 2 else -1
            for d in range(ln):
                y = 1 - d
                put(g, x + (sway if d == ln - 1 else 0), y + 1, 'h')
                if d < ln - 1:
                    put(g, x + 1, y + 1, 'h')
            put(g, x, 2, 'l') if k % 2 else None
    # yüz
    ellipse(g, 12, 9.6, 5.1, 5.4, 'S')
    # perçem (hafif yana taranmış) + parlama
    for x in range(7, 18):
        put(g, x, 4, 'h'); put(g, x, 5, 'h')
    for x in (7, 8, 9, 10, 15, 16, 17):
        put(g, x, 6, 'h')
    for x in (7, 8, 17):
        put(g, x, 7, 'h')
    put(g, 9, 3, 'l'); put(g, 10, 3, 'l'); put(g, 11, 4, 'l'); put(g, 14, 4, 'l')
    rect(g, 6, 8, 1, 8, 'h')
    rect(g, 17, 8, 1, 8, 'h')
    # gözler
    ey = 9
    if blink:
        for ex in (9, 14):
            put(g, ex, ey + 1, 'x'); put(g, ex + 1, ey + 1, 'x')
    elif fall:
        for ex in (9, 14):
            put(g, ex, ey, 'x'); put(g, ex + 1, ey, 'x')
            put(g, ex, ey + 1, 'x'); put(g, ex + 1, ey + 1, 'x')
            put(g, ex + 1, ey, 'W')
    else:
        for ex in (9, 14):
            put(g, ex, ey - 1, 'x'); put(g, ex + 1, ey - 1, 'x')
            put(g, ex, ey, 'x'); put(g, ex + 1, ey, 'W')
            put(g, ex, ey + 1, 'x'); put(g, ex + 1, ey + 1, 'x')
    # kaşlar
    by = ey - 3 if fall else ey - 2
    for ex in (9, 14):
        put(g, ex, by, 'h'); put(g, ex + 1, by, 'h')
    # yanak + ağız
    put(g, 8, ey + 3, 'R'); put(g, 16, ey + 3, 'R')
    if fall:
        put(g, 12, ey + 3, 'Q'); put(g, 12, ey + 4, 'Q')
    elif pose.startswith('wave'):
        put(g, 11, ey + 3, 'Q'); put(g, 12, ey + 3, 'Q')
        put(g, 11, ey + 4, 'q'); put(g, 12, ey + 4, 'q')
    else:
        put(g, 11, ey + 3, 'q'); put(g, 12, ey + 3, 'q')
    # boyun
    rect(g, 11, 14, 2, 2, 'S')


def _girl_robe(g, flare=0.0, hem_wave=None):
    top, bottom = 16, 29
    for y in range(top, bottom + 1):
        k = (y - top) / (bottom - top)
        half = 5.6 + k * (2.6 + flare)
        if y == top:
            half = 4.6
        x0, x1 = int(round(12 - half)), int(round(12 + half)) - 1
        for x in range(x0, x1 + 1):
            put(g, x, y, 'x')
        put(g, x0 + 1, y, 's')  # soldan ışık
    # kıvrımlar
    for y in range(21, 29):
        if y % 3:
            put(g, 9, y, 's')
        if (y + 1) % 3:
            put(g, 14, y, 's')
    if hem_wave is not None:
        for x in range(0, 24):
            if (x + hem_wave) % 4 == 0:
                put(g, x, bottom, '.')
    # yeşil yaka (V) + beyaz gömlek
    for i in range(7):
        y = top + i
        put(g, 7 + (i + 1) // 2, y, 'e')
        put(g, 8 + (i + 1) // 2, y, 'g')
        put(g, 16 - (i + 1) // 2, y, 'e')
        put(g, 15 - (i + 1) // 2, y, 'g')
    for y in range(top, top + 5):
        span = 2 - (y - top) // 2
        for x in range(12 - span, 12 + span):
            put(g, x, y, 'W')
    put(g, 11, top + 1, 'C')


def _girl_arm_down(g, side):
    x = 4 if side < 0 else 17
    for y in range(17, 26):
        put(g, x + 1, y, 'x'); put(g, x + 2 if side < 0 else x, y, 'x')
        put(g, x + (0 if side < 0 else 2), y, 'x' if y > 19 else '.')
    rect(g, x, 25, 3, 1, 'e')
    rect(g, x + (1 if side < 0 else 0), 26, 2, 2, 'S')


def _girl_arm_up(g, side, high):
    # omuzdan yukarı çapraz kol; uçta el
    sx, sy = (16, 17) if side > 0 else (7, 17)
    ex, ey = (20, 9 if high else 11) if side > 0 else (3, 9 if high else 11)
    n = 8
    for i in range(n + 1):
        x = round(sx + (ex - sx) * i / n)
        y = round(sy + (ey - sy) * i / n)
        for d in (-1, 0, 1):
            put(g, x + d, y, 'x')
    put(g, ex - (1 if side > 0 else -1), ey + 1, 'e')
    put(g, ex, ey + 1, 'e')
    rect(g, ex - (0 if side > 0 else 1), ey - 2, 2, 2, 'S')


def lawyer(pose='stand', blink=False):
    """24×32, önden. Siyah cüppe, yeşil yaka (Türkiye avukat cüppesi),
    beyaz gömlek, uzun koyu saç. pose: stand | wave0 | wave1 | fall0 |
    fall1."""
    g = grid(24, 32)
    fall = pose.startswith('fall')
    _girl_head(g, pose, blink)
    if pose in ('stand',):
        _girl_arm_down(g, -1)
        _girl_arm_down(g, 1)
        _girl_robe(g)
    elif pose.startswith('wave'):
        _girl_arm_down(g, -1)
        _girl_robe(g)
        _girl_arm_up(g, 1, pose == 'wave1')
    else:
        _girl_robe(g, flare=1.6, hem_wave=1 if pose == 'fall1' else 3)
        _girl_arm_up(g, -1, pose == 'fall0')
        _girl_arm_up(g, 1, pose == 'fall1')
    # ayakkabılar
    if fall:
        rect(g, 8, 30, 3, 1, 'k'); rect(g, 13, 30, 3, 1, 'k')
    else:
        rect(g, 8, 30, 3, 2, 'k'); rect(g, 13, 30, 3, 2, 'k')
        put(g, 9, 30, 's'); put(g, 14, 30, 's')
    if pose == 'stand':
        # sağ elde küçük altın terazi
        stamp(g, 16, 27, [
            '..y..',
            'yyyyy',
            'Y...Y',
            'y...y',
        ])
    outline(g, 'k')
    return rows_of(g)


# ───────────────────────── Bayraklar (16×11) ─────────────────────────
def flag(code):
    w, h = 16, 11
    g = grid(w, h)
    if code == 'tr':
        rect(g, 0, 0, w, h, 'r')
        ellipse(g, 6, 5.5, 3.4, 3.4, 'W')
        ellipse(g, 7.1, 5.5, 2.7, 2.7, 'r')
        for x, y in ((10, 5), (11, 4), (11, 5), (11, 6), (12, 5)):
            put(g, x, y, 'W')
    elif code == 'us':
        for y in range(h):
            rect(g, 0, y, w, 1, 'r' if y % 2 == 0 else 'W')
        rect(g, 0, 0, 7, 6, 'n')
        for y in range(1, 6, 2):
            for x in range(1, 7, 2):
                put(g, x, y, 'W')
    elif code == 'uk':
        rect(g, 0, 0, w, h, 'n')
        for i in range(w):
            y = round(i * (h - 1) / (w - 1))
            for d in (-1, 0, 1):
                put(g, i, y + d, 'W')
                put(g, i, h - 1 - y + d, 'W')
            put(g, i, y, 'r')
            put(g, i, h - 1 - y, 'r')
        rect(g, 6, 0, 4, h, 'W')
        rect(g, 0, 4, w, 3, 'W')
        rect(g, 7, 0, 2, h, 'r')
        rect(g, 0, 5, w, 1, 'r')
    elif code == 'it':
        rect(g, 0, 0, 5, h, 'e'); rect(g, 5, 0, 6, h, 'W'); rect(g, 11, 0, 5, h, 'r')
    elif code == 'be':
        rect(g, 0, 0, 5, h, 'x'); rect(g, 5, 0, 6, h, 'y'); rect(g, 11, 0, 5, h, 'r')
    elif code == 'de':
        rect(g, 0, 0, w, 4, 'x'); rect(g, 0, 4, w, 3, 'r'); rect(g, 0, 7, w, 4, 'y')
    elif code == 'jp':
        rect(g, 0, 0, w, h, 'W'); ellipse(g, 8, 5.5, 3.2, 3.2, 'r')
    elif code == 'eu':
        rect(g, 0, 0, w, h, 'n')
        for k in range(12):
            a = k / 12 * math.tau
            put(g, round(7.5 + math.cos(a) * 3.6), round(5 + math.sin(a) * 3.6), 'y')
    # kumaş gölgesi (dalga)
    for y in range(h):
        for x in (3, 4, 11, 12):
            pass
    out = rows_of(g)
    return out


# ───────────────────────── Süsler ─────────────────────────
def themis():
    """Adalet tanrıçası heykeli (mermer): gözü bağlı, yukarı kalkık sağ
    elde altın terazi, sol elde aşağı inen kılıç; kademeli kaide."""
    w, h = 22, 40
    g = grid(w, h)
    # kaide
    rect(g, 4, 31, 14, 9, 'A')
    rect(g, 4, 31, 14, 1, 'C')
    rect(g, 5, 33, 12, 5, 'c')
    rect(g, 5, 33, 12, 1, 'a')
    rect(g, 3, 38, 16, 2, 'a')
    rect(g, 3, 38, 16, 1, 'A')
    # elbise (aşağı genişler, dökümlü)
    for y in range(13, 31):
        k = (y - 13) / 17
        half = 2.2 + k * 3.2
        x0, x1 = int(round(11 - half)), int(round(11 + half))
        for x in range(x0, x1 + 1):
            put(g, x, y, 'C')
        put(g, x0, y, 'W')
        put(g, x1, y, 'A')
    for y in range(17, 31, 2):
        put(g, 10, y, 'A')
        put(g, 13, y + 1, 'A')
    # baş, göz bağı, topuz
    ellipse(g, 11, 10, 2.6, 2.9, 'C')
    put(g, 10, 9, 'W')
    rect(g, 8, 10, 7, 1, 'p')
    put(g, 15, 11, 'p'); put(g, 15, 12, 'p')
    rect(g, 10, 6, 3, 2, 'A')
    # sağ kol yukarı + terazi
    for i in range(6):
        put(g, 13 + i // 2, 13 - i, 'C')
        put(g, 14 + i // 2, 13 - i, 'A')
    rect(g, 16, 3, 1, 5, 'y')
    rect(g, 12, 3, 9, 1, 'y')
    put(g, 16, 2, 'Y')
    for x in (12, 20):
        put(g, x, 4, 'd'); put(g, x, 5, 'd')
    rect(g, 11, 6, 3, 1, 'y'); rect(g, 19, 6, 3, 1, 'y')
    # sol kol aşağı + kılıç
    rect(g, 7, 14, 1, 6, 'C')
    rect(g, 5, 19, 3, 1, 'y')
    rect(g, 6, 20, 1, 10, 'A')
    put(g, 6, 18, 'y')
    outline(g, 'k')
    return rows_of(g)


def balloon():
    w, h = 18, 26
    g = grid(w, h)
    ellipse(g, 9, 8, 8, 8.2, 'p')
    for x in range(w):
        for y in range(17):
            if g[y][x] == 'p':
                band = int((x - 1) / 3.2)
                g[y][x] = ['P', 'p', 'W', 'p', 'P', 'q'][band % 6]
    for y in range(12, 17):
        for x in range(w):
            if g[y][x] != '.':
                g[y][x] = 'q' if g[y][x] != 'W' else 'P'
    # ipler + sepet
    for y in range(17, 21):
        put(g, 5 + (y - 17) // 2, y, 'l')
        put(g, 12 - (y - 17) // 2, y, 'l')
    rect(g, 6, 21, 6, 4, 'l')
    rect(g, 6, 21, 6, 1, 'L')
    put(g, 8, 22, 'L'); put(g, 10, 23, 'L')
    outline(g, 'k')
    return rows_of(g)


def lamp():
    w, h = 8, 26
    g = grid(w, h)
    rect(g, 3, 6, 2, 19, 's')
    rect(g, 2, 24, 4, 2, 's')
    rect(g, 1, 1, 6, 5, 'Y')
    rect(g, 1, 0, 6, 1, 's')
    rect(g, 2, 6, 4, 1, 's')
    put(g, 2, 2, 'W')
    outline(g, 'k')
    return rows_of(g)


def tree():
    w, h = 18, 26
    g = grid(w, h)
    rect(g, 8, 17, 2, 9, 'l')
    for (cx, cy, r) in ((9, 9, 6.5), (5.5, 13, 4.5), (12.5, 13, 4.5), (9, 5, 4.4)):
        ellipse(g, cx, cy, r, r, 'e')
    for j in range(h):
        for i in range(w):
            if g[j][i] == 'e' and (i + j) % 7 == 0 and j < 12:
                g[j][i] = 'g'
    outline(g, 'k')
    return rows_of(g)


DECOR = {
    'lawyerStand': lawyer('stand'),
    'lawyerBlink': lawyer('stand', blink=True),
    'lawyerWave0': lawyer('wave0'),
    'lawyerWave1': lawyer('wave1'),
    'lawyerFall0': lawyer('fall0'),
    'lawyerFall1': lawyer('fall1'),
    'themis': themis(),
    'balloon': balloon(),
    'lamp': lamp(),
    'tree': tree(),
}
for code, *_ in ERAS:
    DECOR['flag' + code.upper()] = flag(code)


def validate():
    for name, rows in MODULES.items():
        assert len(rows) == FH, name
        assert all(len(r) == len(rows[0]) for r in rows), name
        for r in rows:
            for c in r:
                assert c in ROLES, (name, c)
    for name, rows in DECOR.items():
        assert all(len(r) == len(rows[0]) for r in rows), name
        for r in rows:
            for c in r:
                assert c == '.' or c in gs.PALETTE, (name, c)


def dart_name(prefix, name):
    return prefix + name[0].upper() + name[1:]


def write_dart():
    lines = [
        '// GENERATED by tools/tower_sprites.py — elle düzenlemeyin.',
        '// Kat modülleri rol harfleriyle (O D M L H w W T t A a) çizilir;',
        '// renkleri her dönemin [TowerEra.palette] haritası verir.',
        "import 'dart:ui';",
        '',
        'const int kTowerFloorPx = %d;' % FH,
        '',
        'class TowerEra {',
        '  final String code, city, name;',
        '  final List<String> module;',
        '  final Map<String, Color> palette;',
        '  final List<String> flag;',
        '  const TowerEra(this.code, this.city, this.name, this.module,',
        '      this.palette, this.flag);',
        '}',
        '',
    ]
    for code, rows in MODULES.items():
        lines.append(f'const List<String> {dart_name("kTowerModule", code)} = [')
        lines += [f"  '{r}'," for r in rows]
        lines += ['];', '']
    for name, rows in DECOR.items():
        lines.append(f'const List<String> {dart_name("kTwr", name)} = [')
        lines += [f"  '{r}'," for r in rows]
        lines += ['];', '']
    lines.append('const List<TowerEra> kTowerEras = [')
    for code, city, name, pal in ERAS:
        lines.append('  TowerEra(')
        lines.append(f"    '{code}',")
        lines.append(f"    '{city}',")
        lines.append(f"    '{name}',")
        lines.append(f'    {dart_name("kTowerModule", code)},')
        lines.append('    {')
        for k in ROLES:
            lines.append(f"      '{k}': Color(0xFF{pal[k]:06X}),")
        lines.append('    },')
        lines.append(f'    {dart_name("kTwrFlag", code.upper())},')
        lines.append('  ),')
    lines += ['];', '']
    with open(DART, 'w') as f:
        f.write('\n'.join(lines))
    print(f'{len(MODULES)} modül + {len(DECOR)} süs → {os.path.relpath(DART, ROOT)}')


def preview(path, scale=6):
    from PIL import Image
    floors = 3
    tile_w = 64
    pad = 6
    era_h = floors * FH
    W = (tile_w + pad) * len(ERAS) + pad
    deco = list(DECOR.items())
    deco_w = sum(len(r[0]) + pad for _, r in deco) + pad
    W = max(W, deco_w)
    H = era_h + pad * 3 + max(len(r) for _, r in deco)
    img = Image.new('RGB', (W * scale, H * scale), (0x8E, 0xC8, 0xF0))
    px = img.load()

    def dot(x, y, col):
        for a in range(scale):
            for b in range(scale):
                px[x * scale + a, y * scale + b] = col

    def rgb(v):
        return ((v >> 16) & 255, (v >> 8) & 255, v & 255)

    for e, (code, _, _, pal) in enumerate(ERAS):
        rows = MODULES[code]
        mw = len(rows[0])
        ox = pad + e * (tile_w + pad)
        for f in range(floors):
            for y in range(FH):
                for x in range(tile_w):
                    c = rows[y][(x + f * 3) % mw]
                    dot(ox + x, pad + f * FH + y, rgb(pal[c]))
    x = pad
    for _, rows in deco:
        for j, r in enumerate(rows):
            for i, c in enumerate(r):
                if c != '.':
                    dot(x + i, era_h + pad * 2 + j, rgb(gs.PALETTE[c]))
        x += len(rows[0]) + pad
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
