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

// Yollar 10x ölçekte tam sayılarla üretilir (SVG'de scale(0.1)).
assert.equal(G.PATH_SCALE, 0.1);
const dl = G.outline('pen', 2.4, line.p);
assert.ok(!/\d\.\d/.test(dl), 'yol koordinatları tam sayı');
assert.match(dl, /^M-?\d+ -?\d+/);

// Kayıt Float32Array kullanır; geri yüklerken düz diziye döner.
const f32 = G.sanitizeDoc({ strokes: [{ id: 'f', t: 'pen', c: '#000000', w: 2, p: new Float32Array([1.25, 2.5, 0.5, 9.75, 3, 0.75]) }] });
assert.equal(f32.strokes.length, 1);
assert.ok(Array.isArray(f32.strokes[0].p));
assert.deepEqual(plain(f32.strokes[0].p), [1.25, 2.5, 0.5, 9.75, 3, 0.75]);

// Kement ön eleme: kutu dışındaki çizgiye hiç bakılmaz, sonuç değişmez.
const far = { id: 'far', t: 'pen', c: '#000000', w: 2, p: G.lineBetween(0, 5000, 100, 5000, 0.5) };
assert.deepEqual(plain(G.lassoSelect([line, other, far], box)), ['a']);
const many = [];
for (let i = 0; i < 3000; i++) many.push({ id: 'm' + i, t: 'pen', c: '#000000', w: 2, p: G.lineBetween(0, i * 20 + 100, 80, i * 20 + 100, 0.5) });
const t0 = process.hrtime.bigint();
assert.deepEqual(plain(G.lassoSelect(many.concat([line]), box)), ['a']);
assert.ok(Number(process.hrtime.bigint() - t0) / 1e6 < 200, 'kement binlerce çizgide hızlı');

// Kement ile büyütme: dayanak noktası sabit kalır, kalınlık da ölçeklenir.
const seg = { id: 'g', t: 'pen', c: '#000000', w: 2, p: [10, 20, 0.5, 30, 40, 0.75] };
const big = G.scaled(seg, 10, 20, 1.5);
assert.deepEqual(plain(big.p), [10, 20, 0.5, 40, 50, 0.75]);
assert.equal(big.w, 3);
assert.equal(G.scaled({ ...seg, w: 60 }, 0, 0, 3).w, 79, 'kalınlık sınırlı');
assert.equal(seg.p[3], 30, 'orijinal değişmez');

// Fosforlu: kabaca yatay çizgi düz çizgiye döner, altındaki satırın ortasına oturur.
const wavy = [];
for (let i = 0; i < 20; i++) wavy.push(i * 10, 100 + (i % 2 ? 3 : -3), 0.5);
const flat = G.straightenHl(wavy, null);
assert.ok(flat && flat.length / 3 >= 30, 'düz çizgi sık noktalı');
assert.ok(flat.every((v, i) => i % 3 !== 1 || v === 100), 'tek bir y');
assert.equal(flat[0], 0);
assert.equal(flat[flat.length - 3], 190);
assert.equal(G.straightenHl(wavy, [0, 90, 300, 120])[1], 105, 'satır ortasına hizalanır');
assert.equal(G.straightenHl(wavy, [0, 140, 300, 170])[1], 100, 'uzak satıra hizalanmaz');
assert.equal(G.straightenHl(wavy, [400, 90, 600, 120])[1], 100, 'yatayda örtüşmeyen satıra hizalanmaz');
const circle = [];
for (let i = 0; i <= 24; i++) { const a = i / 24 * Math.PI * 2; circle.push(100 + 50 * Math.cos(a), 100 + 50 * Math.sin(a), 0.5); }
assert.equal(G.straightenHl(circle, null), null, 'daire korunur');
assert.equal(G.straightenHl([0, 0, 0.5, 20, 0, 0.5], null), null, 'kısa çizgi korunur');

// Arama: Türkçe harfler, şapka, tırnak ve boşluk farkı gözetilmez.
assert.equal(G.fold('  İTİRAZ ve   Şikâyet '), 'itiraz ve sikayet');
assert.equal(G.fold('IĞDIR'), 'igdir');
assert.equal(G.fold('“Ödeme” – emri'), '"odeme" - emri');
assert.equal(G.fold(''), '');

