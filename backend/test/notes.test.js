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
  const notifications = () => db.prepare('SELECT player_id, title, body FROM notifications ORDER BY id').all().map(r => ({...r}));
  return {db, call, notifications};
}
const now = () => Math.floor(Date.now() / 1000);

test('notes need a player code and come with flights in one request', async () => {
  const {call} = await setup();
  assert.equal((await call('/home', undefined, 0, {auth: false})).status, 401);
  assert.equal((await call('/notes', {text: 'x'}, 0, {auth: false})).status, 401);
  const home = await call('/home');
  assert.equal(home.status, 200);
  assert.deepEqual(home.data.trips, []);
  assert.deepEqual(home.data.notes, []);
  // Older app versions still read /trips (same payload).
  assert.deepEqual(Object.keys((await call('/trips')).data).sort(), ['me', 'notes', 'now', 'trips']);
});

test('a note notifies the other player and expires after 24 hours', async () => {
  const {call, notifications} = await setup();
  const r = await call('/notes', {text: '  Seni çok özledim\r\nyakında görüşürüz  '}, 1);
  assert.equal(r.status, 200);
  const [note] = r.data.notes;
  assert.equal(note.player, 2);
  assert.equal(note.name, 'ari');
  assert.equal(note.text, 'Seni çok özledim\nyakında görüşürüz');
  assert.equal(note.expires - note.created, 86400);
  assert.deepEqual(notifications(), [{player_id: 1, title: 'ari sana not bıraktı! 📌',
    body: 'Kaybolmadan görüntüle: not 24 saat sonra silinecek.'}]);
});

test('one active note per player; deleting allows a new one, without notification spam', async () => {
  const {db, call, notifications} = await setup();
  const first = (await call('/notes', {text: 'ilk'})).data.notes[0];
  const again = await call('/notes', {text: 'ikinci'});
  assert.equal(again.status, 409);
  assert.match(again.data.error, /önce onu sil/);
  // Both players' notes sit side by side, ordered by player.
  await call('/notes', {text: 'benden de'}, 1);
  assert.deepEqual((await call('/home')).data.notes.map(n => [n.player, n.text]), [[1, 'ilk'], [2, 'benden de']]);
  // Player 2 cannot delete Player 1's note.
  assert.equal((await call('/notes/delete', {id: first.id}, 1)).data.notes.length, 2);
  assert.equal((await call('/notes/delete', {id: first.id})).data.notes.length, 1);
  assert.equal((await call('/notes', {text: 'yeni not'})).status, 200);
  // Re-posting within 10 minutes does not notify again.
  assert.deepEqual(notifications().map(n => n.player_id), [2, 1]);
  db.prepare('UPDATE notes SET created = created - 700').run();
  await call('/notes/delete', {id: (await call('/home')).data.notes.find(n => n.player === 1).id});
  await call('/notes', {text: 'on dakika sonra'});
  assert.deepEqual(notifications().map(n => n.player_id), [2, 1, 2]);
});

test('Player 1 can remove any note; expired notes disappear and are pruned', async () => {
  const {db, call} = await setup();
  const hers = (await call('/notes', {text: 'pembe not'}, 1)).data.notes[0];
  assert.equal((await call('/notes/delete', {id: hers.id})).data.notes.length, 0);
  db.prepare('INSERT INTO notes(player_id, text, created) VALUES (2, ?, ?)').run('dünkü', now() - 86401);
  assert.deepEqual((await call('/home')).data.notes, []);
  await call('/notes', {text: 'bugün'});
  assert.deepEqual(db.prepare('SELECT text FROM notes WHERE deleted = 0').all().map(r => r.text), ['bugün']);
});

test('note text is validated', async () => {
  const {call} = await setup();
  for (const text of ['', '   ', 'x'.repeat(201), 'a\nb\nc\nd\ne\nf\ng\nh\ni', 'tab\there', 'gizli‮yazı', 42]) {
    const r = await call('/notes', {text});
    assert.equal(r.status, 400, JSON.stringify(text));
  }
  assert.equal((await call('/notes', {text: 'x'.repeat(200)})).status, 200);
});
