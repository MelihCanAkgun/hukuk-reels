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
    .run(i + 1, await tokenHash(tokens[i]), ['mqcan 😎', 'ari'][i]);
  const env = {APP_ORIGIN: 'https://app.example', APP_URL: 'https://app.example/', DB: {prepare(sql) {
    let args = [];
    const stmt = db.prepare(sql);
    return {bind(...v) { args = v; return this; }, async first() { return stmt.get(...args) || null; },
      async all() { return {results: stmt.all(...args)}; }, async run() { return stmt.run(...args); }};
  }}};
  async function call(path, data, id = 0, {auth = true} = {}) {
    const headers = {Origin: env.APP_ORIGIN};
    if (auth) headers.Authorization = 'Bearer ' + tokens[id];
    const response = await worker.fetch(new Request('https://worker.example' + path, {
      method: data === undefined ? 'GET' : 'POST', headers,
      ...(data === undefined ? {} : {body: JSON.stringify(data)}),
    }), env, {waitUntil() {}});
    return {status: response.status, data: await response.json()};
  }
  return {db, call};
}
const now = () => Math.floor(Date.now() / 1000);

test('only the two players can see or add flights', async () => {
  const {call} = await setup();
  assert.equal((await call('/trips', undefined, 0, {auth: false})).status, 401);
  assert.equal((await call('/trips', {destination: 'İstanbul', arrival: now() + 3600}, 0, {auth: false})).status, 401);
  const empty = await call('/trips');
  assert.equal(empty.status, 200);
  assert.deepEqual(empty.data.trips, []);
});

test('a flight is added for the player who enters it and sorted by arrival', async () => {
  const {call} = await setup();
  const later = now() + 20 * 86400, sooner = now() + 3 * 86400;
  await call('/trips', {destination: 'Ankara', arrival: later});
  const r = await call('/trips', {destination: '  İstanbul ', arrival: sooner}, 1);
  assert.equal(r.status, 200);
  assert.deepEqual(r.data.trips.map(t => [t.player, t.name, t.destination, t.arrival]),
    [[2, 'ari', 'İstanbul', sooner], [1, 'mqcan 😎', 'Ankara', later]]);
  assert.ok(Math.abs(r.data.now - now()) < 5);
  // Both players see the same list.
  assert.equal((await call('/trips')).data.trips.length, 2);
});

test('flights are validated', async () => {
  const {call} = await setup();
  for (const [data, msg] of [
    [{destination: '', arrival: now() + 60}, 'varış yeri'],
    [{destination: 'x'.repeat(41), arrival: now() + 60}, 'varış yeri'],
    [{destination: 'Evil‮anilam', arrival: now() + 60}, 'varış yeri'],
    [{destination: 'İzmir', arrival: now() - 3600}, 'gelecekte'],
    [{destination: 'İzmir', arrival: now() + 3 * 365 * 86400}, 'iki yıl'],
    [{destination: 'İzmir', arrival: '2026-11-01'}, 'gelecekte'],
  ]) {
    const r = await call('/trips', data);
    assert.equal(r.status, 400);
    assert.match(r.data.error, new RegExp(msg));
  }
  for (let i = 0; i < 10; i++) assert.equal((await call('/trips', {destination: 'A' + i, arrival: now() + 3600 * (i + 1)})).status, 200);
  assert.equal((await call('/trips', {destination: 'B', arrival: now() + 86400 * 30})).status, 400);
});

test('players delete their own flights; Player 1 can delete any', async () => {
  const {call} = await setup();
  const mine = (await call('/trips', {destination: 'Ankara', arrival: now() + 86400})).data.trips[0].id;
  const hers = (await call('/trips', {destination: 'İstanbul', arrival: now() + 2 * 86400}, 1)).data.trips[1].id;
  // Player 2 cannot remove Player 1's flight.
  assert.equal((await call('/trips/delete', {id: mine}, 1)).data.trips.length, 2);
  assert.equal((await call('/trips/delete', {id: hers}, 1)).data.trips.length, 1);
  const again = (await call('/trips', {destination: 'İzmir', arrival: now() + 3 * 86400}, 1)).data.trips;
  const herId = again.find(t => t.player === 2).id;
  // The admin removes any flight.
  assert.deepEqual((await call('/trips/delete', {id: herId})).data.trips.map(t => t.id), [mine]);
});

test('arrived flights stay for a day, then disappear', async () => {
  const {db, call} = await setup();
  db.prepare('INSERT INTO trips(player_id, destination, arrival, created) VALUES (2, ?, ?, ?)').run('Dün', now() - 3600, now() - 86400);
  db.prepare('INSERT INTO trips(player_id, destination, arrival, created) VALUES (2, ?, ?, ?)').run('Eski', now() - 2 * 86400, now() - 9 * 86400);
  assert.deepEqual((await call('/trips')).data.trips.map(t => t.destination), ['Dün']);
  // Reading never writes; the old row is pruned on the next add.
  assert.equal(db.prepare('SELECT COUNT(*) n FROM trips').get().n, 2);
  await call('/trips', {destination: 'Yeni', arrival: now() + 3600});
  assert.deepEqual(db.prepare('SELECT destination FROM trips ORDER BY arrival').all().map(r => r.destination), ['Dün', 'Yeni']);
});