// Blok özeti: kararlı, kısa, ayırt edici.
assert.equal(G.hash('İcra emri'), G.hash('İcra emri'));
assert.notEqual(G.hash('m.114'), G.hash('m.115'));
assert.match(G.hash('İcra emri'), /^[0-9a-z]{1,7}$/);

// Yazdırma sayfa sonları: satır/blok aralığına düşmez; yer yoksa keser.
assert.deepEqual(plain(G.pageBreaks(1000, 300, [])), [0, 300, 600, 900, 1000]);
assert.deepEqual(plain(G.pageBreaks(1000, 300, [280, 320])), [0, 280, 580, 880, 1000], 'satırın üstünden bölünür');
assert.deepEqual(plain(G.pageBreaks(1000, 300, [100, 900])), [0, 300, 600, 900, 1000], 'uzun blok kesilir');
assert.deepEqual(plain(G.pageBreaks(250.4, 300, [])), [0, 251]);
assert.deepEqual(plain(G.pageBreaks(500, 5, [])), [0, 500]);
{
  let seed = 7;
  const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const iv = [];
  for (let y = 0; y < 20000; y += 20 + rnd() * 300) iv.push(y, y + 10 + rnd() * 120);
  const br = G.pageBreaks(20000, 1000, iv);
  for (let k = 1; k < br.length; k++) {
    assert.ok(br[k] > br[k - 1] && br[k] - br[k - 1] <= 1000, 'sayfa yüksekliği sınırda');
    if (k === br.length - 1) break;
    const y = br[k], inside = iv.some((a, i) => i % 2 === 0 && y > Math.ceil(a) && y < Math.floor(iv[i + 1]));
    const room = br[k] - br[k - 1] < 1000;
    assert.ok(!inside || !room, 'yer varken aralık içinden bölünmez');
  }
}

// Sayfa temeli (blok anahtarları + kutular): paketle, aç, doğrula.
const basis = { keys: ['s1|h2.sec|a', 's1|p|b'], r: [180, 0, 820, 40, 244, 60.5, 692, 40], end: 200 };
const packed = G.packBasis(basis);
assert.equal(packed.k, 's1|h2.sec|a\ns1|p|b');
assert.ok(ArrayBuffer.isView(packed.r));
const unpacked = G.parseBasis(packed);
assert.deepEqual(plain(unpacked.keys), basis.keys);
assert.deepEqual(Array.from(unpacked.r), basis.r);
assert.equal(unpacked.end, 200);
assert.ok(G.sameBasis(unpacked, G.parseBasis({ ...packed, r: packed.r.map(v => v + 0.5) })), 'yarım birim fark aynı sayılır');
assert.ok(!G.sameBasis(unpacked, G.parseBasis({ ...packed, k: 's1|h2.sec|a\ns1|p|c' })));
assert.equal(G.parseBasis({ k: 'a|p|1', r: [1, 2, 3], end: 10 }), null, 'kutu sayısı tutmalı');
assert.equal(G.parseBasis({ k: 'a|p|1', r: [1, 2, 3, NaN], end: 10 }), null);
assert.equal(G.parseBasis({ k: 'a|p|1', r: [1, 2, 3, 4], end: 0 }), null);
assert.equal(G.parseBasis({ k: 'a|p|1', r: 'x', end: 10 }), null);
assert.equal(G.parseBasis('x'), null);

