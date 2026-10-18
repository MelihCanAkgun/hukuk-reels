import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
async function setup() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i = 0; i < 2; i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i + 1, await tokenHash(tokens[i]), ['mqcan', 'ari'][i]);
  const env = {APP_ORIGIN: 'https://app.example', DB: {prepare(sql) {
    let args = [];
    const stmt = db.prepare(sql);
    return {bind(...values) { args = values; return this; }, async first() { return stmt.get(...args) || null; },
      async all() { return {results: stmt.all(...args)}; }, async run() { return stmt.run(...args); }};
  }}};
  async function call(path, data, id = 0) {
    const response = await worker.fetch(new Request('https://worker.example' + path, {
      method: data === undefined ? 'GET' : 'POST',
      headers: {Origin: env.APP_ORIGIN, Authorization: 'Bearer ' + tokens[id]},
      ...(data === undefined ? {} : {body: JSON.stringify(data)}),
    }), env, {waitUntil() {}});
    return {status: response.status, data: await response.json()};
  }
  return {db, call};
}
// Fake clock in seconds.
function clock(t) {
  const real = Date.now;
  const c = {t, restore: () => { Date.now = real; }};
  Date.now = () => c.t * 1000;
  return c;
}

test('opening and heartbeats build sessions; last_seen follows', async t => {
  const {db, call} = await setup();
  const c = clock(1_800_000_000);
  t.after(c.restore);
  const rows = () => db.prepare('SELECT player_id, started, last, device FROM sessions ORDER BY id').all()
    .map(r => ({...r}));
  assert.deepEqual((await call('/seen', {open: true, device: 'ipad'})).data, {ok: true});
  c.t += 300; await call('/seen', {device: 'ipad'});            // heartbeat extends
  c.t += 60; await call('/seen', {open: true, device: 'ipad'});  // quick return: same session
  assert.deepEqual(rows(), [{player_id: 1, started: 1_800_000_000, last: 1_800_000_360, device: 'ipad'}]);
  c.t += 300; await call('/seen', {open: true, device: 'ipad'});  // back after 5 min: new entry
  c.t += 700; await call('/seen', {device: 'ipad'});              // heartbeat after a long gap: new
  c.t += 10; await call('/seen', {open: true, device: 'iphone'}, 1);
  assert.deepEqual(rows().map(r => [r.player_id, r.started - 1_800_000_000, r.device]),
    [[1, 0, 'ipad'], [1, 660, 'ipad'], [1, 1360, 'ipad'], [2, 1370, 'iphone']]);
  assert.deepEqual(db.prepare('SELECT id, last_seen FROM players ORDER BY id').all().map(r => [r.id, r.last_seen]),
    [[1, 1_800_001_360], [2, 1_800_001_370]]);
  // Unknown device names are stored as 'other'; another device is its own session.
  await call('/seen', {open: true, device: '<script>'}, 1);
  assert.deepEqual(rows().slice(-2).map(r => r.device), ['iphone', 'other']);
});

test('only Player 1 can read activity; Player 2 sees no such route', async t => {
  const {call} = await setup();
  const c = clock(1_800_000_000);
  t.after(c.restore);
  await call('/seen', {open: true, device: 'mac'});
  c.t += 30; await call('/seen', {open: true, device: 'iphone'}, 1);
  const r = await call('/activity');
  assert.equal(r.status, 200);
  assert.equal(r.data.now, 1_800_000_030);
  assert.deepEqual(r.data.players.map(p => [p.id, p.name, p.lastSeen]),
    [[1, 'mqcan', 1_800_000_000], [2, 'ari', 1_800_000_030]]);
  assert.deepEqual(r.data.sessions.map(s => [s.player, s.device]), [[2, 'iphone'], [1, 'mac']]);
  const denied = await call('/activity', undefined, 1);
  assert.equal(denied.status, 404);
  assert.equal(denied.data.sessions, undefined);
  assert.equal((await call('/activity', {})).status, 404);
  assert.equal((await call('/seen')).status, 404);
});

test('sessions older than 90 days are removed; activity lists 30 days', async t => {
  const {db, call} = await setup();
  const c = clock(1_800_000_000);
  t.after(c.restore);
  await call('/seen', {open: true, device: 'ipad'});
  c.t += 40 * 86400; await call('/seen', {open: true, device: 'ipad'});
  assert.equal((await call('/activity')).data.sessions.length, 1);
  c.t += 60 * 86400; await call('/seen', {open: true, device: 'ipad'});
  assert.equal(db.prepare('SELECT COUNT(*) n FROM sessions').get().n, 2);
});

test('inactive players cannot report activity', async () => {
  const {db, call} = await setup();
  db.prepare('UPDATE players SET active = 0 WHERE id = 2').run();
  assert.equal((await call('/seen', {open: true}, 1)).status, 403);
  assert.deepEqual((await call('/activity')).data.players.map(p => p.id), [1]);
});
