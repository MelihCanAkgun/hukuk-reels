// Not modunun saf geometrisi ve özet içeriği: node test/notes_ink_test.cjs
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');

const ctx = { window: {}, console };
ctx.window.window = ctx.window;
vm.runInNewContext(fs.readFileSync('web/notes/notes.js', 'utf8'), ctx.window);
const G = ctx.window.hukukInkGeom;
// vm bağlamındaki diziler başka bir realm'den gelir; karşılaştırmadan önce sadeleştir.
const plain = v => JSON.parse(JSON.stringify(v));
assert.ok(G, 'geometri dışa açılmalı');

// Yarıçap: basınç arttıkça kalınlaşır, fosforlu sabittir.
assert.ok(G.radius('pen', 2.4, 1) > G.radius('pen', 2.4, 0.2));
assert.equal(G.radius('hl', 18, 0.1), 9);

// Yumuşatıcı: çok yakın noktalar atılır, yerinde bastırma basıncı artırır.
const b = G.builder(0.6);
b.add(0, 0, 0.3, 0);
assert.equal(b.add(0.2, 0.1, 0.9, 0), false);
assert.equal(b.pts.length, 3);
assert.ok(b.pts[2] > 0.3);
b.add(10, 0, 0.5, 0);
b.add(20, 5, 0.5, 0);
assert.equal(b.pts.length, 9);

// Dış hat: kapalı yol; tek nokta daireye dönüşür; boş dizi boş yol.
const d = G.outline('pen', 2.4, [0, 0, 0.5, 10, 0, 0.5, 20, 5, 0.6]);
assert.match(d, /^M[-\d.]+ [-\d.]+.*A.*Z$/);
assert.ok(!/NaN|Infinity/.test(d));
assert.match(G.outline('pen', 2.4, [5, 5, 0.5]), /^M.*A.*A.*Z$/);
assert.equal(G.outline('pen', 2.4, []), '');
// Tahmin noktası yalnız anlık çizimde eklenir.
assert.notEqual(G.outline('pen', 2.4, [0, 0, 0.5, 10, 0, 0.5], [30, 0, 0.5]), G.outline('pen', 2.4, [0, 0, 0.5, 10, 0, 0.5]));

const line = { id: 'a', t: 'pen', c: '#000000', w: 2, p: G.lineBetween(0, 0, 100, 0, 0.5) };
assert.ok(line.p.length / 3 >= 30, 'düz çizgi sık noktalı olmalı');

// Silgi: değme testi, kenar payı ve hassas bölme.
assert.equal(G.hits(line, 50, 3, 3), true);
assert.equal(G.hits(line, 50, 20, 3), false);
const parts = G.eraseSplit(line, 50, 0, 6);
assert.equal(parts.length, 2);
assert.ok(parts[0].every((v, i) => i % 3 || v < 50));
assert.ok(parts[1].every((v, i) => i % 3 || v > 50));
assert.equal(G.eraseSplit(line, 50, 30, 6), null);
assert.deepEqual(plain(G.eraseSplit(line, 50, 0, 200)), []);

// Kement: noktalarının yarısı içinde kalan çizgi seçilir.
const box = [-5, -5, 60, -5, 60, 5, -5, 5];
const other = { id: 'b', t: 'pen', c: '#000000', w: 2, p: G.lineBetween(200, 0, 300, 0, 0.5) };
assert.deepEqual(plain(G.lassoSelect([line, other], box)), ['a']);
assert.deepEqual(plain(G.lassoSelect([line, other], [-5, -5, 20, -5, 20, 5, -5, 5])), []);
assert.deepEqual(plain(G.lassoSelect([line], [0, 0, 1, 1])), []);

// Taşıma kopya üretir, orijinali değiştirmez.
const moved = G.translated(line, 10, 20);
assert.equal(moved.p[0], 10);
assert.equal(moved.p[1], 20);
assert.equal(line.p[0], 0);

// Düz çizgi algısı.
assert.equal(G.nearlyStraight(line.p), true);
assert.equal(G.nearlyStraight([0, 0, 0.5, 50, 40, 0.5, 100, 0, 0.5]), false);
assert.equal(G.nearlyStraight([0, 0, 0.5, 5, 0, 0.5, 10, 0, 0.5]), false, 'kısa çizgi düzeltilmez');

// Geri al / yinele simetrik.
const s0 = [line];
const op = { before: [line], after: parts.map((p, i) => ({ id: 'p' + i, t: 'pen', c: '#000000', w: 2, p })) };
const s1 = G.applyOp(s0, op, false);
assert.deepEqual(plain(s1.map(s => s.id)), ['p0', 'p1']);
assert.deepEqual(plain(G.applyOp(s1, op, true).map(s => s.id)), ['a']);

// Yedekten gelen bozuk veri ayıklanır, yinelenen kimlikler düzeltilir.
const doc = G.sanitizeDoc({
  extra: 1e9,
  strokes: [
    line, { ...line }, { id: 'x', t: 'pen', c: 'red', w: 2, p: [0, 0, 1] },
    { id: 'y', t: 'brush', c: '#000000', w: 2, p: [0, 0, 1] },
    { id: 'z', t: 'hl', c: '#ffe14d', w: 18, p: [0, 0] },
    { id: 'n', t: 'hl', c: '#ffe14d', w: 18, p: [0, 0, NaN] },
    null,
  ],
});
assert.equal(doc.strokes.length, 2);
assert.notEqual(doc.strokes[0].id, doc.strokes[1].id);
assert.equal(doc.extra, 20000);
assert.deepEqual(plain(G.sanitizeDoc('bozuk').strokes), []);

// Özet içeriği: kayıt, bölüm sayısı, numaralar ve şablon kalıntısı.
let summary = null;
const sctx = { window: { hukukNotesRegister: s => { summary = s; } } };
vm.runInNewContext(fs.readFileSync('web/notes/summaries/icra.js', 'utf8'), sctx);
assert.equal(summary.id, 'icra');
assert.ok(Number.isInteger(summary.version));
const html = summary.html;
const nos = [...html.matchAll(/<span class="no">(\d+)<\/span><span class="tt">/g)].map(m => +m[1]);
assert.deepEqual(nos, Array.from({ length: 19 }, (_, i) => i + 1), 'bölümler 1..19 sırayla');
const ids = [...html.matchAll(/ id="([^"]+)"/g)].map(m => m[1]);
assert.equal(new Set(ids).size, ids.length, 'bölüm kimlikleri tekil');
assert.ok(!html.includes('${'), 'şablon kalıntısı yok');
for (const tag of ['div', 'table', 'ul', 'ol', 'span', 'h2', 'li']) {
  const open = (html.match(new RegExp(`<${tag}[\\s>]`, 'g')) || []).length;
  const close = (html.match(new RegExp(`</${tag}>`, 'g')) || []).length;
  assert.equal(open, close, `<${tag}> açılış/kapanış dengesi`);
}
assert.equal((html.match(/class="part"/g) || []).length, 2, 'iki bölüm başlığı');

console.log('notes ink tests passed');