// Belge biçimi 2: özet sürümü, temel, zaman ve yarım kayıt işareti korunur.
const doc2 = G.sanitizeDoc({ sv: 2, basis: packed, updated: 1760000000000, partial: true, strokes: [seg] });
assert.equal(doc2.v, 2);
assert.equal(doc2.sv, 2);
assert.deepEqual(plain(doc2.basis.keys), basis.keys);
assert.equal(doc2.updated, 1760000000000);
assert.equal(doc2.partial, true);
assert.equal(doc2.edited, 1760000000000, 'son düzenleme yoksa kayıt zamanı');
assert.equal(G.sanitizeDoc({ updated: 5, edited: 3 }).edited, 3, 'taşıma kaydı son düzenlemeyi değiştirmez');
assert.equal(G.sanitizeDoc({ edited: 'x' }).edited, 0);
for (const sv of [2.5, -1, 'x', 1e6]) assert.equal(G.sanitizeDoc({ sv }).sv, 0);
assert.equal(G.sanitizeDoc({ partial: 'true' }).partial, false);
assert.equal(G.sanitizeDoc({ basis: { k: 'a', r: [1], end: 3 } }).basis, null);

// Özet değişince notlar ait oldukları bloğun yeni yerine taşınır.
// Eski düzen: A, B, C (1. bölüm), D, E (2. bölüm). Yenisinde A'nın altına X
// eklendi, B'nin metni değişti ve uzadı, E 20 birim içeri alındı.
const A = { keys: ['s1|h2.sec|A', 's1|p|B', 's1|p|C', 's2|h2.sec|D', 's2|li|E'],
  r: [180, 0, 820, 40, 244, 60, 692, 40, 244, 120, 692, 40, 180, 200, 820, 40, 244, 260, 692, 40], end: 320 };
const Bn = { keys: ['s1|h2.sec|A', 's1|p|X', 's1|p|B2', 's1|p|C', 's2|h2.sec|D', 's2|li|E'],
  r: [180, 0, 820, 40, 244, 60, 692, 40, 244, 120, 692, 80, 244, 220, 692, 40, 180, 300, 820, 40, 264, 360, 672, 40], end: 420 };
const at = (id, x0, y0, x1, y1) => ({ id, t: 'pen', c: '#000000', w: 2, p: G.lineBetween(x0, y0, x1, y1, 0.5) });
const notes = [
  at('underA', 200, 35, 400, 35),
  at('underC', 260, 155, 500, 155),
  at('marginC', 40, 140, 120, 140),
  at('inB', 260, 80, 500, 80),
  at('underE', 300, 290, 500, 290),
  at('marginE', 1050, 270, 1150, 270),
  at('extra', 300, 400, 500, 400),
];
const shift = (s0, s1) => [s1.p[0] - s0.p[0], s1.p[1] - s0.p[1]];
const rm = G.remap(notes, A, Bn);
const byId = Object.fromEntries(rm.strokes.map(s => [s.id, s]));
const delta = id => shift(notes.find(s => s.id === id), byId[id]);
assert.equal(rm.strokes.length, notes.length);
assert.equal(byId.underA, notes[0], 'yeri değişmeyen not aynen kalır');
assert.deepEqual(delta('underC'), [0, 100], 'metin notu bloğuyla kayar');
assert.deepEqual(delta('marginC'), [0, 100], 'kenar notu yanındaki blokla kayar');
assert.deepEqual(delta('underE'), [20, 100], 'içeri alınan blokta yatay kayma da izlenir');
assert.deepEqual(delta('marginE'), [0, 100], 'sağ kenar notu yatayda kaymaz');
assert.deepEqual(delta('inB'), [0, 50], 'değişen blokta komşulara göre aradeğer');
assert.deepEqual(delta('extra'), [0, 100], 'sayfa sonu notu içerik sonuyla kayar');
assert.equal(rm.moved, 6);
assert.equal(notes[1].p[1], 155, 'girdi değişmez');
for (const s of rm.strokes) {
  const o = notes.find(n => n.id === s.id);
  assert.equal(s.p.length, o.p.length);
  assert.ok(s.p.every((v, i) => i % 3 !== 0 || Math.abs(v - o.p[i] - (s.p[0] - o.p[0])) < 0.011), 'şekil korunur (x)');
  assert.ok(s.p.every((v, i) => i % 3 !== 1 || Math.abs(v - o.p[i] - (s.p[1] - o.p[1])) < 0.011), 'şekil korunur (y)');
}
const again = G.remap(rm.strokes, Bn, G.parseBasis(G.packBasis(Bn)));
assert.equal(again.moved, 0, 'aynı temelde ikinci kez taşınmaz');
assert.equal(again.strokes, rm.strokes);
assert.equal(G.remap(notes, null, Bn).strokes, notes, 'temel yoksa dokunulmaz');
// Bölümlerin yeri değişse de (tekdüze olmayan eşleşme) değerler sonlu kalır.
const swapped = { keys: ['s2|h2.sec|D', 's2|li|E', 's1|h2.sec|A', 's1|p|B', 's1|p|C'],
  r: [180, 0, 820, 40, 244, 60, 692, 40, 180, 140, 820, 40, 244, 200, 692, 40, 244, 260, 692, 40], end: 320 };
