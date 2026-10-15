import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';
import {sanitizeJpeg} from '../src/avatar.js';

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
    return {status: response.status, headers: response.headers, data: await response.json()};
  }
  return {db, call};
}

// Minimal structurally valid JPEG: SOI, APP0, APP1(Exif with fake GPS), COM, SOF0 320x320, SOS, data, EOI.
function jpeg({width = 320, height = 320, exif = true, pad = 200} = {}) {
  const seg = (m, payload) => [0xFF, m, (payload.length + 2) >> 8, (payload.length + 2) & 255, ...payload];
  const ascii = s => [...s].map(c => c.charCodeAt(0));
  return new Uint8Array([
    0xFF, 0xD8,
    ...seg(0xE0, ascii('JFIF\0') .concat([1, 1, 0, 0, 1, 0, 1, 0, 0])),
    ...(exif ? seg(0xE1, ascii('Exif\0\0GPS 41.0082N 28.9784E iPhone')) : []),
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
