import {test} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash, nameKey} from '../src/worker.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
async function setup(limit) {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i = 0; i < 2; i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i + 1, await tokenHash(tokens[i]), ['mqcan 😎', 'ari'][i]);
  const counts = {};
  const env = {APP_ORIGIN: 'https://app.example', APP_URL: 'https://app.example/', DB: {prepare(sql) {
    let args = [];
    const stmt = db.prepare(sql);
    return {bind(...v) { args = v; return this; }, async first() { return stmt.get(...args) || null; },
      async all() { return {results: stmt.all(...args)}; }, async run() { return stmt.run(...args); }};
  }}};
  if (limit) env.REQUEST_LIMIT = {async limit({key}) { counts[key] = (counts[key] || 0) + 1; return {success: counts[key] <= limit}; }};
  async function call(path, data, {token = tokens[0], ip = '203.0.113.7'} = {}) {
    const headers = {Origin: env.APP_ORIGIN, 'CF-Connecting-IP': ip};
    if (token) headers.Authorization = 'Bearer ' + token;
    const response = await worker.fetch(new Request('https://worker.example' + path, {
      method: data === undefined ? 'GET' : 'POST', headers,
      ...(data === undefined ? {} : {body: JSON.stringify(data)}),
    }), env, {waitUntil() {}});
    return {status: response.status, data: await response.json()};
  }
  return {db, call};
}

test('every data endpoint requires one of the two player codes', async () => {
  const {call} = await setup();
  const guess = 'Z'.repeat(43);
  for (const [path, data] of [['/board'], ['/avatar?id=1'], ['/avatar?id=2'], ['/avatar/full?id=1'],
    ['/score', {score: 1}], ['/profile', {name: 'x'}], ['/message', {message: 'x'}],
    ['/avatar/delete', {}], ['/battle/create', {}], ['/subscribe', {}]]) {
    assert.equal((await call(path, data, {token: null})).status, 401, path);
    assert.equal((await call(path, data, {token: guess})).status, 401, path);
  }
  assert.equal((await call('/health', undefined, {token: null})).status, 200);
});

test('requests are rate limited per IP before any token check', async () => {
  const {call} = await setup(3);
  for (let i = 0; i < 3; i++) assert.equal((await call('/board', undefined, {token: 'Z'.repeat(43)})).status, 401);
  const blocked = await call('/board');
  assert.equal(blocked.status, 429);
  // Another address is unaffected; /health is never limited.
  assert.equal((await call('/board', undefined, {ip: '198.51.100.9'})).status, 200);
  assert.equal((await call('/health', undefined, {token: null})).status, 200);
});

test('a player cannot take the other player\'s name', async () => {
  const {db, call} = await setup();
  assert.equal(nameKey('mqcan 😎'), nameKey(' MQCAN '));
  assert.equal(nameKey('ARIFE'), nameKey('arife 🌷'));
  assert.equal(nameKey('mqcän'), nameKey('MQÇAN'.replace('Ç', 'C')));
  for (const name of ['mqcan 😎', 'MQCAN', 'mq can!', 'Mqcan👑', 'mqcän']) {
    const r = await call('/profile', {name}, {token: tokens[1]});
    assert.equal(r.status, 400, name);
    assert.equal(r.data.error, 'Bu isim diğer oyuncuya ait.');
  }
  assert.equal(db.prepare('SELECT name FROM players WHERE id = 2').get().name, 'ari');
  assert.equal((await call('/profile', {name: 'arife 🌷'}, {token: tokens[1]})).status, 200);
  // The admin keeps renaming freely (just not to the other player's name).
  assert.equal((await call('/profile', {name: 'mqcan 👑'})).status, 200);
  assert.equal((await call('/profile', {name: 'ARIFE'})).status, 400);
});
