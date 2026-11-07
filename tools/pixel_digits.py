#!/usr/bin/env python3
"""Replace Pixelify Sans digits with clear 5x7 arcade digits.

The original digits have chamfered corners, so at small sizes 5 reads as S
and 2/5/6/9 blur together. This redraws 0 and 2-9 (1 is already clear) on
the font's own pixel grid, square-cornered, for both weight masters
(400 regular, 700 bold through gvar), and keeps the advance widths so the
digits stay tabular. Safe to run again: the digits are rebuilt from the
bitmaps below each time.

Needs fontTools:  pip install fonttools
Usage:            python3 tools/pixel_digits.py
"""
from pathlib import Path

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables.TupleVariation import TupleVariation

FONT = Path(__file__).resolve().parents[1] / 'assets/fonts/PixelifySans.ttf'

# Row 0 is the top row; '#' is a pixel.
DIGITS = {
    '0': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
    '3': ['#####', '...#.', '..#..', '...#.', '....#', '#...#', '.###.'],
    '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
    '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
    '6': ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
    '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
    '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
    '9': ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
}

# Pixel grid measured from the font's own '0' and 'l' outlines: left edge,
# horizontal step, bottom edge, vertical step and pixel size (pixels overlap
# their neighbours slightly, like the original glyphs).
REGULAR = dict(x=60, dx=91, y=-12, dy=(643 - 101) / 6, size=101)
BOLD = dict(x=61, dx=(481 - 127) / 4, y=-11, dy=(649 - 127) / 6, size=127)
BOLD_EXTRA_ADVANCE = 17  # 586 -> 603, as the original digits


def runs(rows):
    """Horizontal runs of pixels: (row, first column, last column)."""
    for r, row in enumerate(rows):
        c = 0
        while c < len(row):
            if row[c] == '#':
                start = c
                while c + 1 < len(row) and row[c + 1] == '#':
                    c += 1
                yield r, start, c
            c += 1


def rect(grid, r, a, b):
    """Clockwise corners of a run (font units, y up)."""
    x0 = grid['x'] + grid['dx'] * a
    x1 = grid['x'] + grid['dx'] * b + grid['size']
    y0 = grid['y'] + grid['dy'] * (6 - r)
    y1 = y0 + grid['size']
    return [(x0, y0), (x0, y1), (x1, y1), (x1, y0)]


def main():
    font = TTFont(FONT)
    cmap = font.getBestCmap()
    glyf, gvar, hmtx = font['glyf'], font['gvar'], font['hmtx']
    for char, rows in DIGITS.items():
        name = cmap[ord(char)]
        pen = TTGlyphPen(None)
        deltas = []
        for r, a, b in runs(rows):
            regular = [(round(x), round(y)) for x, y in rect(REGULAR, r, a, b)]
            bold = [(round(x), round(y)) for x, y in rect(BOLD, r, a, b)]
            pen.moveTo(regular[0])
            for point in regular[1:]:
                pen.lineTo(point)
            pen.closePath()
            deltas += [(bx - x, by - y) for (x, y), (bx, by) in zip(regular, bold)]
        glyph = pen.glyph()
        glyph.flags[0] |= 0x40  # OVERLAP_SIMPLE: runs overlap their neighbours
        glyph.recalcBounds(glyf)
        glyf[name] = glyph
        advance, _ = hmtx[name]
        hmtx[name] = (advance, glyph.xMin)
        phantoms = [None, (BOLD_EXTRA_ADVANCE, 0), None, None]
        gvar.variations[name] = [TupleVariation({'wght': (0.0, 1.0, 1.0)}, deltas + phantoms)]
    font.save(FONT)
    print(f'Redrew digits {"".join(DIGITS)} in {FONT.name}')


if __name__ == '__main__':
    main()