const sw = G.remap(notes, A, swapped);
const swId = Object.fromEntries(sw.strokes.map(s => [s.id, s]));
assert.deepEqual(shift(notes[1], swId.underC), [0, 140]);
assert.deepEqual(shift(notes[4], swId.underE), [0, -200]);
assert.ok(sw.strokes.every(s => s.p.every(Number.isFinite) && s.p[1] >= 0));

// Özet içeriği: kayıt, bölüm sayısı, numaralar ve şablon kalıntısı.
const loadSummary = file => {
  let s = null;
  vm.runInNewContext(fs.readFileSync(file, 'utf8'), { window: { hukukNotesRegister: x => { s = x; } } });
  return s;
};
const checkHtml = (html, name) => {
  const nos = [...html.matchAll(/<span class="no">(\d+)<\/span><span class="tt">/g)].map(m => +m[1]);
  assert.deepEqual(nos, Array.from({ length: 19 }, (_, i) => i + 1), `${name}: bölümler 1..19 sırayla`);
  const ids = [...html.matchAll(/ id="([^"]+)"/g)].map(m => m[1]);
  assert.equal(new Set(ids).size, ids.length, `${name}: bölüm kimlikleri tekil`);
  assert.ok(!html.includes('${'), `${name}: şablon kalıntısı yok`);
  for (const tag of ['div', 'table', 'ul', 'ol', 'span', 'h2', 'h3', 'li', 'b', 'i', 'p', 'tr', 'td']) {
    const open = (html.match(new RegExp(`<${tag}[\\s>]`, 'g')) || []).length;
    const close = (html.match(new RegExp(`</${tag}>`, 'g')) || []).length;
    assert.equal(open, close, `${name}: <${tag}> açılış/kapanış dengesi`);
  }
  assert.equal((html.match(/class="part"/g) || []).length, 2, `${name}: iki bölüm başlığı`);
};
const cur = loadSummary('web/notes/summaries/icra.js');
assert.equal(cur.id, 'icra');
assert.equal(cur.version, 2);
assert.ok(!cur.legacy, 'güncel sürüm eski diye işaretlenmez');
checkHtml(cur.html, 'icra v2');
const v1 = loadSummary('web/notes/summaries/icra.v1.js');
assert.equal(v1.id, 'icra');
assert.equal(v1.version, 1);
assert.equal(v1.legacy, true);
checkHtml(v1.html, 'icra v1');
// v1, eski notların taşınması için ölçülür; tek karakteri bile değişmemeli.
assert.equal(v1.html.length, 41527, 'icra.v1.js dondurulmuştur');
assert.equal(G.hash(v1.html), '7cg8rg', 'icra.v1.js dondurulmuştur');
// 2. sürümdeki içerik düzeltmeleri geri gelmemeli.
assert.ok(!cur.html.includes('Uzlaştırma uygulanmaz'), 'icra suçları: CMK m.253/1-a ile çelişebilecek ifade kaldırıldı');
assert.ok(!cur.html.includes('henüz geçilmeyen yerlerde'), 'çocuk teslimi: İİK m.25 mülga (7343), ÇKK m.41/A');
assert.ok(cur.html.includes('kesin aciz belgesi'), 'İİK m.105: haciz tutanağı kesin aciz belgesi hükmünde');
assert.ok(cur.html.includes('7589'), 'güncel değişiklik belirtilir');

console.log('notes ink tests passed');
