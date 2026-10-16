#!/usr/bin/env python3
"""Flappy Silly Cat + Subway Silly için 8-bit ses efektleri üreticisi.

Bağımlılıksız (yalnız standart kütüphane). Tüm efektler 44.1 kHz, mono,
16-bit WAV olarak `assets/sfx/` içine yazılır; tekrar çalıştırmak aynı
dosyaları (sabit tohumla) üretir.

    python3 tools/game_sfx.py
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'sfx')
SR = 44100


def square(phase, duty=0.5):
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase):
    p = phase % 1.0
    return 4 * p - 1 if p < 0.5 else 3 - 4 * p


def tone(dur, f0, f1=None, wave_fn=square, duty=0.5, vol=0.5,
         attack=0.004, release=None, curve=1.0, vibrato=0.0):
    """Frekansı f0→f1 kayan (curve üssüyle) tek ses."""
    f1 = f0 if f1 is None else f1
    n = int(dur * SR)
    release = dur * 0.6 if release is None else release
    out, phase = [], 0.0
    for i in range(n):
        t = i / SR
        k = (t / dur) ** curve
        f = f0 + (f1 - f0) * k
        if vibrato:
            f *= 1 + vibrato * math.sin(2 * math.pi * 18 * t)
        phase += f / SR
        s = wave_fn(phase, duty) if wave_fn is square else wave_fn(phase)
        env = min(1.0, t / attack) if attack else 1.0
        if t > dur - release:
            env *= max(0.0, (dur - t) / release)
        out.append(s * env * vol)
    return out


def noise(dur, vol=0.5, decay=8.0, lowpass=0.5, seed=1):
    rng = random.Random(seed)
    n = int(dur * SR)
    out, last = [], 0.0
    for i in range(n):
        t = i / SR
        last += (rng.uniform(-1, 1) - last) * lowpass
        out.append(last * vol * math.exp(-decay * t))
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    n = max(int(o * SR) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * n
    for t, o in zip(tracks, offsets):
        s = int(o * SR)
        for i, v in enumerate(t):
            out[s + i] += v
    return out


def seq(*notes, gap=0.0):
    out = []
    for n in notes:
        out += n + [0.0] * int(gap * SR)
    return out


def write(name, samples, gain=0.85):
    peak = max(1e-9, max(abs(v) for v in samples))
    k = gain / peak if peak > gain else 1.0
    # Klik olmasın: son 3 ms'yi sıfıra indir.
    fade = int(0.003 * SR)
    for i in range(1, min(fade, len(samples)) + 1):
        samples[-i] *= i / fade
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, v * k)) * 32767)) for v in samples))
    return path


def note(n):
    """MIDI notası → Hz."""
    return 440.0 * 2 ** ((n - 69) / 12)


EFFECTS = {
    # Flappy: hafif kanat "fıp" (yukarı süpürme + nefes gürültüsü).
    'flap': lambda: mix(
        tone(0.09, 380, 820, duty=0.25, vol=0.30, curve=0.6),
        noise(0.08, vol=0.18, decay=30, lowpass=0.35, seed=3)),
    # Boru geçildi: klasik iki notalı "ding".
    'point': lambda: seq(
        tone(0.06, note(83), duty=0.5, vol=0.35, release=0.02),
        tone(0.16, note(88), duty=0.5, vol=0.35, release=0.12)),
    # Çarpma: alçak darbe + gürültü.
    'hit': lambda: mix(
        tone(0.18, 220, 55, duty=0.5, vol=0.55, curve=0.5),
        noise(0.16, vol=0.55, decay=22, lowpass=0.6, seed=5)),
    # Düşüş ıslığı (çarpmadan sonra yere iniş).
    'fall': lambda: tone(0.42, 900, 160, wave_fn=triangle, vol=0.35, curve=0.8),
    # Altın balık / coin: parlak iki nota arpej.
    'coin': lambda: seq(
        tone(0.045, note(88), duty=0.5, vol=0.28, release=0.01),
        tone(0.12, note(95), duty=0.5, vol=0.28, release=0.1)),
    # Zıplama: yükselen kare.
    'jump': lambda: tone(0.16, 260, 640, duty=0.5, vol=0.32, curve=0.7),
    # Kayma: kısa gürültü süpürmesi.
    'slide': lambda: mix(
        noise(0.22, vol=0.4, decay=9, lowpass=0.12, seed=7),
        tone(0.2, 300, 150, wave_fn=triangle, vol=0.12)),
    # Şerit değiştirme: çok kısa hava "fşş".
    'swoosh': lambda: noise(0.1, vol=0.3, decay=26, lowpass=0.22, seed=11),
    # Yere/trene iniş.
    'land': lambda: mix(
        tone(0.06, 160, 90, duty=0.5, vol=0.3),
        noise(0.05, vol=0.2, decay=50, lowpass=0.3, seed=13)),
    # Güçlendirme alındı: hızlı yükselen arpej.
    'power': lambda: seq(*[
        tone(0.05, note(n), duty=0.25, vol=0.3, release=0.015)
        for n in (72, 76, 79, 84, 88, 91)]) + tone(0.2, note(96), duty=0.25, vol=0.3, vibrato=0.01),
    # Tökezleme (yan çarpma): kısa "bonk" + ikinci yarım.
    'stumble': lambda: mix(
        tone(0.12, 330, 140, duty=0.5, vol=0.45),
        noise(0.1, vol=0.3, decay=30, lowpass=0.5, seed=17)),
    # Yakalandın / tren çarpması: alçalan üç nota + gürültü.
    'crash': lambda: mix(
        seq(tone(0.12, note(64), duty=0.5, vol=0.4, release=0.04),
            tone(0.12, note(60), duty=0.5, vol=0.4, release=0.04),
            tone(0.32, note(52), duty=0.5, vol=0.4, vibrato=0.02)),
        noise(0.25, vol=0.5, decay=14, lowpass=0.55, seed=19)),
    # Madalya / rekor: kısa fanfar.
    'medal': lambda: seq(
        tone(0.09, note(72), vol=0.3, release=0.03),
        tone(0.09, note(76), vol=0.3, release=0.03),
        tone(0.09, note(79), vol=0.3, release=0.03),
        tone(0.34, note(84), vol=0.3, vibrato=0.012)),
    # Güçlendirme bitiyor.
    'powerdown': lambda: seq(*[
        tone(0.06, note(n), duty=0.25, vol=0.25, release=0.02) for n in (84, 79, 76, 72)]),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, make in EFFECTS.items():
        path = write(name, make())
        with wave.open(path) as w:
            dur = w.getnframes() / SR
        print(f'{name:10s} {dur:5.2f}s  {os.path.getsize(path) / 1024:5.1f} KB')


if __name__ == '__main__':
    main()
