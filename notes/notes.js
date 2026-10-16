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
 *    yakınlaştırır. İki parmakla dokunma geri alır, üç parmak yineler.
 *  - Çizilen çizgi ekran koordinatlı bir canvas'ta anlık çizilir; bırakınca
 *    aynı dış hat SVG yoluna dönüşür (görünüm sıçramaz).
 *  - Avuç içi: kalem yazarken ve büyük temas alanlı dokunuşlarda kaydırma yok.
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

  function smoothInto(out, xy) {
    // xy: [x0,y0,x1,y1,...]; mevcut konum xy[0]'dadır.
    const m = xy.length / 2;
    for (let k = 1; k < m - 1; k++) {
      const x = xy[2 * k], y = xy[2 * k + 1];
      const mx = (x + xy[2 * k + 2]) / 2, my = (y + xy[2 * k + 3]) / 2;
      out.push(`Q${rd(x)} ${rd(y)} ${rd(mx)} ${rd(my)}`);
    }
    if (m > 1) out.push(`L${rd(xy[2 * m - 2])} ${rd(xy[2 * m - 1])}`);
  }

  /**
   * Değişken kalınlıklı çizginin dış hattı (SVG path). Aynı dize hem canvas'ta
   * (Path2D) hem SVG'de kullanılır. extra: yalnız anlık çizimde tahmin noktaları.
   */
  function outline(tool, w, pts, extra) {
    const all = extra && extra.length ? pts.concat(extra) : pts;
    const n = all.length / 3;
    if (!n) return '';
    const xs = new Array(n), ys = new Array(n), rs = new Array(n);
    let minx = Infinity, maxx = -Infinity, miny = Infinity, maxy = -Infinity, maxr = 0;
    for (let i = 0; i < n; i++) {
      xs[i] = all[3 * i]; ys[i] = all[3 * i + 1];
      rs[i] = radius(tool, w, all[3 * i + 2]);
      if (xs[i] < minx) minx = xs[i]; if (xs[i] > maxx) maxx = xs[i];
      if (ys[i] < miny) miny = ys[i]; if (ys[i] > maxy) maxy = ys[i];
      if (rs[i] > maxr) maxr = rs[i];
    }
    if (n === 1 || Math.max(maxx - minx, maxy - miny) < maxr * 0.25) {
      const x = (minx + maxx) / 2, y = (miny + maxy) / 2, r = Math.max(maxr, 0.4);
      return `M${rd(x - r)} ${rd(y)}A${rd(r)} ${rd(r)} 0 1 0 ${rd(x + r)} ${rd(y)}A${rd(r)} ${rd(r)} 0 1 0 ${rd(x - r)} ${rd(y)}Z`;
    }
    const L = new Array(2 * n), R = new Array(2 * n);
    let ptx = 1, pty = 0;
    for (let i = 0; i < n; i++) {
      const a = i > 0 ? i - 1 : 0, b = i < n - 1 ? i + 1 : n - 1;
      let tx = xs[b] - xs[a], ty = ys[b] - ys[a];
      const len = Math.hypot(tx, ty);
      if (len < 1e-6) { tx = ptx; ty = pty; } else { tx /= len; ty /= len; }
      ptx = tx; pty = ty;
      const r = rs[i];
      L[2 * i] = xs[i] - ty * r; L[2 * i + 1] = ys[i] + tx * r;
      R[2 * i] = xs[i] + ty * r; R[2 * i + 1] = ys[i] - tx * r;
    }
    const d = [`M${rd(L[0])} ${rd(L[1])}`];
    smoothInto(d, L);
    const re = rd(rs[n - 1]), rs0 = rd(rs[0]);
    d.push(`A${re} ${re} 0 0 0 ${rd(R[2 * n - 2])} ${rd(R[2 * n - 1])}`);
    const back = new Array(2 * n);
    for (let i = 0; i < n; i++) { back[2 * i] = R[2 * (n - 1 - i)]; back[2 * i + 1] = R[2 * (n - 1 - i) + 1]; }
    smoothInto(d, back);
    d.push(`A${rs0} ${rs0} 0 0 0 ${rd(L[0])} ${rd(L[1])}Z`);
    return d.join('');
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
    const ids = [];
    for (const s of strokes) {
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

  /** Geri al/yinele: {before: silinen çizgiler, after: eklenen çizgiler}. */
  function applyOp(strokes, op, reverse) {
    const remove = reverse ? op.after : op.before;
    const add = reverse ? op.before : op.after;
    const gone = new Set(remove.map(s => s.id));
    const next = strokes.filter(s => !gone.has(s.id));
    for (const s of add) next.push(s);
    return next;
  }

  /** Yedek/IndexedDB'den gelen belgeyi doğrular; bozuk çizgileri atar. */
  function sanitizeDoc(raw) {
    const doc = { v: 1, strokes: [], extra: 0 };
    if (!raw || typeof raw !== 'object') return doc;
    doc.extra = clamp(Number(raw.extra) || 0, 0, 20000);
    const list = Array.isArray(raw.strokes) ? raw.strokes : [];
    for (const s of list) {
      if (!s || (s.t !== 'pen' && s.t !== 'hl')) continue;
      if (typeof s.c !== 'string' || !/^#[0-9a-fA-F]{6}$/.test(s.c)) continue;
      const w = Number(s.w);
      if (!(w > 0 && w < 80) || !Array.isArray(s.p) || !s.p.length || s.p.length % 3) continue;
      if (!s.p.every(Number.isFinite)) continue;
      doc.strokes.push({ id: String(s.id || ''), t: s.t, c: s.c, w, p: s.p.map(rd) });
    }
    let n = 0;
    const seen = new Set();
    for (const s of doc.strokes) { if (!s.id || seen.has(s.id)) s.id = 'r' + (n++) + '_' + Math.random().toString(36).slice(2, 8); seen.add(s.id); }
    return doc;
  }

  const G = {
    PAGE_W, MARGIN, radius, builder, outline, bounds, hits, eraseSplit, pointInPoly,
    lassoSelect, translated, lineBetween, nearlyStraight, applyOp, sanitizeDoc,
  };
  window.hukukInkGeom = G;

  // ═════════════════════════ Özet kayıt defteri ═════════════════════════
  const summaries = {};
  const waiting = {};
  window.hukukNotesRegister = s => {
    if (!s || !s.id) return;
    summaries[s.id] = s;
    (waiting[s.id] || []).forEach(fn => fn(s));
    delete waiting[s.id];
  };
  function loadSummary(id) {
    if (summaries[id]) return Promise.resolve(summaries[id]);
    if (!/^[a-z0-9-]+$/.test(id)) return Promise.reject(new Error('Özet bulunamadı.'));
    return new Promise((resolve, reject) => {
      (waiting[id] = waiting[id] || []).push(resolve);
      const tag = document.createElement('script');
      tag.src = 'notes/summaries/' + id + '.js';
      tag.onerror = () => reject(new Error('Özet yüklenemedi. Bağlantını kontrol edip tekrar dene.'));
      document.head.appendChild(tag);
    });
  }

  // ═════════════════════════ Depolama ═════════════════════════
  const store = (() => {
    let dbp = null;
    function db() {
      if (dbp) return dbp;
      dbp = new Promise((resolve, reject) => {
        if (!('indexedDB' in window)) { reject(new Error('no idb')); return; }
        const req = indexedDB.open('hukuk-notes', 1);
        req.onupgradeneeded = () => req.result.createObjectStore('docs');
        req.onsuccess = () => resolve(req.result);
        req.onerror = () => reject(req.error);
      });
      dbp.catch(() => { dbp = null; });
      return dbp;
    }
    async function get(id) {
      try {
        const d = await db();
        return await new Promise((resolve, reject) => {
          const r = d.transaction('docs').objectStore('docs').get(id);
          r.onsuccess = () => resolve(r.result || null);
          r.onerror = () => reject(r.error);
        });
      } catch (_) {
        try { return JSON.parse(localStorage.getItem('hukuk-notes:' + id) || 'null'); } catch (__) { return null; }
      }
    }
    async function put(id, doc) {
      try {
        const d = await db();
        await new Promise((resolve, reject) => {
          const tx = d.transaction('docs', 'readwrite');
          tx.objectStore('docs').put(doc, id);
          tx.oncomplete = resolve;
          tx.onerror = () => reject(tx.error);
          tx.onabort = () => reject(tx.error);
        });
      } catch (_) {
        localStorage.setItem('hukuk-notes:' + id, JSON.stringify(doc));
      }
    }
    return { get, put };
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
  const ICONS = {
    back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>',
    pen: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20l1.2-4.6L15.6 5a2.1 2.1 0 013 3L8.2 18.4z"/><path d="M13.8 6.8l3.4 3.4"/></svg>',
    hl: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M9 14l-3 3v3h3l3-3"/><path d="M9 14l7.5-9.5a2 2 0 012.8-.3l.5.4a2 2 0 01.3 2.8L12 17z"/><path d="M3 21h7" stroke-width="2.6"/></svg>',
    eraser: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 20H20"/><path d="M5.3 15.7l8.9-8.9a2 2 0 012.8 0l2.2 2.2a2 2 0 010 2.8l-7.5 7.5a2 2 0 01-1.4.6H8.6a2 2 0 01-1.4-.6l-1.9-1.9a1.2 1.2 0 010-1.7z"/><path d="M10 10.9l5.3 5.3"/></svg>',
    lasso: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="2.6 2.6"><path d="M12 4c4.7 0 8 2.4 8 5.5S16.7 15 12 15s-8-2.4-8-5.5S7.3 4 12 4z"/><path d="M7.5 14.2c-.9 1.2-1 2.6-.2 3.6.9 1.1 2.6 1.3 3.7 2.2" stroke-dasharray="none"/></svg>',
    undo: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 7L4.5 11.5 9 16"/><path d="M5 11.5h9.5a5 5 0 010 10H12"/></svg>',
    redo: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 7l4.5 4.5L15 16"/><path d="M19 11.5H9.5a5 5 0 000 10H12"/></svg>',
    more: '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5.5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="18.5" cy="12" r="1.8"/></svg>',
    toc: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.5" cy="6" r="1" fill="currentColor"/><circle cx="4.5" cy="12" r="1" fill="currentColor"/><circle cx="4.5" cy="18" r="1" fill="currentColor"/></svg>',
  };

  // ═════════════════════════ Uygulama ═════════════════════════
  let ui = null; // DOM (ilk açılışta kurulur)
  let S = null;  // açık özetin durumu
  let closeResolve = null;

  const nowId = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  const qs = (el, sel) => el.querySelector(sel);

  function build() {
    const root = document.createElement('div');
    root.id = 'hn-root';
    root.innerHTML = `
      <div class="hn-bar">
        <button class="hn-btn hn-back" data-a="close" aria-label="Özetlere dön">${ICONS.back}<span>Özetler</span></button>
        <button class="hn-btn" data-a="toc" aria-label="İçindekiler">${ICONS.toc}</button>
        <div class="hn-title"></div>
        <div class="hn-sp"></div>
        <button class="hn-btn hn-tool" data-tool="pen" aria-label="Kalem">${ICONS.pen}</button>
        <button class="hn-btn hn-tool" data-tool="hl" aria-label="Fosforlu kalem">${ICONS.hl}</button>
        <button class="hn-btn hn-tool" data-tool="eraser" aria-label="Silgi">${ICONS.eraser}</button>
        <button class="hn-btn hn-tool" data-tool="lasso" aria-label="Kement ile seç">${ICONS.lasso}</button>
        <div class="hn-sep"></div>
        <div class="hn-opts" style="display:flex;align-items:center;gap:2px"></div>
        <div class="hn-sep"></div>
        <button class="hn-btn" data-a="undo" aria-label="Geri al">${ICONS.undo}</button>
        <button class="hn-btn" data-a="redo" aria-label="Yinele">${ICONS.redo}</button>
        <button class="hn-btn" data-a="more" aria-label="Diğer">${ICONS.more}</button>
      </div>
      <div class="hn-scroller"><div class="hn-sizer"><div class="hn-page"></div></div></div>
      <svg class="hn-live" aria-hidden="true"><g>
        <path class="hn-lstroke"/><path class="hn-llasso" fill="rgba(214,51,108,0.06)" stroke="#d6336c"/>
        <circle class="hn-lcur" r="0" stroke="rgba(40,20,60,0.55)"/>
      </g></svg>
      <div class="hn-chip hn-zoom" role="button" aria-label="Sayfayı ekrana sığdır">100%</div>
      <div class="hn-chip hn-save">Kaydedildi</div>
      <div class="hn-chip hn-toast"></div>
      <div class="hn-chip hn-selbar">
        <span class="hn-selcount"></span>
        <button class="hn-btn" data-a="seldup">Çoğalt</button>
        <button class="hn-btn" data-a="seldel">Sil</button>
        <button class="hn-btn" data-a="seloff">Bitti</button>
      </div>
      <div class="hn-pop hn-toc"></div>
      <div class="hn-pop hn-menu" style="right:10px"></div>
      <div class="hn-pop hn-eopts" style="right:150px"></div>
    `;
    document.body.appendChild(root);
    const u = {
      root,
      bar: qs(root, '.hn-bar'),
      title: qs(root, '.hn-title'),
      opts: qs(root, '.hn-opts'),
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
    u.zoom.addEventListener('click', () => fitWidth(true));
    u.menu.addEventListener('click', onMenuClick);
    u.eopts.addEventListener('click', onMenuClick);
    u.toc.addEventListener('click', onTocClick);
    attachInput(u);
    window.addEventListener('resize', () => { if (S) layout(); });
    document.addEventListener('visibilitychange', () => { if (document.hidden && S) flushSave(); });
    window.addEventListener('pagehide', () => { if (S) flushSave(); });
    document.addEventListener('keydown', onKey, true);
    return u;
  }

  // ───────── Açma / kapama ─────────
  async function open(id) {
    if (!ui) ui = build();
    if (S && S.id === id && ui.root.classList.contains('hn-open')) return new Promise(r => { closeResolve = r; });
    ui.root.classList.add('hn-open');
    ui.page.innerHTML = '';
    ui.page.style.height = '800px';
    ui.title.textContent = '';
    const loading = document.createElement('div');
    loading.className = 'hn-loading';
    loading.textContent = 'Özet hazırlanıyor…';
    ui.scroller.appendChild(loading);
    hidePops();
    let summary;
    try {
      summary = await loadSummary(id);
      const fonts = document.fonts;
      if (fonts && fonts.load) await Promise.race([fonts.load("400 16px HNInter"), new Promise(r => setTimeout(r, 2500))]);
    } catch (e) {
      loading.textContent = e.message || 'Özet açılamadı.';
      return new Promise(r => { closeResolve = r; });
    }
    // Depolama takılırsa (ör. bekleyen bir izin isteği) özet yine açılır; notlar
    // gelince birleştirilir. O zamana kadar hiçbir şey diske yazılmaz.
    const TIMEOUT = {};
    const raw = await Promise.race([store.get(id), new Promise(r => setTimeout(() => r(TIMEOUT), 3500))]);
    loading.remove();
    S = {
      id, summary,
      doc: G.sanitizeDoc(raw === TIMEOUT ? null : raw),
      loadPending: raw === TIMEOUT,
      els: new Map(),
      undo: [], redo: [],
      tool: prefs.get('tool', 'pen'),
      color: { pen: prefs.get('c.pen', TOOLS.pen.colors[0]), hl: prefs.get('c.hl', TOOLS.hl.colors[0]) },
      size: { pen: prefs.get('s.pen', 1), hl: prefs.get('s.hl', 1), eraser: prefs.get('s.eraser', 1) },
      eraseMode: prefs.get('eraseMode', 'stroke'),
      hidden: false,
      z: 1, contentH: 0,
      sel: null,
      dirty: false, saveTimer: 0,
    };
    if (!TOOLS[S.tool]) S.tool = 'pen';
    if (S.loadPending) lateLoad(S);
    ui.title.textContent = summary.title;
    renderPage();
    const view = prefs.get('view.' + id, null);
    if (view && view.v === summary.version) {
      setZoom(view.z, 0, 0, true);
      ui.scroller.scrollLeft = view.x * S.z;
      ui.scroller.scrollTop = view.y * S.z;
    } else fitWidth(false);
    refreshToolbar();
    if (!prefs.get('hinted', false)) {
      toast('Apple Pencil ile yaz · parmakla kaydır · iki parmakla dokun: geri al', 4200);
      prefs.set('hinted', true);
    }
    return new Promise(r => { closeResolve = r; });
  }

  async function lateLoad(st) {
    const raw = await store.get(st.id);
    if (S !== st) return;
    const old = G.sanitizeDoc(raw);
    const have = new Set(st.doc.strokes.map(s => s.id));
    const add = old.strokes.filter(s => !have.has(s.id));
    st.doc.strokes = add.concat(st.doc.strokes);
    st.doc.extra = Math.max(st.doc.extra, old.extra);
    for (const s of add) addEl(s);
    st.loadPending = false;
    updatePageHeight();
    if (st.dirty) flushSave();
  }

  function close() {
    if (!ui) return;
    if (S) {
      endSelection();
      rememberView();
      flushSave();
    }
    ui.root.classList.remove('hn-open');
    hidePops();
    const r = closeResolve;
    closeResolve = null;
    if (r) r('closed');
  }

  function rememberView() {
    if (!S) return;
    prefs.set('view.' + S.id, {
      v: S.summary.version, z: S.z,
      x: ui.scroller.scrollLeft / S.z, y: ui.scroller.scrollTop / S.z,
    });
  }

  // ───────── Sayfa ─────────
  function renderPage() {
    const page = ui.page;
    page.innerHTML = '';
    const ml = document.createElement('div'); ml.className = 'hn-margin l';
    const mr = document.createElement('div'); mr.className = 'hn-margin r';
    const content = document.createElement('div');
    content.className = 'hn-content';
    content.innerHTML = S.summary.html;
    const extra = document.createElement('div'); extra.className = 'hn-extra';
    page.append(ml, mr, content, extra);
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('class', 'hn-ink');
    const ghl = document.createElementNS(svg.namespaceURI, 'g'); ghl.setAttribute('class', 'hn-hl');
    const gpen = document.createElementNS(svg.namespaceURI, 'g'); gpen.setAttribute('class', 'hn-pen');
    svg.append(ghl, gpen);
    page.appendChild(svg);
    const sel = document.createElement('div'); sel.className = 'hn-sel'; sel.style.display = 'none';
    page.appendChild(sel);
    S.content = content; S.extraEl = extra; S.svg = svg; S.ghl = ghl; S.gpen = gpen; S.selEl = sel;
    S.contentH = Math.ceil(content.offsetHeight);
    for (const s of S.doc.strokes) addEl(s);
    S.sections = [...content.querySelectorAll('h2.sec, .part')].map(h => ({
      part: h.classList.contains('part'),
      no: h.querySelector('.no') ? h.querySelector('.no').textContent : '',
      text: h.classList.contains('part') ? h.querySelector('div').textContent : (h.querySelector('.tt') || h).textContent.trim(),
      el: h,
    }));
    updatePageHeight();
  }

  function pageHeight() {
    let maxY = 0;
    for (const s of S.doc.strokes) { const b = s.b || (s.b = G.bounds(s)); if (b[3] > maxY) maxY = b[3]; }
    return Math.max(S.contentH + 400 + S.doc.extra, Math.ceil(maxY + 300));
  }

  function updatePageHeight() {
    const h = pageHeight();
    S.pageH = h;
    ui.page.style.height = h + 'px';
    S.svg.setAttribute('width', PAGE_W);
    S.svg.setAttribute('height', h);
    S.svg.setAttribute('viewBox', `0 0 ${PAGE_W} ${h}`);
    S.extraEl.style.top = S.contentH + 'px';
    S.extraEl.style.height = (h - S.contentH) + 'px';
    layout();
  }

  // ───────── Yakınlaştırma / yerleşim ─────────
  function viewSize() { return { w: ui.scroller.clientWidth, h: ui.scroller.clientHeight }; }
  function fitZoom() { return clamp((viewSize().w - 24) / PAGE_W, 0.3, 4); }
  function offX() { return Math.max(12, (viewSize().w - PAGE_W * S.z) / 2); }
  const OFF_Y = 14;

  function layout() {
    if (!S) return;
    const z = S.z, ox = offX();
    ui.page.style.transform = `translate(${ox}px, ${OFF_Y}px) scale(${z})`;
    ui.sizer.style.width = Math.max(viewSize().w, PAGE_W * z + ox * 2) + 'px';
    ui.sizer.style.height = (S.pageH * z + OFF_Y * 2 + 40) + 'px';
    ui.zoom.textContent = Math.round(z / fitZoom() * 100) + '%';
  }

  /** fx/fy: kaydırma alanına göre odak noktası; o noktadaki sayfa yeri sabit kalır. */
  function setZoom(z, fx, fy, silent) {
    const sc = ui.scroller;
    const oldZ = S.z, oldOx = offX();
    const px = (sc.scrollLeft + fx - oldOx) / oldZ;
    const py = (sc.scrollTop + fy - OFF_Y) / oldZ;
    S.z = clamp(z, 0.3, 5);
    layout();
    const ox = offX();
    sc.scrollLeft = px * S.z + ox - fx;
    sc.scrollTop = py * S.z + OFF_Y - fy;
    if (!silent) scheduleViewSave();
  }

  function fitWidth(animate) {
    const z = fitZoom();
    const sc = ui.scroller;
    const py = S ? (sc.scrollTop - OFF_Y) / S.z : 0;
    S.z = z;
    layout();
    sc.scrollLeft = 0;
    sc.scrollTop = animate ? Math.max(0, py * z + OFF_Y) : 0;
    scheduleViewSave();
  }

  let viewTimer = 0;
  function scheduleViewSave() { clearTimeout(viewTimer); viewTimer = setTimeout(rememberView, 600); }


  // ───────── Çizim öğeleri ─────────
  function addEl(s) {
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', G.outline(s.t, s.w, s.p));
    path.setAttribute('fill', s.c);
    if (s.t === 'hl') path.setAttribute('fill-opacity', '0.42');
    (s.t === 'hl' ? S.ghl : S.gpen).appendChild(path);
    S.els.set(s.id, path);
    s.b = G.bounds(s);
  }
  function removeEl(id) {
    const el = S.els.get(id);
    if (el) { el.remove(); S.els.delete(id); }
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
    if (!op) return;
    runOp(op, false);
    S.undo.push(op);
    refreshUndo();
  }
  function changed() {
    S.dirty = true;
    refreshUndo();
    const h = pageHeight();
    if (h !== S.pageH) updatePageHeight();
    clearTimeout(S.saveTimer);
    S.saveTimer = setTimeout(flushSave, 500);
  }
  let persistAsked = false;
  async function flushSave() {
    if (!S || !S.dirty || S.loadPending) return;
    clearTimeout(S.saveTimer);
    S.dirty = false;
    const id = S.id;
    const doc = { v: 1, extra: S.doc.extra, updated: Date.now(),
      strokes: S.doc.strokes.map(s => ({ id: s.id, t: s.t, c: s.c, w: s.w, p: s.p })) };
    try {
      await store.put(id, doc);
      if (S && S.id === id) flash(ui.save, 'Kaydedildi');
      // Kalıcı depolama iznini ilk kayıttan sonra iste (Safari'nin temizlemesine karşı).
      if (!persistAsked) {
        persistAsked = true;
        try { navigator.storage && navigator.storage.persist && navigator.storage.persist(); } catch (_) {}
      }
    } catch (_) {
      if (S && S.id === id) { S.dirty = true; toast('Notlar kaydedilemedi — depolama dolu olabilir', 3500); }
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
    erase: null, move: null, touches: new Map(), pinch: null, tap: null,
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
    sc.addEventListener('scroll', () => { if (S) { requestLive(); scheduleViewSave(); } }, { passive: true });
  }

  function onPointerDown(e) {
    if (!S || !isPen(e)) return;
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    if (input.penDown) return;
    hidePops();
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
      const minDist = 0.6 / S.z;
      const b = G.builder(minDist);
      b.add(x, y, p, 0);
      input.stroke = {
        t: tool, c: S.color[tool], w: TOOLS[tool].sizes[S.size[tool]] / (tool === 'hl' ? 1 : 1),
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
      if (S.sel && inSel(x, y)) {
        input.move = { x0: x, y0: y, dx: 0, dy: 0 };
      } else {
        endSelection();
        input.lasso = [x, y];
      }
      requestLive();
    }
  }

  function onPointerMove(e) {
    if (!S || !isPen(e)) return;
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
    const tool = S.tool;
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
      const tr = `translate(${rd(input.move.dx)} ${rd(input.move.dy)})`;
      for (const id of S.sel.ids) { const el = S.els.get(id); if (el) el.setAttribute('transform', tr); }
      placeSelBox(input.move.dx, input.move.dy);
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
      const pts = st.snapped ? st.snapPts : st.b.pts;
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
        const set = new Set(S.sel.ids);
        const before = S.doc.strokes.filter(s => set.has(s.id));
        const after = before.map(s => G.translated(s, mv.dx, mv.dy));
        const op = { before, after };
        runOp(op, false);
        commitOp(op);
        startSelection(after.map(s => s.id));
      } else placeSelBox(0, 0);
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

  function eraserR() { return TOOLS.eraser.sizes[S.size.eraser] / 2 + 0.5; }
  function eraseAt(x, y) {
    const er = eraserR();
    const E = input.erase;
    if (S.eraseMode === 'stroke') {
      const gone = S.doc.strokes.filter(s => G.hits(s, x, y, er));
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
        const runs = G.eraseSplit(s, x, y, er);
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
    placeSelBox(0, 0);
    ui.selcount.textContent = ids.length + ' çizgi seçildi';
    ui.selbar.classList.add('hn-show');
  }
  function placeSelBox(dx, dy) {
    const el = S.selEl, b = S.sel.b, pad = 8;
    el.style.display = 'block';
    el.style.left = (b[0] - pad + dx) + 'px';
    el.style.top = (b[1] - pad + dy) + 'px';
    el.style.width = (b[2] - b[0] + 2 * pad) + 'px';
    el.style.height = (b[3] - b[1] + 2 * pad) + 'px';
  }
  function inSel(x, y) {
    const b = S.sel.b, pad = 14;
    return x >= b[0] - pad && x <= b[2] + pad && y >= b[1] - pad && y <= b[3] + pad;
  }
  function endSelection() {
    if (!S || !S.sel) return;
    S.sel = null;
    S.selEl.style.display = 'none';
    ui.selbar.classList.remove('hn-show');
  }
  function selectionAction(a) {
    if (!S.sel) return;
    const set = new Set(S.sel.ids);
    const chosen = S.doc.strokes.filter(s => set.has(s.id));
    if (a === 'seldel') {
      const op = { before: chosen, after: [] };
      runOp(op, false); commitOp(op); endSelection();
    } else if (a === 'seldup') {
      const copies = chosen.map(s => ({ ...G.translated(s, 24, 24), id: nowId() }));
      const op = { before: [], after: copies };
      runOp(op, false); commitOp(op); startSelection(copies.map(s => s.id));
    } else if (a === 'seloff') endSelection();
  }
  function recolorSelection(color) {
    const set = new Set(S.sel.ids);
    const before = S.doc.strokes.filter(s => set.has(s.id));
    const after = before.map(s => ({ ...s, c: color, b: undefined }));
    const op = { before, after };
    runOp(op, false); commitOp(op);
    startSelection(after.map(s => s.id));
  }

  // ───────── Dokunma: kaydırma, yakınlaştırma, hareketler ─────────
  function onTouchStart(e) {
    if (!S) return;
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
      const [a, b] = direct;
      const rect = ui.scroller.getBoundingClientRect();
      input.pinch = {
        d0: Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY) || 1,
        z0: S.z,
        cx: (a.clientX + b.clientX) / 2 - rect.left, cy: (a.clientY + b.clientY) / 2 - rect.top,
        rect,
      };
      ui.page.style.willChange = 'transform';
      if (!input.tap || now - input.tap.t0 > 260) input.tap = { t0: now, n: direct.length, moved: false, z: S.z };
      else input.tap.n = Math.max(input.tap.n, direct.length);
    } else if (direct.length === 1) {
      input.tap = { t0: now, n: 1, moved: false, z: S.z };
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
      const quick = performance.now() - tp.t0 < 300;
      const sameZoom = Math.abs(S.z - tp.z) / tp.z < 0.04;
      if (quick && !tp.moved && sameZoom) {
        if (tp.n === 2) undo();
        else if (tp.n >= 3) redo();
      }
    }
  }
  function onWheel(e) {
    if (!S || !(e.ctrlKey || e.metaKey)) return; // normal tekerlek kaydırır
    e.preventDefault();
    const rect = ui.scroller.getBoundingClientRect();
    setZoom(S.z * Math.exp(-e.deltaY * 0.01), e.clientX - rect.left, e.clientY - rect.top);
  }
  function onKey(e) {
    if (!S || !ui.root.classList.contains('hn-open')) return;
    const mod = e.metaKey || e.ctrlKey;
    if (mod && (e.key === 'z' || e.key === 'Z')) { e.preventDefault(); e.stopPropagation(); e.shiftKey ? redo() : undo(); }
    else if (mod && (e.key === 'y')) { e.preventDefault(); e.stopPropagation(); redo(); }
    else if (e.key === 'Escape') { e.stopPropagation(); if (S.sel) endSelection(); else if (anyPop()) hidePops(); else close(); }
    else if (!mod && /^[1-4]$/.test(e.key)) { e.stopPropagation(); setTool(['pen', 'hl', 'eraser', 'lasso'][+e.key - 1]); }
    else if ((e.key === 'Backspace' || e.key === 'Delete') && S.sel) { e.preventDefault(); e.stopPropagation(); selectionAction('seldel'); }
    else e.stopPropagation();
  }

  // ───────── Araç çubuğu ─────────
  function setTool(t) {
    if (!TOOLS[t]) return;
    if (t === S.tool && t === 'eraser') { toggleEraserMenu(); return; }
    if (t !== 'lasso') endSelection();
    S.tool = t;
    prefs.set('tool', t);
    hidePops();
    refreshToolbar();
  }
  function refreshToolbar() {
    for (const b of ui.bar.querySelectorAll('.hn-tool')) b.classList.toggle('hn-on', b.dataset.tool === S.tool);
    const t = S.tool, cfg = TOOLS[t];
    let h = '';
    const colorTool = t === 'lasso' ? null : t;
    if (colorTool === 'pen' || colorTool === 'hl') {
      cfg.colors.forEach((c, i) => {
        h += `<button class="hn-btn hn-sw${i >= 5 ? ' hn-x' : ''}${S.color[t] === c ? ' hn-on' : ''}" data-color="${c}" aria-label="Renk"><i style="background:${c}"></i></button>`;
      });
    }
    if (t === 'lasso') {
      h += '<span style="font:600 13px HNInter,sans-serif;color:#6b6478;padding:0 6px">Seçimi renklendir:</span>';
      TOOLS.pen.colors.slice(0, 5).forEach(c => { h += `<button class="hn-btn hn-sw" data-color="${c}" aria-label="Seçimin rengi"><i style="background:${c}"></i></button>`; });
    }
    if (cfg.sizes) {
      h += '<span style="width:6px"></span>';
      cfg.sizes.forEach((s, i) => {
        const dot = t === 'eraser' ? [8, 13, 19][i] : t === 'hl' ? [7, 11, 15][i] : [4, 7, 10][i];
        h += `<button class="hn-btn hn-size${i === 1 ? ' hn-m2' : ''}${S.size[t] === i ? ' hn-on' : ''}" data-size="${i}" aria-label="Kalınlık ${i + 1}"><i style="width:${dot}px;height:${dot}px"></i></button>`;
      });
    }
    if (t === 'eraser') {
      h += `<button class="hn-btn" data-a="emode" style="font-size:13px">${S.eraseMode === 'stroke' ? 'Çizgi' : 'Hassas'} ▾</button>`;
    }
    ui.opts.innerHTML = h;
    refreshUndo();
  }
  function refreshUndo() {
    ui.undo.disabled = !S.undo.length;
    ui.redo.disabled = !S.redo.length;
  }
  function onBarClick(e) {
    const b = e.target.closest('button');
    if (!b || !S) return;
    if (b.dataset.tool) return setTool(b.dataset.tool);
    if (b.dataset.color) {
      if (S.tool === 'lasso') { if (S.sel) recolorSelection(b.dataset.color); else toast('Önce kementle not seç'); return; }
      S.color[S.tool] = b.dataset.color;
      prefs.set('c.' + S.tool, b.dataset.color);
      return refreshToolbar();
    }
    if (b.dataset.size) {
      S.size[S.tool] = +b.dataset.size;
      prefs.set('s.' + S.tool, +b.dataset.size);
      return refreshToolbar();
    }
    const a = b.dataset.a;
    if (a === 'close') return close();
    if (a === 'undo') return undo();
    if (a === 'redo') return redo();
    if (a === 'more') return toggleMenu();
    if (a === 'toc') return toggleToc();
    if (a === 'emode') return toggleEraserMenu();
    if (a && a.startsWith('sel')) return selectionAction(a);
  }

  function anyPop() { return ui.root.querySelector('.hn-pop.hn-show'); }
  function hidePops() { if (ui) for (const p of ui.root.querySelectorAll('.hn-pop')) p.classList.remove('hn-show'); }
  function toggleMenu() {
    const m = ui.menu, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    m.innerHTML = `
      <button data-m="fit">Sayfayı ekrana sığdır</button>
      <button data-m="hide">${S.hidden ? 'Notları göster' : 'Notları gizle'}</button>
      <button data-m="extend">Sayfa sonuna not alanı ekle</button>
      <hr>
      <button data-m="print">Yazdır / PDF olarak kaydet</button>
      <button data-m="export">Notları yedekle (dosya)</button>
      <button data-m="import">Yedekten geri yükle…</button>
      <hr>
      <button data-m="clear" class="hn-danger">Bu özetteki tüm notları sil</button>
      <div class="hn-h">İpuçları</div>
      <div style="font:400 13px/1.5 HNInter,sans-serif;color:#6b6478;padding:0 12px 10px">
        Kalemle yaz, parmakla kaydır. İki parmakla dokun: geri al · üç parmak: yinele.
        Çizgiyi bitirirken kalemi bekletirsen düz çizgiye dönüşür.
      </div>`;
    m.classList.add('hn-show');
  }
  function toggleEraserMenu() {
    const m = ui.eopts, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    m.innerHTML = `
      <div class="hn-h">Silgi</div>
      <button data-m="estroke" class="${S.eraseMode === 'stroke' ? 'hn-on' : ''}">Çizgi silgisi — dokunduğu çizgiyi tamamen siler</button>
      <button data-m="eprecise" class="${S.eraseMode === 'precise' ? 'hn-on' : ''}">Hassas silgi — yalnız üstünden geçtiği kısmı siler</button>`;
    m.classList.add('hn-show');
  }
  function toggleToc() {
    const m = ui.toc, was = m.classList.contains('hn-show');
    hidePops();
    if (was) return;
    let h = '<div class="hn-h">İçindekiler</div>';
    S.sections.forEach((s, i) => {
      h += s.part ? `<div class="hn-part">${esc(s.text)}</div>` : `<button data-sec="${i}"><b>${esc(s.no)}</b>${esc(s.text)}</button>`;
    });
    m.innerHTML = h;
    m.classList.add('hn-show');
  }
  function onTocClick(e) {
    const b = e.target.closest('button[data-sec]');
    if (!b) return;
    const s = S.sections[+b.dataset.sec];
    hidePops();
    const y = s.el.offsetTop + s.el.offsetParent.offsetTop;
    ui.scroller.scrollTo({ top: Math.max(0, (y - 20) * S.z + OFF_Y), behavior: 'smooth' });
  }
  function onMenuClick(e) {
    const b = e.target.closest('button[data-m]');
    if (!b) return;
    const m = b.dataset.m;
    hidePops();
    if (m === 'fit') fitWidth(true);
    else if (m === 'hide') { S.hidden = !S.hidden; S.svg.classList.toggle('hn-hidden', S.hidden); endSelection(); toast(S.hidden ? 'Notlar gizlendi' : 'Notlar gösteriliyor'); }
    else if (m === 'extend') { S.doc.extra += 900; changed(); updatePageHeight(); toast('Sayfa sonuna boş alan eklendi'); }
    else if (m === 'print') { flushSave(); setTimeout(() => window.print(), 50); }
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
    }
  }

  async function exportNotes() {
    await flushSave();
    const data = JSON.stringify({ app: 'hukuk-notes', v: 1, summary: S.id, version: S.summary.version,
      exported: new Date().toISOString(), doc: { extra: S.doc.extra, strokes: S.doc.strokes.map(s => ({ id: s.id, t: s.t, c: s.c, w: s.w, p: s.p })) } });
    const name = `notlar-${S.id}-${new Date().toISOString().slice(0, 10)}.json`;
    const file = new File([data], name, { type: 'application/json' });
    try {
      if (navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], title: 'Özet notları' }); return; }
    } catch (err) { if (err && err.name === 'AbortError') return; }
    const a = document.createElement('a');
    a.href = URL.createObjectURL(file);
    a.download = name;
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 4000);
  }
  function importNotes() {
    const inp = document.createElement('input');
    inp.type = 'file';
    inp.accept = 'application/json,.json';
    inp.onchange = async () => {
      const f = inp.files && inp.files[0];
      if (!f) return;
      try {
        const raw = JSON.parse(await f.text());
        if (!raw || raw.app !== 'hukuk-notes' || raw.summary !== S.id) throw new Error('Bu yedek bu özete ait değil.');
        const doc = G.sanitizeDoc(raw.doc);
        if (!window.confirm(`Yedekteki ${doc.strokes.length} not yüklensin mi? Mevcut notların yerini alır (geri alınabilir).`)) return;
        endSelection();
        const op = { before: S.doc.strokes.slice(), after: doc.strokes };
        runOp(op, false); commitOp(op);
        S.doc.extra = Math.max(S.doc.extra, doc.extra);
        updatePageHeight();
        toast('Yedek yüklendi');
      } catch (err) { toast(err.message && err.message.length < 80 ? err.message : 'Yedek dosyası okunamadı', 3200); }
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

  // ═════════════════════════ Köprü ═════════════════════════
  window.hukukNotesOpen = id => open(String(id)).then(r => r || 'closed');
  window.hukukNotesClose = close;
  /** Özet listesi için: kaydedilmiş not sayısı ve son düzenleme (JSON). */
  window.hukukNotesInfo = async id => {
    const raw = await store.get(String(id));
    const n = raw && Array.isArray(raw.strokes) ? raw.strokes.length : 0;
    return JSON.stringify({ strokes: n, updated: (raw && raw.updated) || 0 });
  };
})();
