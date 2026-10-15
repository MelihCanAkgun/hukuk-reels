import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';
import {sanitizeJpeg, cleanFullJpeg} from '../src/avatar.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43), 'c'.repeat(43)];
async function setup() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i = 0; i < 2; i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i + 1, await tokenHash(tokens[i]), ['Melih', 'Arkadaş'][i]);
  const env = {APP_ORIGIN: 'https://app.example', APP_URL: 'https://app.example/', DB: {prepare(sql) {
    let args = [];
    const stmt = db.prepare(sql);
    return {bind(...v) { args = v; return this; }, async first() { return stmt.get(...args) || null; },
      async all() { return {results: stmt.all(...args)}; }, async run() { return stmt.run(...args); }};
  }}};
  async function call(path, data, id = 0, {method, auth = true, origin = env.APP_ORIGIN, raw} = {}) {
    const headers = {Origin: origin};
    if (auth) headers.Authorization = 'Bearer ' + tokens[id];
    const response = await worker.fetch(new Request('https://worker.example' + path, {
      method: method || (data === undefined && raw === undefined ? 'GET' : 'POST'), headers,
      ...(raw !== undefined ? {body: raw} : data === undefined ? {} : {body: JSON.stringify(data)}),
    }), env, {waitUntil() {}});
    const text = await response.text();
    let parsed;
    try { parsed = JSON.parse(text); } catch { parsed = text; }
    return {status: response.status, headers: response.headers, data: parsed};
  }
  return {db, call};
}

// Minimal structurally valid JPEG: SOI, APP0, APP1(Exif with fake GPS), COM, SOF0 320x320, SOS, data, EOI.
function jpeg({width = 320, height = 320, exif = true, pad = 200, icc = false, app2 = null} = {}) {
  const seg = (m, payload) => [0xFF, m, (payload.length + 2) >> 8, (payload.length + 2) & 255, ...payload];
  const ascii = s => [...s].map(c => c.charCodeAt(0));
  return new Uint8Array([
    0xFF, 0xD8,
    ...seg(0xE0, ascii('JFIF\0') .concat([1, 1, 0, 0, 1, 0, 1, 0, 0])),
    ...(exif ? seg(0xE1, ascii('Exif\0\0GPS 41.0082N 28.9784E iPhone')) : []),
    ...(icc ? seg(0xE2, ascii('ICC_PROFILE\0\x01\x01sRGB profile data')) : []),
    ...(app2 ? seg(0xE2, ascii(app2)) : []),
    ...(exif ? seg(0xFE, ascii('secret comment')) : []),
    ...seg(0xC0, [8, height >> 8, height & 255, width >> 8, width & 255, 1, 1, 0x11, 0]),
    ...seg(0xDA, [1, 1, 0, 0, 63, 0]),
    ...new Array(pad).fill(0x2A),
    0xFF, 0xD9,
  ]);
}
const b64 = bytes => Buffer.from(bytes).toString('base64');

test('sanitizer strips EXIF/comments and rejects non-JPEG data', () => {
  const clean = sanitizeJpeg(jpeg());
  const text = Buffer.from(clean).toString('latin1');
  assert.ok(!text.includes('Exif') && !text.includes('GPS') && !text.includes('secret'));
  assert.ok(text.includes('JFIF'));
  assert.equal(clean[0], 0xFF); assert.equal(clean.at(-1), 0xD9);
  for (const bad of [
    new TextEncoder().encode('<html><script>alert(1)</script></html>'.repeat(4)),
    new Uint8Array([0x89, 0x50, 0x4E, 0x47, ...new Array(100).fill(0)]),
    jpeg({width: 5000}),
    jpeg().slice(0, -2),
  ]) assert.throws(() => sanitizeJpeg(bad));
  assert.throws(() => sanitizeJpeg(jpeg({pad: 100 * 1024})), e => e.status === 413);
});

test('only registered players can upload, list and read avatars', async () => {
  const {db, call} = await setup();
  // No code / wrong code / foreign origin never reach the data.
  assert.equal((await call('/avatar?id=1', undefined, 0, {auth: false})).status, 401);
  assert.equal((await call('/avatar?id=1', undefined, 2)).status, 401);
  assert.equal((await call('/avatar?id=1', undefined, 0, {origin: 'https://evil.example'})).status, 403);
  assert.equal((await call('/avatar?id=1')).status, 404);

  const up = await call('/avatar', {data: b64(jpeg())});
  assert.equal(up.status, 200);
  const mine = up.data.players.find(p => p.id === 1);
  assert.match(mine.avatar, /^[0-9a-f]{20}$/);
  assert.equal(up.data.players.find(p => p.id === 2).avatar, null);
  // The board carries only the version tag, never the photo.
  assert.ok(!JSON.stringify(up.data).includes(b64(jpeg()).slice(0, 40)));

  // The other registered player can read it; stored bytes have no metadata.
  const got = await call('/avatar?id=1', undefined, 1);
  assert.equal(got.status, 200);
  assert.equal(got.data.version, mine.avatar);
  assert.equal(got.headers.get('cache-control'), 'no-store');
  assert.equal(got.headers.get('x-content-type-options'), 'nosniff');
  const stored = Buffer.from(got.data.data, 'base64').toString('latin1');
  assert.ok(!stored.includes('GPS') && !stored.includes('Exif'));
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatars').get().n, 1);
});

