'use strict';
/*
 * Özetler + Apple Pencil not modu.
 *
 * Flutter'ın üstünde tam ekran bir DOM katmanıdır (gecikme için Flutter'ın
 * kare zamanlamasına girmez). Sayfa 1180 birim genişliğinde sabit bir kâğıttır;
 * notlar bu birimlerde vektör olarak saklanır (IndexedDB) ve SVG ile çizilir,
 * böylece her yakınlaştırmada keskin kalır.
 *
 *  - Kalem (pointerType 'pen', fare de) yazar; parmak kaydırır, iki parmak
 *    yakınlaştırır. İki parmakla dokunma geri alır, üç parmak yineler; tek
 *    parmakla çift dokunma yakınlaştırır.
 *  - Çizilen çizgi canlı bir SVG katmanında anlık çizilir; bırakınca aynı dış
 *    hat kalıcı katmana geçer (görünüm sıçramaz).
 *  - Avuç içi: kalem yazarken ve büyük temas alanlı dokunuşlarda kaydırma yok.
 *  - Her kayıtta sayfanın blok düzeni ("temel") de saklanır. Özet metni ya da
 *    yerleşimi değişirse notlar ait oldukları bloğun yeni yerine taşınır
 *    (bkz. remap). Temelden önceki kayıtlar için ilk sürümün metni
 *    summaries/<id>.v1.js dosyasında dondurulmuştur.
 *
 * window.hukukInkGeom: saf geometri (Node testleri bunu kullanır).
 * window.hukukNotesOpen(id) → Promise<'closed'>: Flutter köprüsü.
 * window.hukukNotesRegister(summary): özet içerik dosyaları çağırır.
 */