test('uploads are validated, rate limited and deletable', async () => {
  const {db, call} = await setup();
  assert.equal((await call('/avatar', {data: 'not base64 !!'})).status, 400);
  assert.equal((await call('/avatar', {data: b64(new TextEncoder().encode('x'.repeat(500)))})).status, 400);
  assert.equal((await call('/avatar', undefined, 0, {raw: 'x'.repeat(200000)})).status, 413);
  assert.equal((await call('/avatar', {data: b64(jpeg())})).status, 200);
  assert.equal((await call('/avatar', {data: b64(jpeg({pad: 300}))})).status, 429);
  db.prepare('UPDATE avatars SET updated = updated - 60').run();
  assert.equal((await call('/avatar', {data: b64(jpeg({pad: 300}))})).status, 200);
  // A player can only change their own photo.
  assert.equal((await call('/avatar/delete', {}, 1)).status, 200);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatars').get().n, 1);
  const del = await call('/avatar/delete', {});
  assert.equal(del.status, 200);
  assert.equal(del.data.players.find(p => p.id === 1).avatar, null);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatars').get().n, 0);
  assert.equal((await call('/avatar?id=3')).status, 400);
});

test('inactive players cannot use avatars', async () => {
  const {db, call} = await setup();
  db.prepare('UPDATE players SET active = 0 WHERE id = 2').run();
  assert.equal((await call('/avatar?id=1', undefined, 1)).status, 403);
  assert.equal((await call('/avatar', {data: b64(jpeg())}, 1)).status, 403);
});

const fullBody = (thumb, full) => b64(thumb) + '\n' + b64(full);

test('full-quality upload is stored in parts and only Player 1 can download it', async () => {
  const {db, call} = await setup();
  const big = jpeg({width: 3024, height: 3024, exif: false, pad: 2_500_000});
  const up = await call('/avatar/full', undefined, 1, {raw: fullBody(jpeg(), big)});
  assert.equal(up.status, 200);
  const p2 = up.data.players.find(p => p.id === 2);
  assert.equal(p2.avatarFull, big.length);
  assert.equal(p2.avatarWidth, 3024);
  assert.equal(db.prepare('SELECT parts FROM avatar_full WHERE player_id = 2').get().parts, 4);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatar_full_parts').get().n, 4);
  // Display copy is still served to both players.
  assert.equal((await call('/avatar?id=2', undefined, 0)).data.version, p2.avatar);

  // Player 2 may not download full copies (not even their own).
  assert.equal((await call('/avatar/full?id=2', undefined, 1)).status, 403);
  const got = await call('/avatar/full?id=2', undefined, 0);
  assert.equal(got.status, 200);
  assert.equal(got.headers.get('x-avatar-version'), p2.avatar);
  assert.equal(got.headers.get('cache-control'), 'no-store');
  assert.match(got.headers.get('content-disposition'), /attachment/);
  assert.ok(Buffer.from(got.data, 'base64').equals(Buffer.from(big)));
  assert.equal((await call('/avatar/full?id=1', undefined, 0)).status, 404);

  // A new upload replaces the old parts; a display-only upload drops the full copy.
  db.prepare('UPDATE avatars SET updated = updated - 60').run();
  const small = jpeg({width: 800, height: 800, exif: false, pad: 5000});
  assert.equal((await call('/avatar/full', undefined, 1, {raw: fullBody(jpeg({pad: 300}), small)})).status, 200);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatar_full_parts').get().n, 1);
  db.prepare('UPDATE avatars SET updated = updated - 60').run();
  const legacy = await call('/avatar', {data: b64(jpeg({pad: 400}))}, 1);
  assert.equal(legacy.data.players.find(p => p.id === 2).avatarFull, null);
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatar_full_parts').get().n, 0);
  assert.equal((await call('/avatar/full?id=2', undefined, 0)).status, 404);
});

test('full-quality uploads are validated and deletable', async () => {
  const {db, call} = await setup();
  const ok = jpeg({width: 2000, height: 2000, exif: false});
  // A browser colour profile is kept; EXIF, comments and other APP2 payloads are removed.
  const cleaned = Buffer.from(cleanFullJpeg(b64(jpeg({width: 2000, height: 2000, icc: true, app2: 'MPF\0 hidden data here'}))).text, 'base64').toString('latin1');
  assert.ok(cleaned.includes('ICC_PROFILE') && cleaned.includes('JFIF'));
  assert.ok(!cleaned.includes('Exif') && !cleaned.includes('GPS') && !cleaned.includes('secret') && !cleaned.includes('MPF'));
  // Oversize sides, truncated data, missing separator, non-JPEG.
  for (const raw of [
    fullBody(jpeg(), jpeg({width: 9000, height: 100, exif: false})),
    fullBody(jpeg(), ok.slice(0, -2)),
    b64(ok),
    fullBody(jpeg(), new TextEncoder().encode('<svg onload=alert(1)>'.repeat(20))),
    b64(jpeg()) + '\n' + b64(ok).slice(0, -1),
  ]) assert.equal((await call('/avatar/full', undefined, 0, {raw})).status, 400, raw.slice(-30));
  assert.equal(db.prepare('SELECT COUNT(*) n FROM avatars').get().n, 0);
  assert.throws(() => cleanFullJpeg('A'.repeat(17_000_000)), e => e.status === 413);
  assert.equal((await call('/avatar/full', undefined, 0, {raw: fullBody(jpeg(), ok)})).status, 200);
  assert.equal((await call('/avatar/full', undefined, 0, {raw: fullBody(jpeg({pad: 300}), ok)})).status, 429);
  assert.equal((await call('/avatar/delete', {})).status, 200);
  for (const t of ['avatars', 'avatar_full', 'avatar_full_parts'])
    assert.equal(db.prepare(`SELECT COUNT(*) n FROM ${t}`).get().n, 0, t);
});

test('full-quality cleaning stays cheap for large photos', () => {
  const text = b64(jpeg({width: 4096, height: 4096, pad: 9_000_000}));
  cleanFullJpeg(text); // warm up
  const t = performance.now();
  for (let i = 0; i < 5; i++) cleanFullJpeg(text);
  assert.ok((performance.now() - t) / 5 < 3, 'cleaning should not scan the whole body');
});

// Safari/ImageIO-style header: JFIF, EXIF, Photoshop (APP13), then tables and a scan.
function appleJpeg(exifLen, scanBytes) {
  const seg = (m, payload) => Buffer.from([0xFF, m, (payload.length + 2) >> 8, (payload.length + 2) & 255, ...payload]);
  const scan = Buffer.alloc(scanBytes);
  for (let i = 0; i < scanBytes; i++) scan[i] = (i * 7919) % 255; // never 0xFF
  return Buffer.concat([
    Buffer.from([0xFF, 0xD8]),
    seg(0xE0, [...Buffer.from('JFIF\0'), 1, 1, 0, 0, 72, 0, 72, 0, 0]),
    seg(0xE1, [...Buffer.from('Exif\0\0MM'), ...new Array(exifLen).fill(1)]),
    seg(0xED, [...Buffer.from('Photoshop 3.0\0'), ...new Array(30).fill(2)]),
    seg(0xDB, new Array(65).fill(3)),
    seg(0xC0, [8, 0x0B, 0xD0, 0x0B, 0xD0, 3, 1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1]),
    seg(0xDA, [3, 1, 0, 2, 0x11, 3, 0x11, 0, 63, 0]),
    scan,
    Buffer.from([0xFF, 0xD9]),
  ]);
}

test('Safari-style metadata is stripped and the scan data is kept byte for byte', () => {
  for (const exifLen of [60, 61, 62]) { // removed length ≡ 0, 1, 2 (mod 3)
    for (const scanBytes of [5000, 2_000_000]) { // whole-file and header-only paths
      const src = appleJpeg(exifLen, scanBytes);
      const {text, width, height, size} = cleanFullJpeg(src.toString('base64'));
      const out = Buffer.from(text, 'base64');
      assert.equal(width, 3024); assert.equal(height, 3024); assert.equal(size, out.length);
      const latin = out.subarray(0, 400).toString('latin1');
      assert.ok(!latin.includes('Exif') && !latin.includes('Photoshop') && latin.includes('JFIF'));
      // Everything from the scan marker on is identical; only 0xFF fill bytes precede it.
      const sos = src.indexOf(Buffer.from([0xFF, 0xDA]));
      const outSos = out.length - (src.length - sos);
      assert.ok(out.subarray(outSos).equals(src.subarray(sos)));
      const sof = out.indexOf(Buffer.from([0xFF, 0xC0]));
      const fill = outSos - (sof + 19);
      const removed = (4 + 8 + exifLen) + (4 + 14 + 30); // APP1 + APP13
      assert.equal(fill, scanBytes > 100_000 ? removed % 3 : 0);
      for (let k = sof + 19; k < outSos; k++) assert.equal(out[k], 0xFF);
    }
  }
});