(() => {
  // ═════════════════════════ Geometri ═════════════════════════
  const PAGE_W = 1180;
  const MARGIN = 180;
  const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
  const rd = v => Math.round(v * 100) / 100;

  /** Kalemde basınca göre yarıçap; fosforlu kalem sabit genişliktedir. */
  function radius(tool, w, p) {
    if (tool === 'hl') return w / 2;
    return (w / 2) * (0.22 + 1.1 * Math.pow(clamp(p, 0, 1), 0.85));
  }

  /** Noktaları üç bileşenli düz diziye ([x,y,p,...]) ekleyen yumuşatıcı. */
  function builder(minDist) {
    const pts = [];
    let lx = 0, ly = 0, lp = 0.5, has = false;
    return {
      pts,
      /** streamline: 0 = ham, 1 = hiç hareket etmez. */
      add(x, y, p, streamline) {
        if (!has) {
          pts.push(rd(x), rd(y), rd(p));
          lx = x; ly = y; lp = p; has = true;
          return true;
        }
        const s = streamline || 0;
        const nx = lx + (x - lx) * (1 - s);
        const ny = ly + (y - ly) * (1 - s);
        const np = lp + (p - lp) * 0.45;
        if (Math.hypot(nx - lx, ny - ly) < minDist) {
          // Yerinde bastırma: yalnız basıncı güncelle (nokta kalınlaşır).
          if (pts.length && np > pts[pts.length - 1]) pts[pts.length - 1] = rd(np);
          lp = np;
          return false;
        }
        pts.push(rd(nx), rd(ny), rd(np));
        lx = nx; ly = ny; lp = np;
        return true;
      },
    };
  }

  // Yollar 10 kat ölçekte tam sayılarla üretilir (SVG'de scale(0.1) ile çizilir):
  // 0,1 birim hassasiyet 5x yakınlaştırmada bile yarım pikselden az; tam sayıyı
  // metne çevirmek ondalığa göre çok hızlıdır ve dize kısalır.
  const PATH_SCALE = 0.1;
  const r1 = v => Math.round(v * 10);

  /** xy kenarı boyunca orta noktalardan geçen ikinci derece eğriler. */
  function smoothSide(xy, n, from, step) {
    let d = '';
    for (let k = 1; k < n - 1; k++) {
      const i = from + k * step, j = i + step;
      const x = xy[2 * i], y = xy[2 * i + 1];
      d += 'Q' + r1(x) + ' ' + r1(y) + ' ' + r1((x + xy[2 * j]) / 2) + ' ' + r1((y + xy[2 * j + 1]) / 2);
    }
    const e = from + (n - 1) * step;
    return d + 'L' + r1(xy[2 * e]) + ' ' + r1(xy[2 * e + 1]);
  }

  /**
   * Değişken kalınlıklı çizginin dış hattı (SVG path). Aynı dize hem anlık
   * katmanda hem kalıcı katmanda kullanılır. extra: yalnız anlık çizimde tahmin noktaları.
   */
  function outline(tool, w, pts, extra) {
    const base = pts.length / 3, more = extra ? extra.length / 3 : 0;
    const n = base + more;
    if (!n) return '';
    const P = i => (i < base ? pts : extra);
    const o = i => (i < base ? 3 * i : 3 * (i - base));
    const xs = new Float64Array(n), ys = new Float64Array(n), rs = new Float64Array(n);
    let minx = Infinity, maxx = -Infinity, miny = Infinity, maxy = -Infinity, maxr = 0;
    for (let i = 0; i < n; i++) {
      const a = P(i), k = o(i);
      const x = a[k], y = a[k + 1], r = radius(tool, w, a[k + 2]);
      xs[i] = x; ys[i] = y; rs[i] = r;
      if (x < minx) minx = x; if (x > maxx) maxx = x;
      if (y < miny) miny = y; if (y > maxy) maxy = y;
      if (r > maxr) maxr = r;
    }
    if (n === 1 || Math.max(maxx - minx, maxy - miny) < maxr * 0.25) {
      const x = (minx + maxx) / 2, y = (miny + maxy) / 2, rr = Math.max(maxr, 0.4), r = r1(rr);
      return 'M' + r1(x - rr) + ' ' + r1(y) + 'A' + r + ' ' + r + ' 0 1 0 ' + r1(x + rr) + ' ' + r1(y) +
        'A' + r + ' ' + r + ' 0 1 0 ' + r1(x - rr) + ' ' + r1(y) + 'Z';
    }
    // L: sol kenar (0..n-1), R: sağ kenar; tek dizide [L..., R...].
    const E = new Float64Array(4 * n);
    let ptx = 1, pty = 0;
    for (let i = 0; i < n; i++) {
      const a = i > 0 ? i - 1 : 0, b = i < n - 1 ? i + 1 : n - 1;
      let tx = xs[b] - xs[a], ty = ys[b] - ys[a];
      const len = Math.hypot(tx, ty);
      if (len < 1e-6) { tx = ptx; ty = pty; } else { tx /= len; ty /= len; }
      ptx = tx; pty = ty;
      const r = rs[i];
      E[2 * i] = xs[i] - ty * r; E[2 * i + 1] = ys[i] + tx * r;
      E[2 * (n + i)] = xs[i] + ty * r; E[2 * (n + i) + 1] = ys[i] - tx * r;
    }
    const re = r1(rs[n - 1]), r0 = r1(rs[0]);
    return 'M' + r1(E[0]) + ' ' + r1(E[1]) + smoothSide(E, n, 0, 1) +
      'A' + re + ' ' + re + ' 0 0 0 ' + r1(E[2 * (2 * n - 1)]) + ' ' + r1(E[2 * (2 * n - 1) + 1]) +
      smoothSide(E, n, 2 * n - 1, -1) +
      'A' + r0 + ' ' + r0 + ' 0 0 0 ' + r1(E[0]) + ' ' + r1(E[1]) + 'Z';
  }

  function bounds(s) {
    const p = s.p;
    let minx = Infinity, miny = Infinity, maxx = -Infinity, maxy = -Infinity, maxr = 0;
    for (let i = 0; i < p.length; i += 3) {
      if (p[i] < minx) minx = p[i]; if (p[i] > maxx) maxx = p[i];
      if (p[i + 1] < miny) miny = p[i + 1]; if (p[i + 1] > maxy) maxy = p[i + 1];
      const r = radius(s.t, s.w, p[i + 2]); if (r > maxr) maxr = r;
    }
    return [minx - maxr, miny - maxr, maxx + maxr, maxy + maxr];
  }

  function distSeg(px, py, ax, ay, bx, by) {
    const dx = bx - ax, dy = by - ay;
    const l2 = dx * dx + dy * dy;
    let t = l2 ? ((px - ax) * dx + (py - ay) * dy) / l2 : 0;
    t = clamp(t, 0, 1);
    return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
  }

  /** Silgi dairesi çizgiye değiyor mu? */
  function hits(s, cx, cy, er) {
    const b = s.b || (s.b = bounds(s));
    if (cx + er < b[0] || cx - er > b[2] || cy + er < b[1] || cy - er > b[3]) return false;
    const p = s.p;
    if (p.length === 3) return Math.hypot(p[0] - cx, p[1] - cy) <= er + radius(s.t, s.w, p[2]);
    for (let i = 0; i + 3 < p.length; i += 3) {
      const r = radius(s.t, s.w, Math.max(p[i + 2], p[i + 5]));
      if (distSeg(cx, cy, p[i], p[i + 1], p[i + 3], p[i + 4]) <= er + r) return true;
    }
    return false;
  }

  /**
   * Hassas silgi: silgi içinde kalan noktaları çıkarır, çizgiyi parçalara böler.
   * Değmiyorsa null; değiyorsa kalan parçaların nokta dizileri (boş olabilir).
   */
  function eraseSplit(s, cx, cy, er) {
    if (!hits(s, cx, cy, er)) return null;
    const p = s.p, runs = [];
    let cur = [];
    for (let i = 0; i < p.length; i += 3) {
      const r = radius(s.t, s.w, p[i + 2]);
      const gone = Math.hypot(p[i] - cx, p[i + 1] - cy) <= er + r * 0.5;
      if (gone) { if (cur.length) runs.push(cur); cur = []; } else cur.push(p[i], p[i + 1], p[i + 2]);
    }
    if (cur.length) runs.push(cur);
    // Hiç nokta silinmediyse (yalnız kenarı değdiyse) çizgiyi koru.
    const kept = runs.reduce((a, r) => a + r.length, 0);
    if (kept === p.length) return null;
    // Tek noktalık kırıntılar, çizgi zaten nokta değilse atılır.
    return runs.filter(r => r.length >= 6 || p.length === 3);
  }

  function pointInPoly(x, y, poly) {
    let inside = false;
    for (let i = 0, j = poly.length - 2; i < poly.length; j = i, i += 2) {
      const xi = poly[i], yi = poly[i + 1], xj = poly[j], yj = poly[j + 1];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
    return inside;
  }

  /** Kement: noktalarının en az yarısı çokgen içinde kalan çizgiler. */
  function lassoSelect(strokes, poly) {
    if (poly.length < 6) return [];
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (let i = 0; i < poly.length; i += 2) {
      if (poly[i] < x0) x0 = poly[i]; if (poly[i] > x1) x1 = poly[i];
      if (poly[i + 1] < y0) y0 = poly[i + 1]; if (poly[i + 1] > y1) y1 = poly[i + 1];
    }
    const ids = [];
    for (const s of strokes) {
      // Kementin dış kutusuna değmeyen çizgilerin noktaları hiç sınanmaz.
      const b = s.b || (s.b = bounds(s));
      if (b[2] < x0 || b[0] > x1 || b[3] < y0 || b[1] > y1) continue;
      const p = s.p;
      let inside = 0;
      const total = p.length / 3;
      for (let i = 0; i < p.length; i += 3) if (pointInPoly(p[i], p[i + 1], poly)) inside++;
      if (inside > 0 && inside * 2 >= total) ids.push(s.id);
    }
    return ids;
  }

  function translated(s, dx, dy) {
    const p = s.p.slice();
    for (let i = 0; i < p.length; i += 3) { p[i] = rd(p[i] + dx); p[i + 1] = rd(p[i + 1] + dy); }
    return { id: s.id, t: s.t, c: s.c, w: s.w, p };
  }

  /** (ax, ay) noktasına göre k kat büyütür; kalınlık da aynı oranda değişir. */
  function scaled(s, ax, ay, k) {
    const p = s.p.slice();
    for (let i = 0; i < p.length; i += 3) { p[i] = rd(ax + (p[i] - ax) * k); p[i + 1] = rd(ay + (p[i + 1] - ay) * k); }
    return { id: s.id, t: s.t, c: s.c, w: rd(clamp(s.w * k, 0.3, 79)), p };
  }

  /** İki uç arası düz çizgi (silgi ve kement için sık noktalı). */
  function lineBetween(x0, y0, x1, y1, p) {
    const len = Math.hypot(x1 - x0, y1 - y0);
    const n = Math.max(2, Math.ceil(len / 3) + 1);
    const out = [];
    for (let i = 0; i < n; i++) {
      const t = i / (n - 1);
      out.push(rd(x0 + (x1 - x0) * t), rd(y0 + (y1 - y0) * t), rd(p));
    }
    return out;
  }

  /** Çizgi kabaca düz mü? (uçlara uzaklığın en fazla %10'u kadar sapma) */
  function nearlyStraight(p) {
    const n = p.length / 3;
    if (n < 3) return false;
    const x0 = p[0], y0 = p[1], x1 = p[p.length - 3], y1 = p[p.length - 2];
    const len = Math.hypot(x1 - x0, y1 - y0);
    if (len < 24) return false;
    let dev = 0;
    for (let i = 0; i < p.length; i += 3) dev = Math.max(dev, distSeg(p[i], p[i + 1], x0, y0, x1, y1));
    return dev <= len * 0.1;
  }

  /**
   * Fosforlu kalem: kabaca yatay bir çizgiyi düz yatay çizgiye çevirir; altında
   * bir metin satırı varsa satırın ortasına hizalar. lines: satır kutuları
   * [x0,y0,x1,y1,...] (sayfa birimi). Yatay değilse (daire, karalama) null.
   */
  function straightenHl(p, lines) {
    const n = p.length / 3;
    if (n < 2) return null;
    let minx = Infinity, maxx = -Infinity, sy = 0, sp = 0;
    for (let i = 0; i < p.length; i += 3) {
      if (p[i] < minx) minx = p[i]; if (p[i] > maxx) maxx = p[i];
      sy += p[i + 1]; sp += p[i + 2];
    }
    const len = maxx - minx;
    if (len < 30) return null;
    const ym = sy / n;
    let dev = 0;
    for (let i = 1; i < p.length; i += 3) dev = Math.max(dev, Math.abs(p[i] - ym));
    if (dev > Math.max(7, len * 0.14)) return null;
    let y = ym;
    if (lines && lines.length) {
      let bd = Infinity;
      for (let k = 0; k < lines.length; k += 4) {
        const ly0 = lines[k + 1], ly1 = lines[k + 3];
        if (ly1 < ym - 60 || ly0 > ym + 60) continue;
        const ov = Math.min(maxx, lines[k + 2]) - Math.max(minx, lines[k]);
        if (ov < Math.min(20, len * 0.3)) continue;
        const c = (ly0 + ly1) / 2, d = Math.abs(c - ym);
        if (d <= Math.max(8, (ly1 - ly0) * 0.7) && d < bd) { bd = d; y = c; }
      }
    }
    return lineBetween(minx, y, maxx, y, sp / n);
  }

  /** Geri al/yinele: {before: silinen çizgiler, after: eklenen çizgiler}. */
  function applyOp(strokes, op, reverse) {
    const remove = reverse ? op.after : op.before;
    const add = reverse ? op.before : op.after;
    const gone = new Set(remove.map(s => s.id));
    const next = strokes.filter(s => !gone.has(s.id));
    for (const s of add) next.push(s);
    return next;
  }

  // ───────── Özet değişince notları taşıma ─────────
  // Temel (basis): sayfadaki her bloğun anahtarı ve kutusu. Anahtar = bölüm
  // kimliği | etiket.sınıf | metnin özeti. Eski ve yeni temel bölüm bölüm en
  // uzun ortak alt dizi ile eşlenir; değişmeyen bloklar "çapa" olur.

  /** 32 bit FNV-1a, 36 tabanında. */
  function hash(str) {
    let h = 0x811c9dc5;
    for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 0x01000193); }
    return (h >>> 0).toString(36);
  }

  /** Kayıttaki sıkıştırılmış temeli ({k: '\n' ile anahtarlar, r: x,y,w,h, end}) açar. */
  function parseBasis(raw) {
    if (!raw || typeof raw !== 'object' || typeof raw.k !== 'string') return null;
    const keys = raw.k ? raw.k.split('\n') : [];
    const r = ArrayBuffer.isView(raw.r) || Array.isArray(raw.r) ? raw.r : null;
    const end = Number(raw.end);
    if (!r || keys.length > 50000 || r.length !== keys.length * 4 || !(end > 0 && end < 1e6)) return null;
    const out = new Float64Array(r.length);
    for (let i = 0; i < r.length; i++) { const v = Number(r[i]); if (!Number.isFinite(v)) return null; out[i] = v; }
    return { keys, r: out, end };
  }
  function packBasis(b) { return { k: b.keys.join('\n'), r: Float32Array.from(b.r), end: b.end }; }

  function sameBasis(a, b) {
    if (!a || !b || a.keys.length !== b.keys.length || Math.abs(a.end - b.end) > 0.75) return false;
    for (let i = 0; i < a.keys.length; i++) if (a.keys[i] !== b.keys[i]) return false;
    for (let i = 0; i < a.r.length; i++) if (Math.abs(a.r[i] - b.r[i]) > 0.75) return false;
    return true;
  }

  /** ia/ib dizinlerindeki anahtarlar için en uzun ortak alt dizi; eşleşmeleri m'ye yazar. */
  function lcsInto(ia, ib, ka, kb, m) {
    let s = 0;
    while (s < ia.length && s < ib.length && ka[ia[s]] === kb[ib[s]]) { m[ia[s]] = ib[s]; s++; }
    let ea = ia.length, eb = ib.length;
    while (ea > s && eb > s && ka[ia[ea - 1]] === kb[ib[eb - 1]]) { ea--; eb--; m[ia[ea]] = ib[eb]; }
    const n = ea - s, q = eb - s;
    if (!n || !q || n * q > 4e6) return;
    const W = q + 1;
    const T = new Uint16Array((n + 1) * W);
    for (let i = n - 1; i >= 0; i--) {
      const ki = ka[ia[s + i]];
      for (let j = q - 1; j >= 0; j--) {
        T[i * W + j] = ki === kb[ib[s + j]] ? T[(i + 1) * W + j + 1] + 1 : Math.max(T[(i + 1) * W + j], T[i * W + j + 1]);
      }
    }
    for (let i = 0, j = 0; i < n && j < q;) {
      if (ka[ia[s + i]] === kb[ib[s + j]]) { m[ia[s + i]] = ib[s + j]; i++; j++; }
      else if (T[(i + 1) * W + j] >= T[i * W + j + 1]) i++;
      else j++;
    }
  }

  /** Eski temelin her bloğu için yeni temeldeki karşılığı (yoksa -1). */
  function matchBlocks(a, b) {
    const m = new Int32Array(a.keys.length).fill(-1);
    const groups = keys => {
      const g = new Map();
      keys.forEach((k, i) => {
        const sec = k.slice(0, k.indexOf('|'));
        if (!g.has(sec)) g.set(sec, []);
        g.get(sec).push(i);
      });
      return g;
    };
    const gb = groups(b.keys);
    for (const [sec, ia] of groups(a.keys)) {
      const ib = gb.get(sec);
      if (ib) lcsInto(ia, ib, a.keys, b.keys, m);
    }
    return m;
  }

  /** Azalmayan en uzun alt dizinin indisleri. */
  function lisIdx(vals) {
    const tails = [], prev = new Int32Array(vals.length).fill(-1);
    for (let i = 0; i < vals.length; i++) {
      let lo = 0, hi = tails.length;
      while (lo < hi) { const mid = (lo + hi) >> 1; if (vals[tails[mid]] <= vals[i]) lo = mid + 1; else hi = mid; }
      if (lo > 0) prev[i] = tails[lo - 1];
      tails[lo] = i;
    }
    const out = [];
    for (let k = tails.length ? tails[tails.length - 1] : -1; k >= 0; k = prev[k]) out.push(k);
    return out.reverse();
  }

  /** Eşleşen blokların üst/alt kenarlarından tekdüze, parçalı doğrusal y eşlemesi. */
  function yMap(a, b, m) {
    const P = [[0, 0]];
    for (let i = 0; i < m.length; i++) {
      const j = m[i];
      if (j < 0) continue;
      P.push([a.r[4 * i + 1], b.r[4 * j + 1]], [a.r[4 * i + 1] + a.r[4 * i + 3], b.r[4 * j + 1] + b.r[4 * j + 3]]);
    }
    P.push([a.end, b.end]);
    P.sort((p, q) => p[0] - q[0] || p[1] - q[1]);
    const xs = [], ys = [];
    for (const k of lisIdx(P.map(p => p[1]))) {
      if (xs.length && P[k][0] <= xs[xs.length - 1]) continue;
      xs.push(P[k][0]); ys.push(P[k][1]);
    }
    const n = xs.length;
    return y => {
      if (y <= xs[0]) return y + ys[0] - xs[0];
      if (y >= xs[n - 1]) return y + ys[n - 1] - xs[n - 1];
      let lo = 0, hi = n - 1;
      while (hi - lo > 1) { const mid = (lo + hi) >> 1; if (xs[mid] <= y) lo = mid; else hi = mid; }
      return ys[lo] + (ys[hi] - ys[lo]) * (y - xs[lo]) / (xs[hi] - xs[lo]);
    };
  }

  /**
   * Çizginin ait olduğu eşleşmiş blok. Metin sütunundaki çizgi: merkezini
   * içeren en küçük blok. Kenar boşluğundaki not: aynı yükseklikteki bloklardan
   * yatayda en yakın ve en ince olanı. Önce tam, sonra 10 birim payla aranır.
   */
  function ownerOf(a, cand, cx, cy, inContent) {
    for (const pad of [0, 10]) {
      let best = -1, score = Infinity;
      for (const i of cand) {
        const x = a.r[4 * i], y = a.r[4 * i + 1], w = a.r[4 * i + 2], h = a.r[4 * i + 3];
        if (cy < y - pad || cy > y + h + pad) continue;
        let sc;
        if (inContent) {
          if (cx < x - pad || cx > x + w + pad) continue;
          sc = w * h;
        } else sc = (cx < x ? x - cx : cx > x + w ? cx - x - w : 0) + 0.25 * h;
        if (sc < score) { score = sc; best = i; }
      }
      if (best >= 0) return best;
    }
    return -1;
  }

  /**
   * Notları eski düzenden (a) yeni düzene (b) taşır. Her çizgi ait olduğu
   * değişmemiş bloğun kayması kadar kaydırılır (şekli bozulmaz); bloğu
   * değiştiyse komşu blokların kaymasından aradeğer alınır. Sayfa sonundaki not
   * alanı içeriğin sonuyla birlikte kayar.
   */
  function remap(strokes, a, b) {
    if (!a || !b || sameBasis(a, b)) return { strokes, moved: 0 };
    const m = matchBlocks(a, b);
    const f = yMap(a, b, m);
    const cand = [];
    for (let i = 0; i < m.length; i++) if (m[i] >= 0) cand.push(i);
    const out = [];
    let moved = 0;
    for (const s of strokes) {
      const bb = s.b || bounds(s);
      const cx = (bb[0] + bb[2]) / 2, cy = (bb[1] + bb[3]) / 2;
      const inContent = cx >= MARGIN && cx <= PAGE_W - MARGIN;
      const own = cy <= a.end ? ownerOf(a, cand, cx, cy, inContent) : -1;
      let dx = 0, dy;
      if (own >= 0) {
        const j = m[own];
        dy = b.r[4 * j + 1] - a.r[4 * own + 1];
        if (inContent) dx = b.r[4 * j] - a.r[4 * own];
      } else dy = f(cy) - cy;
      if (bb[1] + dy < 0) dy = -bb[1];
      if (Math.abs(dx) < 0.01 && Math.abs(dy) < 0.01) { out.push(s); continue; }
      moved++;
      out.push(translated(s, dx, dy));
    }
    return { strokes: out, moved };
  }

  /**
   * Yazdırma için sayfa sonları: [0, y1, y2, ..., H]. Her sayfa en fazla Hp
   * yüksekliğindedir; kesim, iv'deki aralıkların ([a0,b0,a1,b1,...]) içine
   * düşmeyecek biçimde mümkün olan en aşağıda yapılır. Sayfanın en az %55'i
   * dolmadan uygun yer yoksa satır bölünür.
   */
  function pageBreaks(H, Hp, iv) {
    H = Math.ceil(H);
    if (!(Hp > 10)) return [0, H];
    const bad = new Uint8Array(H + 2);
    for (let k = 0; k + 1 < iv.length; k += 2) {
      const a = Math.max(0, Math.ceil(iv[k]) + 1), b = Math.min(H, Math.floor(iv[k + 1]) - 1);
      for (let y = a; y <= b; y++) bad[y] = 1;
    }
    const out = [0];
    let y0 = 0;
    while (H - y0 > Hp) {
      const hi = Math.floor(y0 + Hp), lo = Math.ceil(y0 + Hp * 0.55);
      let y = hi;
      while (y >= lo && bad[y]) y--;
      if (y < lo) y = hi;
      out.push(y);
      y0 = y;
    }
    out.push(H);
    return out;
  }

  // Arama: Türkçe büyük/küçük harf ve şapka/nokta farkı gözetmez. Her karakter
  // tek karaktere katlanır; böylece eşleşmenin metindeki yeri doğrudan bulunur.
  const FOLD = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u', 'â': 'a', 'î': 'i', 'û': 'u',
    'é': 'e', 'è': 'e', 'á': 'a', 'à': 'a', 'ó': 'o', 'í': 'i', 'ú': 'u',
    '’': "'", '‘': "'", '“': '"', '”': '"', '–': '-', '—': '-',
  };
  function foldChar(ch) {
    let l = ch.toLocaleLowerCase('tr');
    if (l.length !== 1) { l = ch.toLowerCase(); if (l.length !== 1) l = ch; }
    return FOLD[l] || l;
  }
  const isSpace = c => c <= ' ' || c === '\u00a0';
  function fold(str) {
    let out = '';
    for (let i = 0; i < str.length; i++) {
      const c = str[i];
      if (isSpace(c)) { if (out && out[out.length - 1] !== ' ') out += ' '; continue; }
      out += foldChar(c);
    }
    return out.trim();
  }

  /** Yedek/IndexedDB'den gelen belgeyi doğrular; bozuk çizgileri atar. */
  function sanitizeDoc(raw) {
    const doc = { v: 2, strokes: [], extra: 0, basis: null, sv: 0, updated: 0, edited: 0, partial: false };
    if (!raw || typeof raw !== 'object') return doc;
    doc.extra = clamp(Number(raw.extra) || 0, 0, 20000);
    doc.basis = parseBasis(raw.basis);
    const sv = Number(raw.sv);
    doc.sv = Number.isInteger(sv) && sv > 0 && sv < 10000 ? sv : 0;
    doc.updated = Number(raw.updated) || 0;
    // Son düzenleme: taşıma ya da birleştirme için yapılan kayıtlar bunu değiştirmez.
    doc.edited = Number(raw.edited) > 0 ? Number(raw.edited) : doc.updated;
    doc.partial = raw.partial === true;
    const list = Array.isArray(raw.strokes) ? raw.strokes : [];
    for (const s of list) {
      if (!s || (s.t !== 'pen' && s.t !== 'hl')) continue;
      if (typeof s.c !== 'string' || !/^#[0-9a-fA-F]{6}$/.test(s.c)) continue;
      const w = Number(s.w);
      const pts = ArrayBuffer.isView(s.p) ? Array.from(s.p) : s.p;
      if (!(w > 0 && w < 80) || !Array.isArray(pts) || !pts.length || pts.length % 3) continue;
      if (!pts.every(Number.isFinite)) continue;
      doc.strokes.push({ id: String(s.id || ''), t: s.t, c: s.c, w, p: pts.map(rd) });
    }
    let n = 0;
    const seen = new Set();
    for (const s of doc.strokes) { if (!s.id || seen.has(s.id)) s.id = 'r' + (n++) + '_' + Math.random().toString(36).slice(2, 8); seen.add(s.id); }
    return doc;
  }

  const G = {
    PAGE_W, MARGIN, PATH_SCALE, radius, builder, outline, bounds, hits, eraseSplit, pointInPoly,
    lassoSelect, translated, scaled, lineBetween, nearlyStraight, straightenHl, applyOp, sanitizeDoc,
    hash, parseBasis, packBasis, sameBasis, matchBlocks, remap, pageBreaks, fold,
  };
  window.hukukInkGeom = G;

  // ═════════════════════════ Özet kayıt defteri ═════════════════════════
  // Güncel özet 'id' ve 'id@sürüm' altında; dondurulmuş eski sürümler (legacy)
  // yalnız 'id@sürüm' altında tutulur, güncel olanın yerini almaz.
  const summaries = {};
  const waiting = {};
  const loading = {};
  window.hukukNotesRegister = s => {
    if (!s || !s.id || typeof s.html !== 'string') return;
    const keys = [s.id + '@' + s.version];
    if (!s.legacy) keys.push(s.id);
    for (const k of keys) {
      summaries[k] = s;
      if (waiting[k]) { waiting[k](s); delete waiting[k]; }
    }
  };
  function loadSummary(id, version) {
    const key = version ? id + '@' + version : id;
    if (summaries[key]) return Promise.resolve(summaries[key]);
    if (loading[key]) return loading[key];
    if (!/^[a-z0-9-]+$/.test(id) || (version && !/^\d{1,4}$/.test(String(version)))) return Promise.reject(new Error('Özet bulunamadı.'));
    const tag = document.createElement('script');
    const p = new Promise((resolve, reject) => {
      waiting[key] = resolve;
      tag.src = 'notes/summaries/' + id + (version ? '.v' + version : '') + '.js';
      tag.onload = () => { if (!summaries[key]) reject(new Error('Özet dosyası okunamadı.')); };
      tag.onerror = () => reject(new Error(version
        ? 'Notları yeni sürüme taşımak için gereken dosya yüklenemedi. Bağlantını kontrol edip tekrar dene.'
        : 'Özet yüklenemedi. Bağlantını kontrol edip tekrar dene.'));
      document.head.appendChild(tag);
    });
    loading[key] = p;
    p.catch(() => { delete waiting[key]; tag.remove(); }).finally(() => { delete loading[key]; });
    return p;
  }

  // ═════════════════════════ Depolama ═════════════════════════
  // Asıl kayıt IndexedDB'de. IndexedDB yazamazsa ya da okunamadıysa belge
  // localStorage'a da yazılır ('hukuk-notes:<id>'). Okunamadığı sırada yazılan
  // kopya "partial" işaretlidir: sonraki açılışta asıl kayıtla birleştirilir.
  // IndexedDB okunamadan boş belge asla asıl kaydın üstüne yazılmaz.
  const store = (() => {
    let dbp = null;
    function openDb() {
      return new Promise((resolve, reject) => {
        if (typeof indexedDB === 'undefined' || !indexedDB) { reject(new Error('no idb')); return; }
        let done = false, tries = 0, timer = 0;
        const finish = (err, d) => {
          if (done) { if (d) try { d.close(); } catch (_) {} return; }
          done = true;
          clearTimeout(timer);
          if (err) reject(err); else resolve(d);
        };
        const attempt = () => {
          tries++;
          let req;
          try { req = indexedDB.open('hukuk-notes', 1); } catch (e) { finish(e); return; }
          req.onupgradeneeded = () => { try { req.result.createObjectStore('docs'); } catch (_) {} };
          req.onsuccess = () => {
            const d = req.result;
            d.onversionchange = () => { try { d.close(); } catch (_) {} dbp = null; };
            d.onclose = () => { dbp = null; };
            finish(null, d);
          };
          req.onerror = () => finish(req.error || new Error('idb error'));
          // iOS Safari'de açma isteği bazen hiç yanıt vermez; yeni istek onu uyandırır.
          clearTimeout(timer);
          timer = setTimeout(() => { if (!done) { if (tries < 3) attempt(); else finish(new Error('idb timeout')); } }, 1500);
        };
        attempt();
      });
    }
    function db() {
      if (!dbp) { dbp = openDb(); dbp.catch(() => { dbp = null; }); }
      return dbp;
    }
    async function tx(mode, fn) {
      for (let i = 0; ; i++) {
        const d = await db();
        try {
          return await new Promise((resolve, reject) => {
            const t = d.transaction('docs', mode);
            const req = fn(t.objectStore('docs'));
            t.oncomplete = () => resolve(req ? req.result : undefined);
            t.onerror = () => reject(t.error || new Error('tx error'));
            t.onabort = () => reject(t.error || new Error('tx abort'));
          });
        } catch (e) {
          // Safari arka planda bağlantıyı kapatabilir: bir kez yeniden aç.
          if (i === 0 && e && (e.name === 'InvalidStateError' || e.name === 'UnknownError')) {
            try { d.close(); } catch (_) {}
            dbp = null;
            continue;
          }
          throw e;
        }
      }
    }
    const lsKey = id => 'hukuk-notes:' + id;
    function getLocal(id) {
      try { const v = localStorage.getItem(lsKey(id)); return v ? JSON.parse(v) : null; } catch (_) { return null; }
    }
    function putLocal(id, doc) {
      localStorage.setItem(lsKey(id), JSON.stringify(doc, (k, v) => (ArrayBuffer.isView(v) ? Array.from(v) : v)));
    }
    function dropLocal(id) {
      try { if (localStorage.getItem(lsKey(id)) !== null) localStorage.removeItem(lsKey(id)); } catch (_) {}
    }
    /** {ok: IndexedDB okunabildi mi, idb, local} */
    async function get(id) {
      const local = getLocal(id);
      try { return { ok: true, idb: (await tx('readonly', s => s.get(id))) || null, local }; } catch (_) { return { ok: false, idb: null, local }; }
    }
    async function put(id, doc) { await tx('readwrite', s => s.put(doc, id)); }
    return { get, put, putLocal, dropLocal };
  })();
  const prefs = (() => {
    let v = {};
    try { v = JSON.parse(localStorage.getItem('hukuk-notes-prefs') || '{}') || {}; } catch (_) { v = {}; }
    return {
      get: (k, d) => (k in v ? v[k] : d),
      set(k, val) { v[k] = val; try { localStorage.setItem('hukuk-notes-prefs', JSON.stringify(v)); } catch (_) {} },
    };
  })();

  // ═════════════════════════ Araçlar ═════════════════════════
  const TOOLS = {
    pen: {
      label: 'Kalem', colors: ['#1d1b22', '#1f4fd1', '#d12a3a', '#1e8a4c', '#7a3fc4', '#e07a1f'],
      sizes: [1.5, 2.4, 3.8],
    },
    hl: {
      label: 'Fosforlu kalem', colors: ['#ffe14d', '#8cf59f', '#ff9fd0', '#8fd8ff', '#ffbf6b', '#c8b0ff'],
      sizes: [12, 18, 26],
    },
    eraser: { label: 'Silgi', sizes: [6, 14, 30] },
    lasso: { label: 'Kement' },
  };
  const DOTS = { pen: [4, 7, 10], hl: [7, 11, 15], eraser: [8, 13, 19] };
  const COLOR_NAMES = {
    '#1d1b22': 'Siyah', '#1f4fd1': 'Mavi', '#d12a3a': 'Kırmızı', '#1e8a4c': 'Yeşil', '#7a3fc4': 'Mor', '#e07a1f': 'Turuncu',
    '#ffe14d': 'Sarı', '#8cf59f': 'Yeşil', '#ff9fd0': 'Pembe', '#8fd8ff': 'Mavi', '#ffbf6b': 'Turuncu', '#c8b0ff': 'Lila',
  };
  const svgIcon = (body, extra = '') => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"${extra}>${body}</svg>`;
  const ICONS = {
    back: svgIcon('<path d="M15 5l-7 7 7 7"/>', ' stroke-width="2.2"'),
    pen: svgIcon('<path d="M4 20l1.2-4.6L15.6 5a2.1 2.1 0 013 3L8.2 18.4z"/><path d="M13.8 6.8l3.4 3.4"/>', ' stroke-width="1.9"'),
    hl: svgIcon('<path d="M9 14l-3 3v3h3l3-3"/><path d="M9 14l7.5-9.5a2 2 0 012.8-.3l.5.4a2 2 0 01.3 2.8L12 17z"/><path d="M3 21h7" stroke-width="2.6"/>', ' stroke-width="1.9"'),
    eraser: svgIcon('<path d="M8.5 20H20"/><path d="M5.3 15.7l8.9-8.9a2 2 0 012.8 0l2.2 2.2a2 2 0 010 2.8l-7.5 7.5a2 2 0 01-1.4.6H8.6a2 2 0 01-1.4-.6l-1.9-1.9a1.2 1.2 0 010-1.7z"/><path d="M10 10.9l5.3 5.3"/>', ' stroke-width="1.9"'),
    lasso: svgIcon('<path d="M12 4c4.7 0 8 2.4 8 5.5S16.7 15 12 15s-8-2.4-8-5.5S7.3 4 12 4z"/><path d="M7.5 14.2c-.9 1.2-1 2.6-.2 3.6.9 1.1 2.6 1.3 3.7 2.2" stroke-dasharray="none"/>', ' stroke-width="1.9" stroke-dasharray="2.6 2.6"'),
    undo: svgIcon('<path d="M9 7L4.5 11.5 9 16"/><path d="M5 11.5h9.5a5 5 0 010 10H12"/>'),
    redo: svgIcon('<path d="M15 7l4.5 4.5L15 16"/><path d="M19 11.5H9.5a5 5 0 000 10H12"/>'),
    more: '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5.5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="18.5" cy="12" r="1.8"/></svg>',
    toc: svgIcon('<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.5" cy="6" r="1" fill="currentColor"/><circle cx="4.5" cy="12" r="1" fill="currentColor"/><circle cx="4.5" cy="18" r="1" fill="currentColor"/>'),
    search: svgIcon('<circle cx="10.5" cy="10.5" r="6"/><path d="M15.2 15.2L20 20"/>'),
    up: svgIcon('<path d="M6 15l6-6 6 6"/>'),
    down: svgIcon('<path d="M6 9l6 6 6-6"/>'),
    x: svgIcon('<path d="M6 6l12 12M18 6L6 18"/>'),
  };

  // ═════════════════════════ Uygulama ═════════════════════════
  let ui = null; // DOM (ilk açılışta kurulur)
  let S = null;  // açık özetin durumu
  let closeResolve = null;
  let openSeq = 0;
  let saving = Promise.resolve();

  const wait = ms => new Promise(r => setTimeout(r, ms));
  const nowId = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  const qs = (el, sel) => el.querySelector(sel);
  const SVGNS = 'http://www.w3.org/2000/svg';

  function build() {
    const root = document.createElement('div');
    root.id = 'hn-root';
    root.innerHTML = `
      <div class="hn-bar">
        <button class="hn-btn hn-back" data-a="close" aria-label="Özetlere dön">${ICONS.back}<span>Özetler</span></button>
        <button class="hn-btn" data-a="toc" aria-label="İçindekiler">${ICONS.toc}</button>
        <button class="hn-btn hn-findbtn" data-a="find" aria-label="Özette ara">${ICONS.search}</button>
        <div class="hn-title"><b></b><small></small></div>
        <div class="hn-sp"></div>
        <button class="hn-btn hn-tool" data-tool="pen" aria-label="Kalem">${ICONS.pen}</button>
        <button class="hn-btn hn-tool" data-tool="hl" aria-label="Fosforlu kalem">${ICONS.hl}</button>
        <button class="hn-btn hn-tool" data-tool="eraser" aria-label="Silgi">${ICONS.eraser}</button>
        <button class="hn-btn hn-tool" data-tool="lasso" aria-label="Kement ile seç">${ICONS.lasso}</button>
        <div class="hn-sep"></div>
        <div class="hn-opts"></div>
        <button class="hn-btn hn-style" data-a="style" aria-label="Renk ve kalınlık"><i></i>${ICONS.down}</button>
        <div class="hn-sep"></div>
        <button class="hn-btn" data-a="undo" aria-label="Geri al">${ICONS.undo}</button>
        <button class="hn-btn hn-redo" data-a="redo" aria-label="Yinele">${ICONS.redo}</button>
        <button class="hn-btn" data-a="more" aria-label="Diğer">${ICONS.more}</button>
      </div>
      <div class="hn-scroller"><div class="hn-sizer"><div class="hn-page"></div></div></div>
      <svg class="hn-live" aria-hidden="true"><g>
        <path class="hn-lstroke"/><path class="hn-llasso" fill="rgba(214,51,108,0.06)" stroke="#d6336c"/>
        <circle class="hn-lcur" r="0" stroke="rgba(40,20,60,0.55)"/>
      </g></svg>
      <div class="hn-chip hn-zoom" role="button" aria-label="Sayfayı ekrana sığdır">100%</div>
      <div class="hn-chip hn-save">Kaydedildi</div>
      <div class="hn-chip hn-toast" role="status"></div>
      <div class="hn-chip hn-selbar">
        <span class="hn-selcount"></span>
        <button class="hn-btn" data-a="selcolor">Renk</button>
        <button class="hn-btn" data-a="seldup">Çoğalt</button>
        <button class="hn-btn" data-a="seldel">Sil</button>
        <button class="hn-btn" data-a="seloff">Bitti</button>
      </div>
      <div class="hn-notice" role="status"><span></span><div class="hn-nb"></div></div>
      <div class="hn-find" role="search">
        ${ICONS.search}
        <input type="search" placeholder="Özette ara" aria-label="Özette ara" enterkeyhint="search" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">
        <span class="hn-fcount"></span>
        <button class="hn-btn" data-f="prev" aria-label="Önceki sonuç">${ICONS.up}</button>
        <button class="hn-btn" data-f="next" aria-label="Sonraki sonuç">${ICONS.down}</button>
        <button class="hn-btn" data-f="close" aria-label="Aramayı kapat">${ICONS.x}</button>
      </div>
      <div class="hn-pop hn-toc"></div>
      <div class="hn-pop hn-menu"></div>
      <div class="hn-pop hn-eopts"></div>
      <div class="hn-pop hn-stylepop"></div>
      <div class="hn-pop hn-recolor"></div>
    `;
    document.body.appendChild(root);
    const u = {
      root,
      bar: qs(root, '.hn-bar'),
      titleMain: qs(root, '.hn-title b'),
      titleSub: qs(root, '.hn-title small'),
      opts: qs(root, '.hn-opts'),
      style: qs(root, '.hn-style'),
      scroller: qs(root, '.hn-scroller'),
      sizer: qs(root, '.hn-sizer'),
      page: qs(root, '.hn-page'),
      live: qs(root, '.hn-live'),
      zoom: qs(root, '.hn-zoom'),
      save: qs(root, '.hn-save'),
      toast: qs(root, '.hn-toast'),
      selbar: qs(root, '.hn-selbar'),
      selcount: qs(root, '.hn-selcount'),
      toc: qs(root, '.hn-toc'),
      menu: qs(root, '.hn-menu'),
      eopts: qs(root, '.hn-eopts'),
      stylePop: qs(root, '.hn-stylepop'),
      recolor: qs(root, '.hn-recolor'),
      notice: qs(root, '.hn-notice'),
      noticeText: qs(root, '.hn-notice span'),
      noticeBtns: qs(root, '.hn-nb'),
      find: qs(root, '.hn-find'),
      findInput: qs(root, '.hn-find input'),
      findCount: qs(root, '.hn-fcount'),
      undo: qs(root, '[data-a="undo"]'),
      redo: qs(root, '[data-a="redo"]'),
    };
    u.liveG = qs(u.live, 'g');
    u.lStroke = qs(u.live, '.hn-lstroke');
    u.lLasso = qs(u.live, '.hn-llasso');
    u.lCur = qs(u.live, '.hn-lcur');
    // Flutter'ın pencere düzeyindeki dinleyicilerine olay sızmasın.
    for (const t of ['pointerdown', 'pointermove', 'pointerup', 'pointercancel', 'touchstart', 'touchmove',
      'touchend', 'wheel', 'mousedown', 'mouseup', 'click', 'contextmenu', 'gesturestart', 'gesturechange']) {
      root.addEventListener(t, e => { e.stopPropagation(); if (t === 'contextmenu' || t.startsWith('gesture')) e.preventDefault(); });
    }
    u.bar.addEventListener('click', onBarClick);
    u.selbar.addEventListener('click', onBarClick);
    u.stylePop.addEventListener('click', onBarClick);
    u.recolor.addEventListener('click', onRecolorClick);
    u.zoom.addEventListener('click', () => { if (S) fitWidth(true); });
    u.menu.addEventListener('click', onMenuClick);
    u.eopts.addEventListener('click', onMenuClick);
    u.toc.addEventListener('click', onTocClick);
    u.notice.addEventListener('click', onNoticeClick);
    u.find.addEventListener('click', onFindClick);
    u.findInput.addEventListener('input', () => {
      clearTimeout(u.findTimer);
      u.findTimer = setTimeout(() => runFind(u.findInput.value), 140);
    });
    u.scroller.addEventListener('click', onScrollerClick);
    attachInput(u);
    window.addEventListener('resize', onResize);
    document.addEventListener('visibilitychange', () => { if (document.hidden && S) flushSave(); });
    window.addEventListener('pagehide', () => { if (S) flushSave(); });
    document.addEventListener('keydown', onKey, true);
    window.addEventListener('beforeprint', () => { if (S && isOpen() && (!S.printEl || S.printVer !== S.ver)) buildPrint(); });
    return u;
  }

  const isOpen = () => !!ui && ui.root.classList.contains('hn-open');

  // ───────── Açma / kapama ─────────
  function open(id) {
    if (!ui) ui = build();
    if (closeResolve) { const r = closeResolve; closeResolve = null; r('replaced'); }
    const done = new Promise(r => { closeResolve = r; });
    // Aynı özet zaten açıksa yeniden yükleme.
    if (!(S && S.id === id && isOpen() && !S.closed)) load(id);
    return done;
  }

  async function load(id) {
    const seq = ++openSeq;
    if (S && !S.closed) { endSelection(); closeFind(); rememberView(); flushSave(); S.closed = true; }
    S = null;
    removePrint();
    document.documentElement.classList.add('hn-noting');
    document.body.classList.add('hn-noting');
    ui.root.classList.add('hn-open');
    hidePops();
    for (const el of [ui.notice, ui.selbar, ui.find, ui.toast, ui.save]) el.classList.remove('hn-show');
    ui.page.innerHTML = '';
    ui.page.style.height = '800px';
    ui.page.style.transform = '';
    ui.sizer.style.height = '';
    setTitle('', '');
    showLoading('Özet hazırlanıyor…');
    try {
      // Önceki kayıt bitmeden okumaya başlama (hızlı kapat-aç).
      await Promise.race([saving, wait(2000)]);
      const summary = await loadSummary(id);
      if (seq !== openSeq) return;
      await fontsReady(2500);
      if (seq !== openSeq) return;
      // Depolama takılırsa (ör. iOS'ta yanıt vermeyen IndexedDB) özet yine açılır;
      // kayıtlı notlar gelince birleştirilir. O zamana kadar asıl kayda yazılmaz.
      const TIMEOUT = {};
      const got = await Promise.race([store.get(id), wait(3500).then(() => TIMEOUT)]);
      if (seq !== openSeq) return;
      const st = newState(id, summary);
      S = st;
      renderPage();
      setBasis(measureBasis(st.content));
      let doc = null;
      if (got !== TIMEOUT) {
        doc = await prepareAll(got);
        if (seq !== openSeq || S !== st) return;
        st.loadPending = !got.ok;
      } else st.loadPending = true;
      if (doc) { st.doc.strokes = doc.strokes; st.doc.extra = doc.extra; st.doc.edited = doc.edited; }
      for (const s of st.doc.strokes) addEl(s, false);
      hideLoading();
      setTitle(summary.title, '');
      updatePageHeight();
      restoreView();
      refreshToolbar();
      updateTitle();
      maybeBackupNotice();
      watchFonts(st);
      if (doc && doc.resave) { st.dirty = true; scheduleSave(); }
      if (doc && doc.moved) {
        toast(`Özet güncellendi — ${doc.moved} not yeni düzende yerine taşındı`, 4500);
      } else if (!prefs.get('hinted', false)) {
        toast('Apple Pencil ile yaz · parmakla kaydır · iki parmakla dokun: geri al', 4200);
        prefs.set('hinted', true);
      }
      if (st.loadPending) {
        toast('Kayıtlı notlar yükleniyor… Bu sırada aldığın notlar da saklanır.', 3200);
        lateLoad(st);
      }
    } catch (e) {
      if (seq !== openSeq) return;
      S = null;
      ui.page.innerHTML = '';
      showLoadError(id, e);
    }
  }

  function newState(id, summary) {
    const pick = (list, v, d) => (list.includes(v) ? v : d);
    const size = (k, d) => { const v = prefs.get(k, d); return Number.isInteger(v) && v >= 0 && v <= 2 ? v : d; };
    const st = {
      id, summary,
      doc: { strokes: [], extra: 0, edited: 0 },
      basis: null, basisPacked: null, loadPending: false, closed: false,
      els: new Map(), tiles: [], tileOf: new Map(),
      undo: [], redo: [],
      tool: prefs.get('tool', 'pen'),
      color: {
        pen: pick(TOOLS.pen.colors, prefs.get('c.pen'), TOOLS.pen.colors[0]),
        hl: pick(TOOLS.hl.colors, prefs.get('c.hl'), TOOLS.hl.colors[0]),
      },
      size: { pen: size('s.pen', 1), hl: size('s.hl', 1), eraser: size('s.eraser', 1) },
      eraseMode: prefs.get('eraseMode', 'stroke') === 'precise' ? 'precise' : 'stroke',
      eraseHl: prefs.get('eraseHl', false) === true,
      hlSnap: prefs.get('hlSnap', true) !== false,
      hidden: false,
      z: 1, rz: 1, contentH: 0, pageH: 0, vw: 0, ox: 0,
      sel: null, dirty: false, saveTimer: 0, ver: 0,
      lines: null, findIdx: null, find: null, printEl: null, printVer: -1,
      sections: [],
    };
    if (!TOOLS[st.tool]) st.tool = 'pen';
    return st;
  }

  function fontsReady(ms) {
    const f = document.fonts;
    if (!f || !f.load) return Promise.resolve();
    return Promise.race([f.load('400 16px HNInter').catch(() => {}), wait(ms)]);
  }
  /** Yazı tipi açılıştan sonra yüklenirse düzen ölçülür, notlar yeni yerine taşınır. */
  function watchFonts(st) {
    const f = document.fonts;
    if (!f || !f.check) return;
    let ok = true;
    try { ok = f.check('400 16px HNInter'); } catch (_) {}
    if (ok) return;
    f.load('400 16px HNInter').then(() => { if (S === st && !st.closed) relayout(); }, () => {});
  }
  function relayout() {
    S.contentH = Math.ceil(S.content.offsetHeight);
    S.lines = null;
    S.findIdx = null;
    refreshSections();
    const nb = measureBasis(S.content);
    if (!G.sameBasis(S.basis, nb)) {
      const res = G.remap(S.doc.strokes, S.basis, nb);
      setBasis(nb);
      if (res.moved) {
        endSelection();
        S.doc.strokes = res.strokes;
        // Eski konumları tutan geri alma geçmişi artık geçersiz.
        S.undo.length = 0; S.redo.length = 0;
        rebuildInk();
      }
      S.dirty = true;
      scheduleSave();
    }
    updatePageHeight();
    if (S.find) runFind(S.find.q, true);
  }

  async function lateLoad(st) {
    for (let attempt = 0; S === st && st.loadPending && !st.closed; attempt++) {
      const got = await Promise.race([store.get(st.id), wait(5000).then(() => null)]);
      if (S !== st || st.closed) return;
      if (got && got.ok) {
        let doc;
        try { doc = await prepareAll(got); } catch (_) { doc = null; }
        if (S !== st || st.closed) return;
        if (doc) {
          // Birleşim: bu oturumda alınan notlar korunur, kayıtlılar eklenir.
          const have = new Set(st.doc.strokes.map(s => s.id));
          const add = doc.strokes.filter(s => !have.has(s.id));
          st.doc.strokes = add.concat(st.doc.strokes);
          st.doc.extra = Math.max(st.doc.extra, doc.extra);
          st.doc.edited = Math.max(st.doc.edited, doc.edited);
          for (const s of add) addEl(s, false);
          st.loadPending = false;
          requestCull();
          updatePageHeight();
          st.dirty = true;
          flushSave();
          if (add.length) toast('Kayıtlı notlar yüklendi');
          return;
        }
      }
      await wait(Math.min(15000, 2500 * (attempt + 1)));
    }
  }

  /** Kayıtlı belgenin notlarını bu sayfanın düzenine taşır. */
  const legacyBasis = {};
  async function prepare(raw) {
    const d = G.sanitizeDoc(raw);
    d.moved = 0;
    d.resave = false;
    if (!d.strokes.length) return d;
    let from = d.basis;
    if (!from) {
      // Temelsiz kayıt: kaydedildiği sürümün dondurulmuş metni ölçülür.
      const v = d.sv || 1;
      if (v === S.summary.version) from = S.basis;
      else {
        const key = S.id + '@' + v;
        if (!legacyBasis[key]) {
          const old = await loadSummary(S.id, v);
          legacyBasis[key] = measureHtml(old.html, !!old.legacy);
        }
        from = legacyBasis[key];
      }
    }
    if (!G.sameBasis(from, S.basis)) {
      const res = G.remap(d.strokes, from, S.basis);
      d.strokes = res.strokes;
      d.moved = res.moved;
      d.resave = true;
    } else if (!d.basis) d.resave = true;
    return d;
  }
  async function prepareAll(got) {
    const idb = got.idb ? await prepare(got.idb) : null;
    const local = got.local ? await prepare(got.local) : null;
    let doc;
    if (!got.ok) doc = local;
    else if (!local) doc = idb;
    else if (!idb) doc = local;
    else if (local.partial) {
      const have = new Set(idb.strokes.map(s => s.id));
      doc = idb;
      doc.strokes = idb.strokes.concat(local.strokes.filter(s => !have.has(s.id)));
      doc.extra = Math.max(idb.extra, local.extra);
      doc.edited = Math.max(idb.edited, local.edited);
      doc.moved += local.moved;
    } else doc = local.updated > idb.updated ? local : idb;
    doc = doc || G.sanitizeDoc(null);
    // Yerel kopya birleştirildiyse asıl kayda yazılıp silinsin.
    if (got.ok && got.local) doc.resave = true;
    return doc;
  }

  function close() {
    if (!ui) return;
    openSeq++;
    if (S && !S.closed) {
      endSelection();
      closeFind();
      rememberView();
      flushSave();
      S.closed = true;
    }
    removePrint();
    hideLoading();
    ui.root.classList.remove('hn-open');
    document.documentElement.classList.remove('hn-noting');
    document.body.classList.remove('hn-noting');
    hidePops();
    const r = closeResolve;
    closeResolve = null;
    if (r) r('closed');
  }

  function showLoading(msg) {
    hideLoading();
    const d = document.createElement('div');
    d.className = 'hn-loading';
    d.innerHTML = `<i class="hn-spin"></i><span>${esc(msg)}</span>`;
    ui.scroller.appendChild(d);
  }
  function hideLoading() { if (ui) for (const el of ui.root.querySelectorAll('.hn-loading')) el.remove(); }
  function showLoadError(id, err) {
    hideLoading();
    const msg = err && err.message && err.message.length < 160 ? err.message : 'Özet açılamadı.';
    const d = document.createElement('div');
    d.className = 'hn-loading hn-error';
    d.innerHTML = `<p>${esc(msg)}</p><div><button class="hn-btn hn-primary" data-e="retry">Tekrar dene</button><button class="hn-btn" data-e="close">Kapat</button></div>`;
    d.addEventListener('click', e => {
      const b = e.target.closest('button[data-e]');
      if (!b) return;
      if (b.dataset.e === 'retry') load(id); else close();
    });
    ui.scroller.appendChild(d);
  }

  function setTitle(main, sub) {
    ui.titleMain.textContent = main;
    ui.titleSub.textContent = sub;
  }

  // ───────── Görünüm (yakınlık ve konum) ─────────
  function rememberView() {
    if (!S || !S.content) return;
    const sc = ui.scroller;
    const y = (sc.scrollTop - OFF_Y) / S.z;
    const sec = sectionAt(y + 1);
    prefs.set('view.' + S.id, {
      v: S.summary.version, rz: rd(S.rz), x: rd(sc.scrollLeft / S.z), y: rd(y),
      sec: sec ? sec.key : null, sy: sec ? rd(y - sec.y) : 0,
    });
  }
  function restoreView() {
    const view = prefs.get('view.' + S.id, null);
    let rz = 1, y = 0, x = 0;
    if (view && typeof view === 'object') {
      if (Number.isFinite(view.rz)) rz = clamp(view.rz, 0.25, 8);
      if (view.v === S.summary.version && Number.isFinite(view.y)) { y = view.y; x = Number(view.x) || 0; }
      else if (view.sec) {
        // Özet değiştiyse aynı bölümün aynı yerine dön.
        const sec = S.sections.find(s => s.key === view.sec);
        if (sec) y = sec.y + (Number(view.sy) || 0);
      }
    }
    S.z = clamp(rz * fitZoom(), 0.3, 5);
    S.rz = S.z / fitZoom();
    layout();
    ui.scroller.scrollTop = Math.max(0, y * S.z + OFF_Y);
    ui.scroller.scrollLeft = Math.max(0, x * S.z);
  }

  // ───────── Sayfa ─────────
  function renderPage() {
    const page = ui.page;
    page.innerHTML = '';
    const ml = document.createElement('div'); ml.className = 'hn-margin l';
    const mr = document.createElement('div'); mr.className = 'hn-margin r';
    const content = document.createElement('div');
    content.className = 'hn-content' + (S.summary.legacy ? ' hn-legacy' : '');
    content.innerHTML = S.summary.html;
    const extra = document.createElement('div'); extra.className = 'hn-extra';
    const find = document.createElement('div'); find.className = 'hn-findlayer';
    const ink = document.createElement('div'); ink.className = 'hn-inkwrap';
    const sel = document.createElement('div'); sel.className = 'hn-sel'; sel.style.display = 'none';
    sel.innerHTML = '<i class="hn-selh"></i>';
    page.append(ml, mr, content, extra, find, ink, sel);
    S.content = content; S.extraEl = extra; S.findEl = find; S.ink = ink; S.selEl = sel;
    S.tiles = []; S.tileOf = new Map(); S.els = new Map();
    S.contentH = Math.ceil(content.offsetHeight);
    S.sections = [...content.querySelectorAll('h2.sec, .part')].map((h, i) => ({
      part: h.classList.contains('part'),
      no: h.querySelector('.no') ? h.querySelector('.no').textContent : '',
      text: h.classList.contains('part') ? (h.querySelector('div') || h).textContent.trim() : (h.querySelector('.tt') || h).textContent.trim(),
      key: h.id || 'part' + i,
      el: h, y: 0,
    }));
    refreshSections();
  }
  function refreshSections() {
    // Başlıklar içeriğin doğrudan çocuklarıdır; offsetTop sayfa birimindedir.
    for (const s of S.sections) s.y = s.el.offsetTop;
  }
  /** y'nin içinde bulunduğu numaralı bölüm (ilk bölümden önce null). */
  function sectionAt(y) {
    let cur = null;
    for (const s of S.sections) { if (s.part) continue; if (s.y <= y) cur = s; else break; }
    return cur;
  }

  // Bloklar: notların taşınmasında çapa olarak kullanılan öğeler.
  const BLOCKS = 'h1,h2,h3,h4,h5,p,li,tr,.n,.card,.box,.cap,.part,.cover>div,.legend>span,.foot';
  function measureBasis(content) {
    const els = content.querySelectorAll(BLOCKS);
    const base = content.getBoundingClientRect();
    const z = base.width / (content.offsetWidth || 1) || 1;
    const keys = new Array(els.length), r = new Float64Array(els.length * 4);
    const q = v => Math.round(v * 2) / 2;
    let sec = 'top';
    for (let i = 0; i < els.length; i++) {
      const el = els[i];
      if (el.tagName === 'H2' && el.id) sec = el.id;
      const b = el.getBoundingClientRect();
      const kind = el.tagName.toLowerCase() + (el.classList.length ? '.' + el.classList[0] : '');
      keys[i] = sec + '|' + kind + '|' + G.hash(el.textContent.replace(/\s+/g, ' ').trim());
      r[4 * i] = q((b.left - base.left) / z + MARGIN);
      r[4 * i + 1] = q((b.top - base.top) / z);
      r[4 * i + 2] = q(b.width / z);
      r[4 * i + 3] = q(b.height / z);
    }
    return { keys, r, end: q(content.offsetHeight) };
  }
  /** Bir özet sürümünü görünmez bir sayfada ölçer (eski notları taşımak için). */
  function measureHtml(html, legacy) {
    const page = document.createElement('div');
    page.className = 'hn-page hn-measure';
    const content = document.createElement('div');
    content.className = 'hn-content' + (legacy ? ' hn-legacy' : '');
    content.innerHTML = html;
    page.appendChild(content);
    ui.root.appendChild(page);
    try { return measureBasis(content); } finally { page.remove(); }
  }
  function setBasis(b) { S.basis = b; S.basisPacked = G.packBasis(b); }

  function pageHeight() {
    let maxY = 0;
    for (const s of S.doc.strokes) { const b = s.b || (s.b = G.bounds(s)); if (b[3] > maxY) maxY = b[3]; }
    return Math.max(S.contentH + 400 + S.doc.extra, Math.ceil(maxY + 300));
  }

  function updatePageHeight() {
    const h = pageHeight();
    S.pageH = h;
    ui.page.style.height = h + 'px';
    S.extraEl.style.top = S.contentH + 'px';
    S.extraEl.style.height = (h - S.contentH) + 'px';
    layout();
  }

  // ───────── Yakınlaştırma / yerleşim ─────────
  // Yakınlık sayfanın ekrana sığdığı değere göre (rz) tutulur: iPad döndürülünce
  // ya da pencere bölününce sayfa aynı göreli yakınlıkta kalır.
  function viewSize() { return { w: ui.scroller.clientWidth, h: ui.scroller.clientHeight }; }
  function fitZoom() { return clamp((viewSize().w - 24) / PAGE_W, 0.3, 4); }
  function offX() { return Math.max(12, (viewSize().w - PAGE_W * S.z) / 2); }
  const OFF_Y = 14;

  function layout() {
    if (!S) return;
    const vw = viewSize().w;
    const z = S.z, ox = offX();
    S.vw = vw; S.ox = ox;
    ui.page.style.transform = `translate(${ox}px, ${OFF_Y}px) scale(${z})`;
    ui.sizer.style.width = Math.max(vw, PAGE_W * z + ox * 2) + 'px';
    ui.sizer.style.height = (S.pageH * z + OFF_Y * 2 + 40) + 'px';
    ui.zoom.textContent = Math.round(S.rz * 100) + '%';
    if (S.sel) S.selEl.style.setProperty('--hn-inv', String(1 / z));
    requestCull();
  }

  /** fx/fy: kaydırma alanına göre odak noktası; o noktadaki sayfa yeri sabit kalır. */
  function setZoom(z, fx, fy, silent) {
    const sc = ui.scroller;
    const oldZ = S.z, oldOx = offX();
    const px = (sc.scrollLeft + fx - oldOx) / oldZ;
    const py = (sc.scrollTop + fy - OFF_Y) / oldZ;
    S.z = clamp(z, 0.3, 5);
    S.rz = S.z / fitZoom();
    layout();
    const ox = offX();
    sc.scrollLeft = px * S.z + ox - fx;
    sc.scrollTop = py * S.z + OFF_Y - fy;
    if (!silent) scheduleViewSave();
  }

  function fitWidth(animate) {
    const sc = ui.scroller;
    const py = (sc.scrollTop - OFF_Y) / S.z;
    S.z = fitZoom();
    S.rz = 1;
    layout();
    sc.scrollLeft = 0;
    sc.scrollTop = animate ? Math.max(0, py * S.z + OFF_Y) : 0;
    scheduleViewSave();
  }

  let zoomAnim = 0;
  function animateZoom(toZ, fx, fy) {
    cancelAnimationFrame(zoomAnim);
    const fromZ = S.z, t0 = performance.now();
    const step = now => {
      if (!S) return;
      const k = Math.min(1, (now - t0) / 220), e = 1 - Math.pow(1 - k, 3);
      setZoom(fromZ + (toZ - fromZ) * e, fx, fy, k < 1);
      requestLive();
      if (k < 1) zoomAnim = requestAnimationFrame(step);
    };
    zoomAnim = requestAnimationFrame(step);
  }

  function onResize() {
    if (!S || !isOpen() || !S.content) return;
    const sc = ui.scroller;
    const oldZ = S.z;
    const py = (sc.scrollTop - OFF_Y) / oldZ;
    const pxc = (sc.scrollLeft + S.vw / 2 - S.ox) / oldZ;
    S.z = clamp(S.rz * fitZoom(), 0.3, 5);
    layout();
    sc.scrollTop = py * S.z + OFF_Y;
    sc.scrollLeft = pxc * S.z + offX() - viewSize().w / 2;
    fitBar();
    hidePops();
    requestLive();
  }

  let viewTimer = 0;
  function scheduleViewSave() { clearTimeout(viewTimer); viewTimer = setTimeout(rememberView, 600); }

  // ───────── Çizim öğeleri (karolar) ─────────
  // Notlar sayfa boyunca 1200 birimlik yatay karolara bölünür; her karo ayrı
  // bir SVG'dir. Ekrandan uzak karolar gizlenir (çizilmez, yakınlaştırmada
  // yeniden işlenmez) ve yolları ancak ekrana yaklaşınca üretilir. Binlerce
  // çizgide açılış, kaydırma ve yakınlaştırma böylece hafif kalır.
  const TILE = 1200;
  function tile(k) {
    let t = S.tiles[k];
    if (t) return t;
    const svg = document.createElementNS(SVGNS, 'svg');
    svg.setAttribute('class', 'hn-ink');
    svg.setAttribute('width', PAGE_W);
    svg.setAttribute('height', TILE);
    svg.setAttribute('viewBox', `0 ${k * TILE} ${PAGE_W} ${TILE}`);
    svg.style.top = k * TILE + 'px';
    svg.style.display = 'none';
    const sc = `scale(${PATH_SCALE})`;
    const ghl = document.createElementNS(SVGNS, 'g'); ghl.setAttribute('class', 'hn-hl'); ghl.setAttribute('transform', sc);
    const gpen = document.createElementNS(SVGNS, 'g'); gpen.setAttribute('class', 'hn-pen'); gpen.setAttribute('transform', sc);
    svg.append(ghl, gpen);
    S.ink.appendChild(svg);
    t = S.tiles[k] = { k, svg, ghl, gpen, items: new Map(), min: Infinity, max: -Infinity, shown: false, pending: 0 };
    return t;
  }
  function makePath(s, t) {
    const path = document.createElementNS(SVGNS, 'path');
    path.setAttribute('d', G.outline(s.t, s.w, s.p));
    path.setAttribute('fill', s.c);
    if (s.t === 'hl') path.setAttribute('fill-opacity', '0.42');
    (s.t === 'hl' ? t.ghl : t.gpen).appendChild(path);
    S.els.set(s.id, path);
  }
  /** now: kullanıcı işlemi; yol hemen çizilir. false: karo görünür olunca. */
  function addEl(s, now = true) {
    s.b = s.b || G.bounds(s);
    const k = Math.max(0, Math.floor((s.b[1] + s.b[3]) / 2 / TILE));
    const t = tile(k);
    t.items.set(s.id, s);
    S.tileOf.set(s.id, k);
    if (s.b[1] < t.min) t.min = s.b[1];
    if (s.b[3] > t.max) t.max = s.b[3];
    if (now) {
      makePath(s, t);
      if (!t.shown) requestCull();
    } else {
      t.pending++;
    }
  }
  function removeEl(id) {
    const k = S.tileOf.get(id);
    if (k === undefined) return;
    const t = S.tiles[k];
    t.items.delete(id);
    S.tileOf.delete(id);
    const el = S.els.get(id);
    if (el) { el.remove(); S.els.delete(id); } else if (t.pending) t.pending--;
  }
  function buildTile(t) {
    if (!t.pending) return;
    for (const s of t.items.values()) if (!S.els.has(s.id)) makePath(s, t);
    t.pending = 0;
  }
  function rebuildInk() {
    S.ink.innerHTML = '';
    S.tiles = []; S.tileOf = new Map(); S.els = new Map();
    for (const s of S.doc.strokes) addEl(s, false);
    requestCull();
  }
  let cullQueued = false;
  function requestCull() {
    if (cullQueued || !S) return;
    cullQueued = true;
    requestAnimationFrame(cull);
  }
  function cull() {
    cullQueued = false;
    if (!S || !S.tiles) return;
    const sc = ui.scroller, z = S.z;
    const top = (sc.scrollTop - OFF_Y) / z, h = sc.clientHeight / z;
    // Görünen alanın bir ekran üstü ve altı da hazır tutulur (kaydırırken boşluk görünmesin).
    const lo = top - h, hi = top + 2 * h;
    let built = 0;
    const t0 = performance.now();
    for (const t of S.tiles) {
      if (!t) continue;
      const want = t.items.size > 0 && t.max >= lo && t.min <= hi;
      if (want && t.pending) {
        // Bir karede çok iş yapma: ekranda olan karo hemen, kenardakiler sonraki karelerde.
        const onScreen = t.max >= top && t.min <= top + h;
        if (!onScreen && performance.now() - t0 > 8) { built++; continue; }
        buildTile(t);
      }
      if (want !== t.shown) { t.svg.style.display = want ? '' : 'none'; t.shown = want; }
    }
    if (built) requestCull();
  }
  function commitOp(op) {
    if (!op.before.length && !op.after.length) return;
    S.undo.push(op);
    if (S.undo.length > 300) S.undo.shift();
    S.redo.length = 0;
    changed();
  }
  function runOp(op, reverse) {
    const remove = reverse ? op.after : op.before;
    const add = reverse ? op.before : op.after;
    for (const s of remove) removeEl(s.id);
    S.doc.strokes = G.applyOp(S.doc.strokes, op, reverse);
    for (const s of add) addEl(s);
    changed();
  }
  function undo() {
    if (!S) return;
    endSelection();
    const op = S.undo.pop();
    if (!op) return toast('Geri alınacak bir şey yok');
    runOp(op, true);
    S.redo.push(op);
    refreshUndo();
  }
  function redo() {
    if (!S) return;
    endSelection();
    const op = S.redo.pop();
    if (!op) return toast('Yinelenecek bir şey yok');
    runOp(op, false);
    S.undo.push(op);
    refreshUndo();
  }
  function changed() {
    S.ver++;
    S.doc.edited = Date.now();
    refreshUndo();
    const h = pageHeight();
    if (h !== S.pageH) updatePageHeight();
    S.dirty = true;
    scheduleSave();
  }
  function scheduleSave() {
    clearTimeout(S.saveTimer);
    S.saveTimer = setTimeout(flushSave, 500);
  }

  // ───────── Kayıt ─────────
  let persistAsked = false;
  /** Kayıtlar sırayla yazılır; her biri çağrıldığı andaki durumu yazar. */
  function flushSave() {
    if (!S || !S.dirty) return saving;
    const st = S;
    clearTimeout(st.saveTimer);
    st.dirty = false;
    const doc = {
      v: 2, sv: st.summary.version, basis: st.basisPacked, extra: st.doc.extra, updated: Date.now(), edited: st.doc.edited,
      // Noktalar Float32Array olarak yazılır: düz diziye göre yarı boyut ve hızlı kopya.
      // Çizgiler değişmez nesnelerdir (her işlem yenisini üretir); dizi bir kez oluşturulur.
      strokes: st.doc.strokes.map(s => ({ id: s.id, t: s.t, c: s.c, w: s.w, p: s.f || (s.f = new Float32Array(s.p)) })),
    };
    const pending = st.loadPending;
    saving = saving.then(() => writeDoc(st, doc, pending));
    return saving;
  }
  async function writeDoc(st, doc, pending) {
    try {
      if (pending) store.putLocal(st.id, { ...doc, partial: true });
      else {
        try {
          await store.put(st.id, doc);
          store.dropLocal(st.id);
        } catch (_) {
          // IndexedDB yazamadı (dolu ya da kapalı): tam kopya localStorage'a.
          store.putLocal(st.id, doc);
        }
      }
      if (S === st && !st.closed) {
        flash(ui.save, pending ? 'Kaydedildi (geçici)' : 'Kaydedildi');
        if (st.saveFailed) { st.saveFailed = false; ui.notice.classList.remove('hn-show'); }
      }
      if (!persistAsked) {
        persistAsked = true;
        // Kalıcı depolama izni (Safari'nin temizlemesine karşı).
        try { navigator.storage && navigator.storage.persist && navigator.storage.persist(); } catch (_) {}
      }
    } catch (_) {
      st.dirty = true;
      clearTimeout(st.retryTimer);
      if (!st.closed) st.retryTimer = setTimeout(() => { if (S === st && st.dirty) flushSave(); }, 15000);
      if (S === st) {
        st.saveFailed = true;
        notice('Notlar bu cihaza kaydedilemedi (depolama dolu ya da erişilemiyor). Kaybetmemek için yedek al.',
          [['Yedekle', 'backup'], ['Tekrar dene', 'retry']], 'error');
      }
    }
  }

  // ───────── Canlı katman (anlık çizgi) ─────────
  let liveQueued = false;
  function requestLive() {
    if (liveQueued) return;
    liveQueued = true;
    requestAnimationFrame(drawLive);
  }
  function pageOrigin() {
    const pr = ui.page.getBoundingClientRect();
    const cr = ui.live.getBoundingClientRect();
    return { x: pr.left - cr.left, y: pr.top - cr.top, pr };
  }
  // Canlı katman bir SVG'dir: canvas + mix-blend-mode, iPad Safari'de kalem
  // kalkana kadar ekrana yansımıyordu. SVG yolu her karede normal yeniden
  // boyamayla güncellenir ve bırakınca oluşan çizgiyle aynı dış hattı kullanır.
  function drawLive() {
    liveQueued = false;
    if (!S) return;
    const o = pageOrigin(), z = S.z;
    ui.liveG.setAttribute('transform', `matrix(${z} 0 0 ${z} ${rd(o.x)} ${rd(o.y)})`);
    const st = input.stroke;
    if (st && st.b.pts.length) {
      const pts = st.snapped ? st.snapPts : st.b.pts;
      ui.lStroke.setAttribute('d', G.outline(st.t, st.w, pts, st.snapped ? null : st.predicted));
      ui.lStroke.setAttribute('transform', `scale(${PATH_SCALE})`);
      ui.lStroke.setAttribute('fill', st.c);
      ui.lStroke.setAttribute('fill-opacity', st.t === 'hl' ? '0.42' : '1');
      ui.lStroke.style.mixBlendMode = st.t === 'hl' ? 'multiply' : '';
    } else ui.lStroke.setAttribute('d', '');
    const lasso = input.lasso;
    if (lasso && lasso.length > 2) {
      let d = `M${lasso[0]} ${lasso[1]}`;
      for (let i = 2; i < lasso.length; i += 2) d += `L${lasso[i]} ${lasso[i + 1]}`;
      ui.lLasso.setAttribute('d', d + 'Z');
      ui.lLasso.setAttribute('stroke-width', rd(1.6 / z));
      ui.lLasso.setAttribute('stroke-dasharray', `${rd(6 / z)} ${rd(5 / z)}`);
    } else ui.lLasso.setAttribute('d', '');
    const cur = input.cursor;
    if (cur) {
      ui.lCur.setAttribute('cx', rd(cur.x));
      ui.lCur.setAttribute('cy', rd(cur.y));
      ui.lCur.setAttribute('r', rd(cur.r));
      ui.lCur.setAttribute('stroke-width', rd(1.2 / z));
      ui.lCur.setAttribute('fill', cur.fill || 'none');
    } else ui.lCur.setAttribute('r', '0');
  }

  // ───────── Girdi ─────────
  const input = {
    stroke: null, lasso: null, cursor: null, penId: null, penDown: false, lastPen: 0,
    erase: null, move: null, resize: null, touches: new Map(), pinch: null, tap: null, lastTap: null,
  };

  function toPage(e, pr) {
    return [(e.clientX - pr.left) / S.z, (e.clientY - pr.top) / S.z];
  }
  const isPen = e => e.pointerType === 'pen' || e.pointerType === 'mouse';

  function attachInput(u) {
    const sc = u.scroller;
    sc.addEventListener('pointerdown', onPointerDown);
    sc.addEventListener('pointermove', onPointerMove);
    sc.addEventListener('pointerup', onPointerUp);
    sc.addEventListener('pointercancel', onPointerUp);
    sc.addEventListener('pointerleave', e => { if (isPen(e) && !input.penDown) { input.cursor = null; requestLive(); } });
    sc.addEventListener('lostpointercapture', e => { if (e.pointerId === input.penId) onPointerUp(e); });
    sc.addEventListener('touchstart', onTouchStart, { passive: false });
    sc.addEventListener('touchmove', onTouchMove, { passive: false });
    sc.addEventListener('touchend', onTouchEnd, { passive: false });
    sc.addEventListener('touchcancel', onTouchEnd, { passive: false });
    sc.addEventListener('wheel', onWheel, { passive: false });
    sc.addEventListener('scroll', () => {
      if (S) { requestLive(); requestCull(); scheduleViewSave(); scheduleTitle(); }
    }, { passive: true });
  }

  function onPointerDown(e) {
    if (!S || !S.content || !isPen(e)) return;
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    if (input.penDown) return;
    hidePops();
    if (document.activeElement === ui.findInput) ui.findInput.blur();
    e.preventDefault();
    try { ui.scroller.setPointerCapture(e.pointerId); } catch (_) {}
    input.penId = e.pointerId;
    input.penDown = true;
    input.pinch = null;
    ui.scroller.style.overflow = 'hidden'; // avuç içi kaydırmasın
    const pr = ui.page.getBoundingClientRect();
    input.pr = pr;
    const [x, y] = toPage(e, pr);
    const p = e.pointerType === 'pen' ? (e.pressure || 0.5) : 0.5;
    if (S.hidden) { input.penDown = false; restoreScroll(); toast('Notlar gizli — menüden göster'); return; }
    const tool = S.tool;
    if (tool === 'pen' || tool === 'hl') {
      endSelection();
      const b = G.builder(0.6 / S.z);
      b.add(x, y, p, 0);
      input.stroke = {
        t: tool, c: S.color[tool], w: TOOLS[tool].sizes[S.size[tool]],
        b, predicted: null, snapped: false, snapPts: null, lastMove: performance.now(), lx: e.clientX, ly: e.clientY,
      };
      armSnap();
      input.cursor = null;
      requestLive();
    } else if (tool === 'eraser') {
      input.erase = { before: new Map(), after: new Map(), lx: x, ly: y };
      eraseAt(x, y);
      setEraserCursor(x, y, true);
    } else if (tool === 'lasso') {
      if (S.sel && onHandle(x, y)) {
        const b = S.sel.b;
        input.resize = { ax: b[0], ay: b[1], cx: b[2], cy: b[3], k: 1 };
      } else if (S.sel && inSel(x, y)) {
        input.move = { x0: x, y0: y, dx: 0, dy: 0 };
      } else {
        endSelection();
        input.lasso = [x, y];
      }
      requestLive();
    }
  }

  function onPointerMove(e) {
    if (!S || !S.content || !isPen(e)) return;
    const pr = input.penDown ? input.pr : ui.page.getBoundingClientRect();
    if (!input.penDown || e.pointerId !== input.penId) {
      // Apple Pencil hover (iPad Pro): araç boyutunu gösteren imleç.
      if (e.pointerType === 'pen' && !input.penDown) {
        const [x, y] = toPage(e, pr);
        hoverCursor(x, y);
      }
      return;
    }
    e.preventDefault();
    const list = (e.getCoalescedEvents && e.getCoalescedEvents()) || [];
    const evs = list.length ? list : [e];
    if (input.stroke) {
      const st = input.stroke;
      if (Math.hypot(e.clientX - st.lx, e.clientY - st.ly) > 2.5) {
        st.lx = e.clientX; st.ly = e.clientY; st.lastMove = performance.now();
        if (!st.snapped) armSnap();
      }
      if (st.snapped) {
        const [x, y] = toPage(e, pr);
        const p0 = st.b.pts;
        st.snapPts = G.lineBetween(p0[0], p0[1], x, y, st.snapP);
      } else {
        for (const ev of evs) {
          const [x, y] = toPage(ev, pr);
          const p = ev.pointerType === 'pen' ? (ev.pressure || 0.5) : 0.5;
          st.b.add(x, y, p, st.t === 'hl' ? 0.45 : 0.2);
        }
        const pred = e.getPredictedEvents ? e.getPredictedEvents() : null;
        if (pred && pred.length) {
          const last = pred[pred.length - 1];
          const [x, y] = toPage(last, pr);
          const pp = st.b.pts;
          st.predicted = [x, y, pp[pp.length - 1]];
        } else st.predicted = null;
      }
      requestLive();
    } else if (input.erase) {
      for (const ev of evs) {
        const [x, y] = toPage(ev, pr);
        // Hızlı harekette aradaki noktaları da sil.
        const er = eraserR();
        const steps = Math.max(1, Math.ceil(Math.hypot(x - input.erase.lx, y - input.erase.ly) / (er * 0.6)));
        for (let i = 1; i <= steps; i++) {
          eraseAt(input.erase.lx + (x - input.erase.lx) * i / steps, input.erase.ly + (y - input.erase.ly) * i / steps);
        }
        input.erase.lx = x; input.erase.ly = y;
      }
      const [x, y] = toPage(e, pr);
      setEraserCursor(x, y, true);
    } else if (input.lasso) {
      for (const ev of evs) {
        const [x, y] = toPage(ev, pr);
        const l = input.lasso;
        if (Math.hypot(x - l[l.length - 2], y - l[l.length - 1]) > 2 / S.z) l.push(rd(x), rd(y));
      }
      requestLive();
    } else if (input.move) {
      const [x, y] = toPage(e, pr);
      input.move.dx = x - input.move.x0;
      input.move.dy = y - input.move.y0;
      // Yollar 10x ölçekli grupta; taşıma da o ölçekte.
      const tr = `translate(${rd(input.move.dx / PATH_SCALE)} ${rd(input.move.dy / PATH_SCALE)})`;
      for (const id of S.sel.ids) { const el = S.els.get(id); if (el) el.setAttribute('transform', tr); }
      placeSelBox(input.move.dx, input.move.dy, 1);
    } else if (input.resize) {
      const [x, y] = toPage(e, pr);
      const R = input.resize;
      const den = Math.max(1, (R.cx - R.ax) + (R.cy - R.ay));
      R.k = clamp(((x - R.ax) + (y - R.ay)) / den, 0.2, 5);
      const k = R.k;
      const tr = `matrix(${rd(k)} 0 0 ${rd(k)} ${rd(R.ax / PATH_SCALE * (1 - k))} ${rd(R.ay / PATH_SCALE * (1 - k))})`;
      for (const id of S.sel.ids) { const el = S.els.get(id); if (el) el.setAttribute('transform', tr); }
      placeSelBox(0, 0, k);
    }
  }

  function onPointerUp(e) {
    if (!S || !input.penDown || (e.pointerId !== undefined && e.pointerId !== input.penId)) return;
    input.penDown = false;
    input.lastPen = performance.now();
    clearTimeout(input.snapTimer);
    restoreScroll();
    if (input.stroke) {
      const st = input.stroke;
      input.stroke = null;
      let pts = st.snapped ? st.snapPts : st.b.pts;
      // Fosforlu kalem: yatay çekilen çizgi düzleşir ve metin satırına oturur.
      if (st.t === 'hl' && !st.snapped && S.hlSnap) pts = G.straightenHl(pts, textLines()) || pts;
      if (pts && pts.length) {
        const s = { id: nowId(), t: st.t, c: st.c, w: st.w, p: pts.slice() };
        S.doc.strokes.push(s);
        addEl(s);
        commitOp({ before: [], after: [s] });
      }
    } else if (input.erase) {
      const er = input.erase;
      input.erase = null;
      commitOp({ before: [...er.before.values()], after: [...er.after.values()] });
    } else if (input.lasso) {
      const poly = input.lasso;
      input.lasso = null;
      const ids = G.lassoSelect(S.doc.strokes, poly);
      if (ids.length) startSelection(ids); else toast('Seçilecek not bulunamadı');
    } else if (input.move) {
      const mv = input.move;
      input.move = null;
      for (const id of S.sel.ids) { const el = S.els.get(id); if (el) el.removeAttribute('transform'); }
      if (Math.abs(mv.dx) > 0.5 || Math.abs(mv.dy) > 0.5) {
        transformSelection(s => G.translated(s, mv.dx, mv.dy));
      } else placeSelBox(0, 0, 1);
    } else if (input.resize) {
      const R = input.resize;
      input.resize = null;
      for (const id of S.sel.ids) { const el = S.els.get(id); if (el) el.removeAttribute('transform'); }
      if (Math.abs(R.k - 1) > 0.01) transformSelection(s => G.scaled(s, R.ax, R.ay, R.k));
      else placeSelBox(0, 0, 1);
    }
    input.cursor = null;
    requestLive();
  }

  function restoreScroll() {
    // Kalem kalktıktan hemen sonra avuç içi kaydırmasın.
    clearTimeout(input.scrollTimer);
    input.scrollTimer = setTimeout(() => { if (!input.penDown) ui.scroller.style.overflow = ''; }, 260);
  }

  // Basılı tutunca düz çizgi (Notlar uygulaması gibi).
  function armSnap() {
    clearTimeout(input.snapTimer);
    input.snapTimer = setTimeout(() => {
      const st = input.stroke;
      if (!st || st.snapped || !G.nearlyStraight(st.b.pts)) return;
      const p = st.b.pts;
      let sum = 0;
      for (let i = 2; i < p.length; i += 3) sum += p[i];
      st.snapP = sum / (p.length / 3);
      st.snapped = true;
      st.snapPts = G.lineBetween(p[0], p[1], p[p.length - 3], p[p.length - 2], st.snapP);
      try { navigator.vibrate && navigator.vibrate(8); } catch (_) {}
      requestLive();
    }, 480);
  }

  /** Metin satırlarının kutuları (sayfa birimi); fosforlu kalem hizası için, ilk gerektiğinde ölçülür. */
  function textLines() {
    if (S.lines) return S.lines;
    const out = [];
    const pr = ui.page.getBoundingClientRect(), z = S.z;
    const walker = document.createTreeWalker(S.content, NodeFilter.SHOW_TEXT);
    const range = document.createRange();
    for (let n = walker.nextNode(); n; n = walker.nextNode()) {
      if (!n.nodeValue.trim()) continue;
      range.selectNodeContents(n);
      for (const r of range.getClientRects()) {
        if (r.width < 1 || r.height < 1) continue;
        out.push((r.left - pr.left) / z, (r.top - pr.top) / z, (r.right - pr.left) / z, (r.bottom - pr.top) / z);
      }
    }
    S.lines = out;
    return out;
  }

  function eraserR() { return TOOLS.eraser.sizes[S.size.eraser] / 2 + 0.5; }
  function eraseAt(x, y) {
    const er = eraserR();
    const E = input.erase;
    const only = S.eraseHl;
    if (S.eraseMode === 'stroke') {
      const gone = S.doc.strokes.filter(s => (!only || s.t === 'hl') && G.hits(s, x, y, er));
      if (!gone.length) return;
      const set = new Set(gone.map(s => s.id));
      for (const s of gone) {
        removeEl(s.id);
        if (E.after.has(s.id)) E.after.delete(s.id); else E.before.set(s.id, s);
      }
      S.doc.strokes = S.doc.strokes.filter(s => !set.has(s.id));
    } else {
      const next = [];
      let touched = false;
      for (const s of S.doc.strokes) {
        const runs = only && s.t !== 'hl' ? null : G.eraseSplit(s, x, y, er);
        if (!runs) { next.push(s); continue; }
        touched = true;
        removeEl(s.id);
        if (E.after.has(s.id)) E.after.delete(s.id); else E.before.set(s.id, s);
        for (const p of runs) {
          const piece = { id: nowId(), t: s.t, c: s.c, w: s.w, p };
          next.push(piece);
          addEl(piece);
          E.after.set(piece.id, piece);
        }
      }
      if (touched) S.doc.strokes = next;
    }
  }
  function setEraserCursor(x, y, down) {
    input.cursor = { x, y, r: eraserR(), fill: down ? 'rgba(255,255,255,0.5)' : null };
    requestLive();
  }
  function hoverCursor(x, y) {
    if (S.tool === 'eraser') return setEraserCursor(x, y, false);
    if (S.tool === 'pen' || S.tool === 'hl') {
      input.cursor = { x, y, r: Math.max(1.2, TOOLS[S.tool].sizes[S.size[S.tool]] / 2) };
      requestLive();
    }
  }

  // ───────── Seçim (kement) ─────────
  function selBounds(ids) {
    const set = new Set(ids);
    let b = [Infinity, Infinity, -Infinity, -Infinity];
    for (const s of S.doc.strokes) {
      if (!set.has(s.id)) continue;
      const sb = s.b || (s.b = G.bounds(s));
      b = [Math.min(b[0], sb[0]), Math.min(b[1], sb[1]), Math.max(b[2], sb[2]), Math.max(b[3], sb[3])];
    }
    return b;
  }
  function startSelection(ids) {
    S.sel = { ids, b: selBounds(ids) };
    S.selEl.style.setProperty('--hn-inv', String(1 / S.z));
    placeSelBox(0, 0, 1);
    ui.selcount.textContent = ids.length === 1 ? '1 çizgi' : ids.length + ' çizgi';
    ui.selbar.classList.add('hn-show');
  }
  const SEL_PAD = 8;
  function placeSelBox(dx, dy, k) {
    const el = S.selEl, b = S.sel.b, pad = SEL_PAD;
    const x1 = b[0] + (b[2] - b[0]) * k, y1 = b[1] + (b[3] - b[1]) * k;
    el.style.display = 'block';
    el.style.left = (b[0] - pad + dx) + 'px';
    el.style.top = (b[1] - pad + dy) + 'px';
    el.style.width = (x1 - b[0] + 2 * pad) + 'px';
    el.style.height = (y1 - b[1] + 2 * pad) + 'px';
  }
  function inSel(x, y) {
    const b = S.sel.b, pad = 14;
    return x >= b[0] - pad && x <= b[2] + pad && y >= b[1] - pad && y <= b[3] + pad;
  }
  /** Sağ alt köşedeki boyutlandırma tutamacı (ekranda ~26 px). */
  function onHandle(x, y) {
    const b = S.sel.b;
    return Math.hypot(x - (b[2] + SEL_PAD), y - (b[3] + SEL_PAD)) <= 18 / S.z + 4;
  }
  function endSelection() {
    if (!S || !S.sel) return;
    S.sel = null;
    S.selEl.style.display = 'none';
    ui.selbar.classList.remove('hn-show');
    ui.recolor.classList.remove('hn-show');
  }
  function selectedStrokes() {
    const set = new Set(S.sel.ids);
    return S.doc.strokes.filter(s => set.has(s.id));
  }
  function transformSelection(fn) {
    const before = selectedStrokes();
    const after = before.map(fn);
    const op = { before, after };
    runOp(op, false);
    commitOp(op);
    startSelection(after.map(s => s.id));
  }
  function selectionAction(a) {
    if (!S.sel) return;
    const chosen = selectedStrokes();
    if (a === 'seldel') {
      const op = { before: chosen, after: [] };
      runOp(op, false); commitOp(op); endSelection();
    } else if (a === 'seldup') {
      const copies = chosen.map(s => ({ ...G.translated(s, 24, 24), id: nowId() }));
      const op = { before: [], after: copies };
      runOp(op, false); commitOp(op); startSelection(copies.map(s => s.id));
    } else if (a === 'selcolor') toggleRecolor();
    else if (a === 'seloff') endSelection();
  }
  function selectAll() {
    if (!S.doc.strokes.length) return toast('Bu özette not yok');
    if (S.tool !== 'lasso') setTool('lasso');
    startSelection(S.doc.strokes.map(s => s.id));
  }
  /** Seçimin rengi: kalem renkleri yalnız kalem çizgilerine, fosforlular fosforlulara. */
  function toggleRecolor() {
    const m = ui.recolor, was = m.classList.contains('hn-show');
    hidePops();
    if (was || !S.sel) return;
    const kinds = new Set(selectedStrokes().map(s => s.t));
    let h = '';
    for (const t of ['pen', 'hl']) {
      if (!kinds.has(t)) continue;
      h += `<div class="hn-h">${t === 'pen' ? 'Kalem' : 'Fosforlu kalem'}</div><div class="hn-swrow">`;
      for (const c of TOOLS[t].colors) h += swatch(c, false, ` data-t="${t}"`);
      h += '</div>';
    }
    m.innerHTML = h;
    m.classList.add('hn-show');
  }
  function onRecolorClick(e) {
    const b = e.target.closest('button[data-color]');
    if (!b || !S || !S.sel) return;
    const t = b.dataset.t, color = b.dataset.color;
    const set = new Set(S.sel.ids);
    const before = S.doc.strokes.filter(s => set.has(s.id) && s.t === t && s.c !== color);
    if (!before.length) return;
    const after = before.map(s => ({ id: s.id, t: s.t, c: color, w: s.w, p: s.p }));
    const op = { before, after };
    runOp(op, false); commitOp(op);
    startSelection(S.sel.ids);
  }

  // ───────── Dokunma: kaydırma, yakınlaştırma, hareketler ─────────
  function onTouchStart(e) {
    if (!S || !S.content) return;
    const now = performance.now();
    let stylus = false, palm = false;
    for (const t of e.changedTouches) {
      if (t.touchType === 'stylus') stylus = true;
      else if ((t.radiusX || 0) > 34 || (t.radiusY || 0) > 34) palm = true;
    }
    // Kalem yazarken (ve hemen sonrasında) hiçbir dokunuş kaydırmasın.
    if (stylus || palm || input.penDown || now - input.lastPen < 350) { e.preventDefault(); return; }
    for (const t of e.changedTouches) input.touches.set(t.identifier, { x0: t.clientX, y0: t.clientY, x: t.clientX, y: t.clientY });
    const direct = [...e.touches].filter(t => t.touchType !== 'stylus');
    if (direct.length >= 2) {
      e.preventDefault();
      cancelAnimationFrame(zoomAnim);
      const [a, b] = direct;
      const rect = ui.scroller.getBoundingClientRect();
      input.pinch = {
        d0: Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY) || 1,
        z0: S.z,
        cx: (a.clientX + b.clientX) / 2 - rect.left, cy: (a.clientY + b.clientY) / 2 - rect.top,
        rect,
      };
      ui.page.style.willChange = 'transform';
      input.lastTap = null;
      if (!input.tap || now - input.tap.t0 > 260) input.tap = { t0: now, n: direct.length, moved: false, z: S.z };
      else input.tap.n = Math.max(input.tap.n, direct.length);
    } else if (direct.length === 1) {
      input.tap = { t0: now, n: 1, moved: false, z: S.z, x: direct[0].clientX, y: direct[0].clientY };
    }
  }
  let pinchQueued = false;
  function onTouchMove(e) {
    if (!S) return;
    if (input.penDown) { e.preventDefault(); return; }
    for (const t of e.changedTouches) {
      const r = input.touches.get(t.identifier);
      if (r) { r.x = t.clientX; r.y = t.clientY; if (Math.hypot(r.x - r.x0, r.y - r.y0) > 10 && input.tap) input.tap.moved = true; }
    }
    const pz = input.pinch;
    if (!pz) return;
    e.preventDefault();
    const direct = [...e.touches].filter(t => t.touchType !== 'stylus');
    if (direct.length < 2) return;
    const [a, b] = direct;
    pz.d = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY);
    pz.nx = (a.clientX + b.clientX) / 2 - pz.rect.left;
    pz.ny = (a.clientY + b.clientY) / 2 - pz.rect.top;
    if (!pinchQueued) {
      pinchQueued = true;
      requestAnimationFrame(() => {
        pinchQueued = false;
        const p = input.pinch;
        if (!p || !p.d) return;
        // Odak noktası parmakların ortasında kalır; ortası kayarsa sayfa da kayar.
        setZoom(p.z0 * p.d / p.d0, p.cx, p.cy, true);
        ui.scroller.scrollLeft -= p.nx - p.cx;
        ui.scroller.scrollTop -= p.ny - p.cy;
        p.cx = p.nx; p.cy = p.ny; p.z0 = S.z; p.d0 = p.d;
        requestLive();
      });
    }
  }
  function onTouchEnd(e) {
    if (!S) return;
    for (const t of e.changedTouches) input.touches.delete(t.identifier);
    const remaining = [...e.touches].filter(t => t.touchType !== 'stylus');
    if (input.pinch && remaining.length < 2) {
      input.pinch = null;
      setTimeout(() => { if (!input.pinch) ui.page.style.willChange = ''; }, 120);
      scheduleViewSave();
    }
    if (remaining.length === 0 && input.tap) {
      const tp = input.tap;
      input.tap = null;
      const now = performance.now();
      const quick = now - tp.t0 < 300;
      const sameZoom = Math.abs(S.z - tp.z) / tp.z < 0.04;
      if (quick && !tp.moved && sameZoom) {
        if (tp.n === 2) undo();
        else if (tp.n >= 3) redo();
        else if (tp.n === 1) {
          // Tek parmakla çift dokunma: yakınlaş / sayfaya sığdır.
          const lt = input.lastTap;
          if (lt && now - lt.t < 330 && Math.hypot(tp.x - lt.x, tp.y - lt.y) < 40) {
            input.lastTap = null;
            e.preventDefault();
            const rect = ui.scroller.getBoundingClientRect();
            animateZoom(S.rz > 1.3 ? fitZoom() : fitZoom() * 2, tp.x - rect.left, tp.y - rect.top);
            scheduleViewSave();
          } else input.lastTap = { t: now, x: tp.x, y: tp.y };
        }
      }
    }
  }
  function onScrollerClick() { if (anyPop()) hidePops(); }
  function onWheel(e) {
    if (!S || !(e.ctrlKey || e.metaKey)) return; // normal tekerlek kaydırır
    e.preventDefault();
    const rect = ui.scroller.getBoundingClientRect();
    setZoom(S.z * Math.exp(-e.deltaY * 0.01), e.clientX - rect.left, e.clientY - rect.top);
  }
  function zoomBy(k) {
    const v = viewSize();
    animateZoom(clamp(S.z * k, 0.3, 5), v.w / 2, v.h / 3);
    scheduleViewSave();
  }
  function onKey(e) {
    if (!isOpen()) return;
    const mod = e.metaKey || e.ctrlKey;
    const key = e.key;
    if (e.target === ui.findInput) {
      e.stopPropagation();
      if (key === 'Escape') { e.preventDefault(); closeFind(); }
      else if (key === 'Enter' || (mod && (key === 'g' || key === 'G'))) { e.preventDefault(); stepFind(e.shiftKey ? -1 : 1); }
      return;
    }
    e.stopPropagation();
    if (key === 'Escape') {
      if (!S) close();
      else if (S.find) closeFind();
      else if (S.sel) endSelection();
      else if (anyPop()) hidePops();
      else close();
      return;
    }
    if (!S || !S.content) return;
    if (mod && (key === 'z' || key === 'Z')) { e.preventDefault(); e.shiftKey ? redo() : undo(); }
    else if (mod && (key === 'y' || key === 'Y')) { e.preventDefault(); redo(); }
    else if (mod && (key === 'f' || key === 'F')) { e.preventDefault(); openFind(); }
    else if (mod && (key === 'g' || key === 'G')) { e.preventDefault(); if (S.find) stepFind(e.shiftKey ? -1 : 1); else openFind(); }
    else if (mod && (key === 'p' || key === 'P')) { e.preventDefault(); printNotes(); }
    else if (mod && (key === 'a' || key === 'A')) { e.preventDefault(); selectAll(); }
    else if (mod && key === '0') { e.preventDefault(); fitWidth(true); }
    else if (mod && (key === '=' || key === '+')) { e.preventDefault(); zoomBy(1.25); }
    else if (mod && key === '-') { e.preventDefault(); zoomBy(0.8); }
    else if (!mod && /^[1-4]$/.test(key)) setTool(['pen', 'hl', 'eraser', 'lasso'][+key - 1]);
    else if ((key === 'Backspace' || key === 'Delete') && S.sel) { e.preventDefault(); selectionAction('seldel'); }
  }

  // ───────── Araç çubuğu ─────────
  function setTool(t) {
    if (!TOOLS[t]) return;
    if (t === S.tool && t === 'eraser') { toggleEraserMenu(ui.bar.querySelector('[data-tool="eraser"]')); return; }
    if (t !== 'lasso') endSelection();
    S.tool = t;
    prefs.set('tool', t);
    hidePops();
    refreshToolbar();
  }
  const swatch = (c, on, extra = '') =>
    `<button class="hn-btn hn-sw${on ? ' hn-on' : ''}" data-color="${c}"${extra} aria-label="${COLOR_NAMES[c] || 'Renk'}"><i style="background:${c}"></i></button>`;
  function optionsHtml(t) {
    const cfg = TOOLS[t];
    let h = '';
    if (t === 'pen' || t === 'hl') cfg.colors.forEach(c => { h += swatch(c, S.color[t] === c); });
    if (t === 'lasso') h += '<span class="hn-hint">Notların etrafını çizerek seç</span>';
    if (cfg.sizes) {
      h += '<span class="hn-gap"></span>';
      cfg.sizes.forEach((s, i) => {
        const dot = DOTS[t][i];
        h += `<button class="hn-btn hn-size${S.size[t] === i ? ' hn-on' : ''}" data-size="${i}" aria-label="Kalınlık ${i + 1}"><i style="width:${dot}px;height:${dot}px"></i></button>`;
      });
    }
    return h;
  }
  function refreshToolbar() {
    for (const b of ui.bar.querySelectorAll('.hn-tool')) {
      b.classList.toggle('hn-on', b.dataset.tool === S.tool);
      b.setAttribute('aria-pressed', String(b.dataset.tool === S.tool));
    }
    const t = S.tool;
    let h = optionsHtml(t);
    if (t === 'eraser') h += `<button class="hn-btn hn-emode" data-a="emode">${S.eraseMode === 'stroke' ? 'Çizgi' : 'Hassas'}${S.eraseHl ? ' · fosforlu' : ''} ▾</button>`;
    ui.opts.innerHTML = h;
    // Dar ekranda renk ve kalınlık tek düğmede toplanır.
    const st = ui.style;
    st.classList.toggle('hn-none', t === 'lasso');
    const i = st.querySelector('i');
    if (t === 'pen' || t === 'hl') {
      i.className = '';
      i.style.background = S.color[t];
      i.innerHTML = `<b style="width:${Math.round(DOTS[t][S.size[t]] * 0.7)}px;height:${Math.round(DOTS[t][S.size[t]] * 0.7)}px"></b>`;
    } else if (t === 'eraser') {
      i.className = 'hn-er';
      i.style.background = '';
      i.innerHTML = `<b style="width:${DOTS.eraser[S.size.eraser]}px;height:${DOTS.eraser[S.size.eraser]}px"></b>`;
    }
    refreshUndo();
    fitBar();
  }
  /** Sığana kadar araç çubuğunu sıkıştırır (başlık → etiket → arama → renkler → küçük düğmeler). */
  function fitBar() {
    const bar = ui.bar;
    let lv = 0;
    for (; lv <= 5; lv++) {
      for (let k = 1; k <= 5; k++) bar.classList.toggle('hn-c' + k, lv >= k);
      if (bar.scrollWidth <= bar.clientWidth + 1) break;
    }
    S.barLevel = Math.min(lv, 5);
  }
  function refreshUndo() {
    ui.undo.disabled = !S.undo.length;
    ui.redo.disabled = !S.redo.length;
  }
  function onBarClick(e) {
    const b = e.target.closest('button');
    if (!b) return;
    const a = b.dataset.a;
    if (a === 'close') return close();
    if (!S || !S.content) return;
    if (b.dataset.tool) return setTool(b.dataset.tool);
    if (b.dataset.color) {
      S.color[S.tool] = b.dataset.color;
      prefs.set('c.' + S.tool, b.dataset.color);
      refreshToolbar();
      if (ui.stylePop.classList.contains('hn-show')) fillStylePop();
      return;
    }
    if (b.dataset.size) {
      S.size[S.tool] = +b.dataset.size;
      prefs.set('s.' + S.tool, +b.dataset.size);
      refreshToolbar();
      if (ui.stylePop.classList.contains('hn-show')) fillStylePop();
      return;
    }
    if (a === 'undo') return undo();
    if (a === 'redo') return redo();
    if (a === 'more') return toggleMenu();
    if (a === 'toc') return toggleToc();
    if (a === 'find') return S.find ? closeFind() : openFind();
    if (a === 'style') return toggleStylePop(b);
    if (a === 'emode') return toggleEraserMenu(b);
    if (a && a.startsWith('sel')) return selectionAction(a);
  }

  function anyPop() { return ui.root.querySelector('.hn-pop.hn-show'); }
  function hidePops() { if (ui) for (const p of ui.root.querySelectorAll('.hn-pop')) p.classList.remove('hn-show'); }
  /** Açılır pencereyi düğmenin altına, ekrandan taşmadan yerleştirir. */
  function showPopAt(pop, btn) {
    pop.style.left = '0px';
    pop.style.right = 'auto';
    pop.classList.add('hn-show');
    const br = btn.getBoundingClientRect(), rr = ui.root.getBoundingClientRect();
    const w = pop.offsetWidth;
    pop.style.left = clamp(br.left + br.width / 2 - w / 2 - rr.left, 8, Math.max(8, rr.width - w - 8)) + 'px';
  }
  function toggleStylePop(btn) {
    const m = ui.stylePop, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    fillStylePop();
    showPopAt(m, btn);
  }
  function fillStylePop() {
    const t = S.tool, cfg = TOOLS[t];
    let h = '';
    if (cfg.colors) {
      h += `<div class="hn-h">${cfg.label}</div><div class="hn-swrow">`;
      cfg.colors.forEach(c => { h += swatch(c, S.color[t] === c); });
      h += '</div>';
    }
    if (cfg.sizes) {
      h += '<div class="hn-h">Kalınlık</div><div class="hn-swrow">';
      cfg.sizes.forEach((s, i) => {
        const dot = DOTS[t][i];
        h += `<button class="hn-btn hn-size${S.size[t] === i ? ' hn-on' : ''}" data-size="${i}" aria-label="Kalınlık ${i + 1}"><i style="width:${dot}px;height:${dot}px"></i></button>`;
      });
      h += '</div>';
    }
    if (t === 'eraser') h += `<div class="hn-swrow"><button class="hn-btn hn-emode" data-a="emode">Silgi türü: ${S.eraseMode === 'stroke' ? 'Çizgi' : 'Hassas'} ▾</button></div>`;
    ui.stylePop.innerHTML = h;
  }
  function toggleMenu() {
    const m = ui.menu, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    const n = S.doc.strokes.length;
    const tick = on => `<b class="hn-tick">${on ? '✓' : ''}</b>`;
    m.innerHTML = `
      ${S.barLevel >= 5 ? '<button data-m="redo">Yinele</button>' : ''}${S.barLevel === 3 || S.barLevel >= 5 ? '<button data-m="find">Özette ara</button>' : ''}${S.barLevel === 3 || S.barLevel >= 5 ? '<hr>' : ''}
      <button data-m="fit">Sayfayı ekrana sığdır</button>
      <button data-m="hide">${S.hidden ? 'Notları göster' : 'Notları gizle'}</button>
      <button data-m="extend">Sayfa sonuna not alanı ekle</button>
      <button data-m="hlsnap">${tick(S.hlSnap)}Fosforlu kalemi satıra hizala</button>
      <hr>
      <button data-m="print">Yazdır / PDF olarak kaydet</button>
      <button data-m="export">Notları yedekle (dosya)</button>
      <button data-m="import">Yedekten geri yükle…</button>
      <hr>
      <button data-m="clear" class="hn-danger">Bu özetteki tüm notları sil</button>
      <div class="hn-h">İpuçları</div>
      <div class="hn-tips">
        Kalemle yaz, parmakla kaydır. İki parmakla dokun: geri al · üç parmak: yinele · çift dokun: yakınlaş.
        Çizgiyi bitirirken kalemi bekletirsen düz çizgiye dönüşür. Seçimi köşesindeki tutamaçtan büyütebilirsin.
      </div>
      <div class="hn-stat">${n ? n + ' not' : 'Henüz not yok'}${S.loadPending ? ' · kayıtlı notlar yükleniyor' : ''}</div>`;
    m.classList.add('hn-show');
  }
  function toggleEraserMenu(btn) {
    const m = ui.eopts, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    m.innerHTML = `
      <div class="hn-h">Silgi</div>
      <button data-m="estroke" class="${S.eraseMode === 'stroke' ? 'hn-on' : ''}">Çizgi silgisi — dokunduğu çizgiyi tamamen siler</button>
      <button data-m="eprecise" class="${S.eraseMode === 'precise' ? 'hn-on' : ''}">Hassas silgi — yalnız üstünden geçtiği kısmı siler</button>
      <hr>
      <button data-m="ehl"><b class="hn-tick">${S.eraseHl ? '✓' : ''}</b>Yalnız fosforlu kalemi sil</button>`;
    showPopAt(m, btn || ui.bar.querySelector('[data-tool="eraser"]'));
  }
  function sectionCounts() {
    const counts = new Map();
    let extra = 0;
    for (const s of S.doc.strokes) {
      const b = s.b || (s.b = G.bounds(s));
      const cy = (b[1] + b[3]) / 2;
      if (cy > S.contentH) { extra++; continue; }
      const sec = sectionAt(cy);
      if (sec) counts.set(sec, (counts.get(sec) || 0) + 1);
    }
    return { counts, extra };
  }
  function viewTopY() { return (ui.scroller.scrollTop - OFF_Y) / S.z; }
  function currentSection() { return sectionAt(viewTopY() + viewSize().h / S.z * 0.25); }
  function toggleToc() {
    const m = ui.toc, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    const { counts, extra } = sectionCounts();
    const cur = currentSection();
    let h = `<div class="hn-h">İçindekiler</div><button data-tf="1" class="hn-tfind">${ICONS.search}<span>Özette ara</span></button>`;
    S.sections.forEach((s, i) => {
      if (s.part) { h += `<div class="hn-part">${esc(s.text)}</div>`; return; }
      const n = counts.get(s) || 0;
      h += `<button data-sec="${i}"${s === cur ? ' class="hn-cur"' : ''}><b>${esc(s.no)}</b><span>${esc(s.text)}</span>${n ? `<em title="${n} not">${n}</em>` : ''}</button>`;
    });
    if (extra) h += `<button data-sec="extra"><b>+</b><span>Sayfa sonundaki not alanı</span><em>${extra}</em></button>`;
    m.innerHTML = h;
    m.classList.add('hn-show');
    const c = m.querySelector('.hn-cur');
    if (c) m.scrollTop = Math.max(0, c.offsetTop - m.clientHeight / 2 + c.offsetHeight / 2);
  }
  function onTocClick(e) {
    const f = e.target.closest('button[data-tf]');
    if (f) { hidePops(); openFind(); return; }
    const b = e.target.closest('button[data-sec]');
    if (!b) return;
    hidePops();
    const y = b.dataset.sec === 'extra' ? S.contentH : S.sections[+b.dataset.sec].y;
    ui.scroller.scrollTo({ top: Math.max(0, (y - 20) * S.z + OFF_Y), behavior: 'smooth' });
  }
  let titleQueued = false;
  function scheduleTitle() {
    if (titleQueued) return;
    titleQueued = true;
    requestAnimationFrame(() => { titleQueued = false; updateTitle(); });
  }
  /** Başlığın altında okunan bölüm. */
  function updateTitle() {
    if (!S || !S.content || S.barLevel >= 1) return;
    const sec = currentSection();
    const sub = sec ? sec.no + ' · ' + sec.text : '';
    if (ui.titleSub.textContent !== sub) ui.titleSub.textContent = sub;
  }
  function onMenuClick(e) {
    const b = e.target.closest('button[data-m]');
    if (!b || !S || !S.content) return;
    const m = b.dataset.m;
    hidePops();
    if (m === 'fit') fitWidth(true);
    else if (m === 'redo') redo();
    else if (m === 'find') openFind();
    else if (m === 'hide') { S.hidden = !S.hidden; S.ink.classList.toggle('hn-hidden', S.hidden); endSelection(); S.ver++; toast(S.hidden ? 'Notlar gizlendi' : 'Notlar gösteriliyor'); }
    else if (m === 'extend') { S.doc.extra = Math.min(20000, S.doc.extra + 900); changed(); updatePageHeight(); toast('Sayfa sonuna boş alan eklendi'); }
    else if (m === 'hlsnap') { S.hlSnap = !S.hlSnap; prefs.set('hlSnap', S.hlSnap); toast(S.hlSnap ? 'Fosforlu kalem satıra hizalanacak' : 'Fosforlu kalem serbest'); }
    else if (m === 'print') printNotes();
    else if (m === 'export') exportNotes();
    else if (m === 'import') importNotes();
    else if (m === 'clear') {
      if (!S.doc.strokes.length) return toast('Bu özette not yok');
      if (!window.confirm('Bu özetteki tüm notlar silinsin mi? (Geri al ile geri getirebilirsin.)')) return;
      endSelection();
      const op = { before: S.doc.strokes.slice(), after: [] };
      runOp(op, false); commitOp(op);
    } else if (m === 'estroke' || m === 'eprecise') {
      S.eraseMode = m === 'estroke' ? 'stroke' : 'precise';
      prefs.set('eraseMode', S.eraseMode);
      refreshToolbar();
    } else if (m === 'ehl') {
      S.eraseHl = !S.eraseHl;
      prefs.set('eraseHl', S.eraseHl);
      refreshToolbar();
    }
  }

  // ───────── Arama ─────────
  function openFind() {
    if (!S || !S.content) return;
    hidePops();
    ui.find.classList.add('hn-show');
    if (!S.find) S.find = { q: '', hits: [], cur: -1 };
    ui.findInput.focus();
    ui.findInput.select();
  }
  function closeFind() {
    if (!ui) return;
    ui.find.classList.remove('hn-show');
    clearTimeout(ui.findTimer);
    if (document.activeElement === ui.findInput) ui.findInput.blur();
    if (S && S.findEl) S.findEl.innerHTML = '';
    if (S) S.find = null;
    ui.findCount.textContent = '';
  }
  /** Metin düğümlerinden katlanmış tek bir dize; her karakterin kaynağı ni/off'ta. */
  function findIndex() {
    if (S.findIdx) return S.findIdx;
    const nodes = [], ni = [], off = [];
    let text = '', lastBlock = null;
    const walker = document.createTreeWalker(S.content, NodeFilter.SHOW_TEXT);
    for (let n = walker.nextNode(); n; n = walker.nextNode()) {
      const v = n.nodeValue;
      if (!v) continue;
      const blk = n.parentElement && n.parentElement.closest('p,li,td,th,h1,h2,h3,h4,h5,.k,.d,div');
      // Bloklar arasında eşleşme olmasın.
      if (blk !== lastBlock && text && text[text.length - 1] !== '\n') { text += '\n'; ni.push(-1); off.push(0); }
      lastBlock = blk;
      const k = nodes.length;
      nodes.push(n);
      for (let i = 0; i < v.length; i++) {
        const c = v[i];
        if (isSpace(c)) {
          const last = text[text.length - 1];
          if (!text || last === ' ' || last === '\n') continue;
          text += ' ';
        } else text += foldChar(c);
        ni.push(k); off.push(i);
      }
    }
    S.findIdx = { text, nodes, ni: Int32Array.from(ni), off: Int32Array.from(off) };
    return S.findIdx;
  }
  function runFind(q, keep) {
    if (!S || !S.find) return;
    const f = S.find;
    const fq = G.fold(q || '');
    const prevCur = keep ? f.cur : -1;
    f.q = q;
    f.hits = [];
    f.cur = -1;
    S.findEl.innerHTML = '';
    if (!fq) { ui.findCount.textContent = ''; return; }
    const idx = findIndex();
    const range = document.createRange();
    const pr = ui.page.getBoundingClientRect(), z = S.z;
    const frag = document.createDocumentFragment();
    for (let i = idx.text.indexOf(fq); i >= 0 && f.hits.length < 999; i = idx.text.indexOf(fq, i + fq.length)) {
      const a = i, b = i + fq.length - 1;
      range.setStart(idx.nodes[idx.ni[a]], idx.off[a]);
      range.setEnd(idx.nodes[idx.ni[b]], idx.off[b] + 1);
      const els = [];
      let y = Infinity, x = 0;
      for (const r of range.getClientRects()) {
        if (r.width < 0.5) continue;
        const d = document.createElement('i');
        const L = (r.left - pr.left) / z, T = (r.top - pr.top) / z;
        d.style.cssText = `left:${rd(L - 1)}px;top:${rd(T)}px;width:${rd(r.width / z + 2)}px;height:${rd(r.height / z)}px`;
        frag.appendChild(d);
        els.push(d);
        if (T < y) { y = T; x = L; }
      }
      if (els.length) f.hits.push({ els, y, x });
    }
    S.findEl.appendChild(frag);
    if (!f.hits.length) { ui.findCount.textContent = 'Sonuç yok'; return; }
    // İlk sonuç: ekranda görünenlerden ilki (yoksa ekranın altındaki ilk sonuç).
    let start = prevCur;
    if (start < 0 || start >= f.hits.length) {
      const top = viewTopY();
      start = f.hits.findIndex(h => h.y >= top);
      if (start < 0) start = 0;
    }
    setFindCur(start, !keep);
  }
  function setFindCur(i, scroll) {
    const f = S.find;
    if (!f || !f.hits.length) return;
    if (f.cur >= 0 && f.hits[f.cur]) for (const d of f.hits[f.cur].els) d.classList.remove('hn-cur');
    f.cur = (i + f.hits.length) % f.hits.length;
    const h = f.hits[f.cur];
    for (const d of h.els) d.classList.add('hn-cur');
    ui.findCount.textContent = `${f.cur + 1} / ${f.hits.length}${f.hits.length >= 999 ? '+' : ''}`;
    if (scroll) {
      const v = viewSize(), top = viewTopY(), vh = v.h / S.z;
      if (h.y < top + 50 / S.z || h.y > top + vh - 90 / S.z) ui.scroller.scrollTop = Math.max(0, (h.y - vh * 0.3) * S.z + OFF_Y);
      const left = (ui.scroller.scrollLeft - S.ox) / S.z, vw = v.w / S.z;
      if (h.x < left || h.x > left + vw - 40 / S.z) ui.scroller.scrollLeft = Math.max(0, (h.x - vw * 0.2) * S.z + S.ox);
    }
  }
  function stepFind(d) {
    if (!S || !S.find) return;
    if (G.fold(ui.findInput.value) !== G.fold(S.find.q || '')) { clearTimeout(ui.findTimer); runFind(ui.findInput.value); return; }
    if (S.find.hits.length) setFindCur(S.find.cur + d, true);
  }
  function onFindClick(e) {
    const b = e.target.closest('button[data-f]');
    if (!b) return;
    if (b.dataset.f === 'close') closeFind();
    else stepFind(b.dataset.f === 'prev' ? -1 : 1);
  }

  // ───────── Yazdırma ─────────
  // Ekrandaki sayfa A4 sayfalarına bölünür: her sayfa, özetin bir dilimini
  // gösteren kırpılmış bir penceredir (içerik ve notlar birlikte, aynı yerde).
  // Kesimler satırların, kutuların ve notların arasından yapılır; başlıklar
  // altlarındaki metinden ayrılmaz.
  const MM = 96 / 25.4;
  function printNotes() {
    if (!S || !S.content) return;
    hidePops();
    flushSave();
    buildPrint();
    setTimeout(() => window.print(), 60);
  }
  function printIntervals(Hp) {
    const iv = [];
    const b = S.basis;
    for (let i = 0; i < b.keys.length; i++) {
      const k = b.keys[i];
      const kind = k.slice(k.indexOf('|') + 1, k.lastIndexOf('|'));
      const y = b.r[4 * i + 1], h = b.r[4 * i + 3];
      if (h <= 0) continue;
      const head = /^(h[1-5]|div\.part)/.test(kind);
      // Başlık, altındaki ~3 satırla aynı sayfada kalsın.
      if (head) iv.push(y - 2, y + h + 80);
      else if (h < Hp * 0.6) iv.push(y - 2, y + h + 2);
    }
    const lines = textLines();
    for (let k = 0; k < lines.length; k += 4) iv.push(lines[k + 1] - 1, lines[k + 3] + 1);
    if (!S.hidden) {
      for (const s of S.doc.strokes) {
        const bb = s.b || (s.b = G.bounds(s));
        if (bb[3] - bb[1] < Hp * 0.4) iv.push(bb[1] - 2, bb[3] + 2);
      }
    }
    return iv;
  }
  function buildPrint() {
    removePrint();
    const strokes = S.hidden ? [] : S.doc.strokes;
    // Kenarlarda not yoksa yalnız metin sütunu basılır: yazı daha büyük çıkar.
    let marginInk = false, maxY = 0;
    for (const s of strokes) {
      const b = s.b || (s.b = G.bounds(s));
      if (b[0] < MARGIN - 20 || b[2] > PAGE_W - MARGIN + 20) marginInk = true;
      if (b[3] > maxY) maxY = b[3];
    }
    const x0 = marginInk ? 0 : MARGIN - 28;
    const W = PAGE_W - 2 * x0;
    const boxW = 190 * MM, boxH = 268 * MM, footH = 9 * MM;
    const s = boxW / W;
    const Hp = (boxH - footH) / s;
    const H = Math.max(S.contentH, Math.ceil(maxY + 30));
    const br = G.pageBreaks(H, Hp, printIntervals(Hp));
    const wrap = document.createElement('div');
    wrap.className = 'hn-print hn-measuring';
    const kids = [...S.content.children];
    const tops = kids.map(k => k.offsetTop), bots = kids.map((k, i) => tops[i] + k.offsetHeight);
    const pages = [];
    const total = br.length - 1;
    const date = new Date().toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' });
    for (let i = 0; i < total; i++) {
      const a = br[i], b = br[i + 1];
      const pp = document.createElement('div'); pp.className = 'hn-pp';
      const pw = document.createElement('div'); pw.className = 'hn-pw';
      pw.style.height = rd((b - a) * s) + 'px';
      const pc = document.createElement('div'); pc.className = 'hn-pc';
      pc.style.transform = `scale(${s}) translate(${-x0}px, ${-a}px)`;
      const content = document.createElement('div');
      content.className = S.content.className;
      let first = -1;
      for (let j = 0; j < kids.length; j++) {
        if (bots[j] > a - 40 && tops[j] < b + 40) {
          if (first < 0) first = j;
          const c = kids[j].cloneNode(true);
          if (c.id) c.removeAttribute('id');
          for (const el of c.querySelectorAll('[id]')) el.removeAttribute('id');
          content.appendChild(c);
        }
      }
      pc.appendChild(content);
      pc.appendChild(printInk(strokes, a, b));
      pw.appendChild(pc);
      pp.appendChild(pw);
      const sec = sectionAt(a + 1);
      const foot = document.createElement('div');
      foot.className = 'hn-pf';
      foot.innerHTML = `<span>${esc(S.summary.title)}${sec ? ' · ' + esc(sec.no + '. ' + sec.text) : ''}</span><span>${esc(date)}</span><span>${i + 1} / ${total}</span>`;
      pp.appendChild(foot);
      // Sayfa kutusu bir satır içi blok olarak sarılır: satırlar bölünemez, böylece
      // tarayıcı kutunun içindeki kopyayı sonraki kâğıtlara taşıyamaz.
      const ppw = document.createElement('div'); ppw.className = 'hn-ppw';
      ppw.appendChild(pp);
      wrap.appendChild(ppw);
      pages.push({ content, first });
    }
    ui.root.appendChild(wrap);
    // Kopyanın ilk bloğu asıl sayfadaki yerine oturtulur (önceki bloklar kopyalanmadı).
    for (const p of pages) {
      const c = p.content.firstElementChild;
      if (c && p.first >= 0) p.content.style.top = (tops[p.first] - c.offsetTop) + 'px';
    }
    wrap.classList.remove('hn-measuring');
    document.body.classList.add('hn-hasprint');
    S.printEl = wrap;
    S.printVer = S.ver;
  }
  function printInk(strokes, a, b) {
    const pad = 40;
    const svg = document.createElementNS(SVGNS, 'svg');
    svg.setAttribute('class', 'hn-ink');
    svg.setAttribute('width', PAGE_W);
    svg.setAttribute('height', b - a + 2 * pad);
    svg.setAttribute('viewBox', `0 ${a - pad} ${PAGE_W} ${b - a + 2 * pad}`);
    svg.style.top = (a - pad) + 'px';
    const sc = `scale(${PATH_SCALE})`;
    const ghl = document.createElementNS(SVGNS, 'g'); ghl.setAttribute('class', 'hn-hl'); ghl.setAttribute('transform', sc);
    const gpen = document.createElementNS(SVGNS, 'g'); gpen.setAttribute('transform', sc);
    for (const s of strokes) {
      const bb = s.b || (s.b = G.bounds(s));
      if (bb[3] < a - pad || bb[1] > b + pad) continue;
      const path = document.createElementNS(SVGNS, 'path');
      const el = S.els.get(s.id);
      path.setAttribute('d', el ? el.getAttribute('d') : G.outline(s.t, s.w, s.p));
      path.setAttribute('fill', s.c);
      if (s.t === 'hl') path.setAttribute('fill-opacity', '0.42');
      (s.t === 'hl' ? ghl : gpen).appendChild(path);
    }
    svg.append(ghl, gpen);
    return svg;
  }
  function removePrint() {
    if (ui) for (const el of ui.root.querySelectorAll('.hn-print')) el.remove();
    document.body.classList.remove('hn-hasprint');
    if (S) { S.printEl = null; S.printVer = -1; }
  }

  // ───────── Yedek ─────────
  async function exportNotes() {
    await flushSave();
    const data = JSON.stringify({
      app: 'hukuk-notes', v: 2, summary: S.id, version: S.summary.version, exported: new Date().toISOString(),
      doc: { extra: S.doc.extra, basis: S.basisPacked, strokes: S.doc.strokes.map(s => ({ id: s.id, t: s.t, c: s.c, w: s.w, p: s.p })) },
    }, (k, v) => (ArrayBuffer.isView(v) ? Array.from(v) : v));
    const name = `notlar-${S.id}-${new Date().toISOString().slice(0, 10)}.json`;
    const file = new File([data], name, { type: 'application/json' });
    try {
      if (navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], title: 'Özet notları' }); backedUp(); return; }
    } catch (err) { if (err && err.name === 'AbortError') return; }
    const a = document.createElement('a');
    a.href = URL.createObjectURL(file);
    a.download = name;
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 4000);
    backedUp();
  }
  function backedUp() {
    prefs.set('backup.' + S.id, Date.now());
    if (!S.saveFailed) ui.notice.classList.remove('hn-show');
  }

  // Safari, ana ekrana eklenmemiş sitelerin verisini bir süre ziyaret
  // edilmezse silebilir. Not birikince yedek ya da ana ekran hatırlatılır.
  function maybeBackupNotice() {
    const n = S.doc.strokes.length, now = Date.now();
    if (n < 40 || now - prefs.get('notice.snooze', 0) < 3 * 864e5) return;
    let standalone = false;
    try { standalone = navigator.standalone === true || matchMedia('(display-mode: standalone)').matches; } catch (_) {}
    const last = prefs.get('backup.' + S.id, 0), days = Math.floor((now - last) / 864e5);
    let msg = '';
    if (!standalone && days >= 7) msg = 'Safari, ana ekrana eklenmemiş sitelerin verisini silebilir. Notlarını korumak için uygulamayı ana ekrana ekle ya da yedek al.';
    else if (days >= 21) msg = last ? `Son yedekten bu yana ${days} gün geçti.` : 'Notlarının henüz yedeği yok.';
    if (msg) notice(msg, [['Yedekle', 'backup'], ['Sonra', 'later']], 'backup');
  }
  function importNotes() {
    const inp = document.createElement('input');
    inp.type = 'file';
    inp.accept = 'application/json,.json';
    inp.style.display = 'none';
    ui.root.appendChild(inp);
    const st = S;
    inp.onchange = async () => {
      const f = inp.files && inp.files[0];
      inp.remove();
      if (!f || S !== st) return;
      try {
        const raw = JSON.parse(await f.text());
        if (!raw || raw.app !== 'hukuk-notes' || raw.summary !== S.id) throw new Error('Bu yedek bu özete ait değil.');
        const d = raw.doc && typeof raw.doc === 'object' ? raw.doc : {};
        // Eski yedeklerde temel yok; yedeğin alındığı sürüm (version) ölçülür.
        const doc = await prepare({ ...d, sv: d.sv || raw.version || 1 });
        if (S !== st) return;
        if (!window.confirm(`Yedekteki ${doc.strokes.length} not yüklensin mi? Mevcut notların yerini alır (geri alınabilir).`)) return;
        endSelection();
        const op = { before: S.doc.strokes.slice(), after: doc.strokes };
        runOp(op, false); commitOp(op);
        S.doc.extra = Math.max(S.doc.extra, doc.extra);
        updatePageHeight();
        toast(doc.moved ? `Yedek yüklendi — ${doc.moved} not özetin güncel düzenine taşındı` : 'Yedek yüklendi', 3200);
      } catch (err) { toast(err.message && err.message.length < 120 ? err.message : 'Yedek dosyası okunamadı', 3600); }
    };
    inp.click();
  }

  // ───────── Bildirimler ─────────
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  let toastTimer = 0;
  function toast(msg, ms) {
    ui.toast.textContent = msg;
    ui.toast.classList.add('hn-show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => ui.toast.classList.remove('hn-show'), ms || 1800);
  }
  function flash(el, msg) {
    el.textContent = msg;
    el.classList.add('hn-show');
    clearTimeout(el._t);
    el._t = setTimeout(() => el.classList.remove('hn-show'), 1100);
  }
  function notice(msg, buttons, kind) {
    ui.noticeText.textContent = msg;
    ui.noticeBtns.innerHTML = buttons.map(([label, act]) => `<button class="hn-btn" data-n="${act}">${esc(label)}</button>`).join('');
    ui.notice.dataset.kind = kind || '';
    ui.notice.classList.add('hn-show');
  }
  function onNoticeClick(e) {
    const b = e.target.closest('button[data-n]');
    if (!b || !S || !S.content) return;
    const n = b.dataset.n;
    if (n === 'backup') exportNotes();
    else if (n === 'retry') { S.dirty = true; flushSave(); }
    else { prefs.set('notice.snooze', Date.now()); ui.notice.classList.remove('hn-show'); }
  }

  // ═════════════════════════ Köprü ═════════════════════════
  window.hukukNotesOpen = id => open(String(id)).then(r => r || 'closed');
  window.hukukNotesClose = close;
  /** Özet listesi için: kaydedilmiş not sayısı ve son düzenleme (JSON). */
  window.hukukNotesInfo = async id => {
    const got = await Promise.race([store.get(String(id)), wait(4000).then(() => null)]);
    const list = d => (d && Array.isArray(d.strokes) ? d.strokes : []);
    const count = d => list(d).length;
    const time = (d, k) => (d && Number(d[k]) > 0 ? Number(d[k]) : 0);
    let strokes = 0, updated = 0, edited = 0;
    if (got) {
      const { idb, local } = got;
      updated = Math.max(time(idb, 'updated'), time(local, 'updated'));
      edited = Math.max(time(idb, 'edited') || time(idb, 'updated'), time(local, 'edited') || time(local, 'updated'));
      if (local && idb && got.ok && local.partial) {
        const ids = new Set(list(idb).map(s => s && s.id));
        strokes = count(idb) + list(local).filter(s => s && !ids.has(s.id)).length;
      } else if (local && idb && got.ok) strokes = time(local, 'updated') > time(idb, 'updated') ? count(local) : count(idb);
      else strokes = got.ok ? count(idb) || count(local) : count(local);
    }
    return JSON.stringify({ strokes, updated, edited });
  };
})();
