import {test, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';
import {finalize, weeklyTick, standing, TROPHIES, ROUND_LENGTH} from '../src/weekly.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
const realNow = Date.now;
afterEach(() => { Date.now = realNow; });
const START = Date.UTC(2026, 10, 13, 17, 0, 0) / 1000;
const END = START + ROUND_LENGTH;
const at = seconds => { Date.now = () => seconds * 1000; };

async function setup() {
  const pending = [];
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i = 0; i < 2; i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i + 1, await tokenHash(tokens[i]), ['mqcan', 'ari'][i]);
  const env = {APP_ORIGIN: 'https://app.example', APP_URL: 'https://app.example/', DB: {prepare(sql) {
    let args = [];
    const stmt = db.prepare(sql);
    return {bind(...v) { args = v; return this; }, async first() { return stmt.get(...args) || null; },
      async all() { return {results: stmt.all(...args)}; }, async run() { return stmt.run(...args); }};
  }}};
  async function call(path, data, id = 0) {
    const response = await worker.fetch(new Request('https://worker.example' + path, {
      method: data === undefined ? 'GET' : 'POST', headers: {Origin: env.APP_ORIGIN, Authorization: 'Bearer ' + tokens[id]},
      ...(data === undefined ? {} : {body: JSON.stringify(data)}),
    }), env, {waitUntil(p) { pending.push(p.catch(() => {})); }});
    return {status: response.status, data: await response.json()};
  }
  const notifications = () => db.prepare('SELECT player_id, title, body FROM notifications ORDER BY id').all().map(r => ({...r}));
  const score = (id, game, value, at) => call('/weekly/score', {game, score: value, ...(at ? {at} : {})}, id);
  const start = () => call('/weekly/start', {}, 0);
  return {db, env, call, notifications, score, start};
}

test('only the admin starts a round; it lasts seven days', async () => {
  at(START);
  const {call, start, notifications} = await setup();
  let r = await call('/weekly');
  assert.equal(r.data.round, null);
  assert.equal(r.data.canStart, true);
  assert.equal(r.data.nextTrophy, 0);
  assert.equal((await call('/weekly', undefined, 1)).data.canStart, false);
  assert.equal((await call('/weekly/start', {}, 1)).status, 403);
  r = await start();
  assert.equal(r.status, 200);
  assert.deepEqual(r.data.round, {id: 1, start: START, end: END, trophy: 0, startedBy: 1});
  assert.equal(r.data.canStart, false);
  assert.equal((await start()).status, 409);
  assert.deepEqual(notifications(), [{player_id: 2, title: 'mqcan meydan okuma başlattı! ⚔️',
    body: '7 gün, 4 oyun. Ödül: Altın Kupa. İlk skoru sen yap!'}]);
  assert.equal(TROPHIES.length, 7);
});

test('best per game in the round; the better score wins the game', async () => {
  at(START);
  const {call, score, start} = await setup();
  await start();
  at(START + 3600);
  await score(0, 'block', 500);
  await score(0, 'block', 300);        // never lowers
  await score(1, 'block', 400);
  await score(1, 'tower', 12);
  await score(0, 'flappy', 7);
  const r = await score(1, 'flappy', 7);     // equal: nobody wins the game
  assert.deepEqual(r.data.wins, {1: 1, 2: 1});
  assert.equal(r.data.scores.find(s => s.player === 1 && s.game === 'block').best, 500);
  assert.equal((await score(0, 'chess', 5)).status, 400);
  assert.equal((await score(0, 'block', -1)).status, 400);
  assert.equal((await call('/weekly', undefined, 0)).data.me, 1);
});

test('scores without a round, or made before it started, are ignored', async () => {
  at(START - 500);
  const {score, start} = await setup();
  let r = await score(0, 'block', 900);
  assert.equal(r.data.ignored, true);
  at(START);
  await start();
  at(START + 60);
  r = await score(0, 'block', 900, START - 100);     // played offline before the round
  assert.equal(r.data.ignored, true);
  assert.deepEqual(r.data.scores, []);
  r = await score(0, 'block', 700, START + 30);
  assert.equal(r.data.scores[0].best, 700);
});

test('overtaking notifies the other player once per lead change', async () => {
  at(START);
  const {score, start, notifications} = await setup();
  await start();
  const n0 = notifications().length;
  await score(0, 'subway', 100);
  assert.equal(notifications().length, n0);      // first score: nobody to overtake
  await score(1, 'subway', 150);
  let n = notifications().slice(n0);
  assert.equal(n.length, 1);
  assert.equal(n[0].player_id, 1);
  assert.equal(n[0].title, 'Meydan okuma ⚔️');
  assert.match(n[0].body, /^ari bu turda Subway Silly skorunu geçti: 150\. Durum 0-1\.$/);
  await score(1, 'subway', 200);                 // already ahead
  assert.equal(notifications().length, n0 + 1);
  await score(0, 'tower', 9);
  await score(1, 'tower', 5);
  await score(1, 'tower', 10);
  n = notifications().slice(n0);
  assert.equal(n.length, 2);
  assert.match(n[1].body, /Adliye Kulesi skorunu geçti: 10 kat\. Durum 0-2\./);
});

test('no second notification right after an all-time "Lider değişti"', async () => {
  // Real clock: the notification's `created` comes from SQLite.
  const {call, score, start, notifications} = await setup();
  await start();
  await call('/score', {game: 'flappy', score: 10}, 0);
  await score(0, 'flappy', 10);
  await call('/score', {game: 'flappy', score: 20}, 1);
  await score(1, 'flappy', 20);
  assert.deepEqual(notifications().filter(n => n.player_id === 1).map(n => n.title), ['Lider değişti! 🏆']);
});

test('the round ends with a winner, a trophy, a result push and a history entry', async () => {
  at(START);
  const {call, score, start, notifications} = await setup();
  await start();
  await score(0, 'block', 500);
  await score(1, 'block', 100);
  await score(0, 'flappy', 5);
  await score(1, 'tower', 8);
  at(END - 1);
  assert.equal((await call('/weekly')).data.round.id, 1);
  at(END + 5);
  let r = await call('/weekly');
  assert.equal(r.data.round, null);
  assert.equal(r.data.canStart, true);
  assert.equal(r.data.nextTrophy, 1);
  assert.deepEqual(r.data.scores, []);
  assert.deepEqual(r.data.totals, {1: 1, 2: 0});
  assert.deepEqual(r.data.reveal, {id: 1, start: START, end: END, winner: 1, wins: {1: 2, 2: 1}, coin: false, trophy: 0,
    detail: [{game: 'block', s1: 500, s2: 100}, {game: 'flappy', s1: 5, s2: 0}, {game: 'subway', s1: 0, s2: 0},
      {game: 'tower', s1: 0, s2: 8}]});
  assert.equal(r.data.history.length, 1);
  const n = notifications().filter(x => x.title === 'Meydan okuma bitti! 🏆');
  assert.deepEqual(n.map(x => [x.player_id, x.body]), [[1, 'Turu 2-1 kazandın, Altın Kupa senin!'],
    [2, 'mqcan turu 2-1 kazandı ve Altın Kupa onun oldu. Rövanş yeni turda!']]);
  // A late score does not reopen it. Seen by one player only.
  assert.equal((await score(1, 'subway', 999, END - 10)).data.ignored, true);
  r = await call('/weekly/seen', {round: 1});
  assert.equal(r.data.reveal, null);
  assert.equal((await call('/weekly', undefined, 1)).data.reveal.id, 1);
  // The next round gets the next trophy.
  r = await call('/weekly/start', {});
  assert.equal(r.data.round.trophy, 1);
  assert.equal(r.data.round.id, 2);
});

test('a tie is decided by a coin flip; an empty round has no winner', async () => {
  at(START);
  const {env, score, start, db, call, notifications} = await setup();
  await start();
  await score(0, 'block', 500);
  await score(1, 'tower', 8);
  await finalize(env, END - 1, () => 1);                 // not over yet
  assert.equal(db.prepare('SELECT decided FROM weekly_rounds WHERE id = 1').get().decided, null);
  await finalize(env, END, () => 1);
  await finalize(env, END, () => 0);                     // already decided
  const row = db.prepare('SELECT winner, coin, wins1, wins2 FROM weekly_rounds WHERE id = 1').get();
  assert.deepEqual({...row}, {winner: 2, coin: 1, wins1: 1, wins2: 1});
  assert.match(notifications().at(-1).body, /^1-1 berabere bitti\. Altın Kupa için yazı tura atıldı/);
  at(END + 60);
  await start();
  const before = notifications().length;
  at(END + 60 + ROUND_LENGTH + 1);
  const r = await call('/weekly');
  assert.equal(r.data.reveal.id, 1);                      // the empty round reveals nothing new
  assert.equal(db.prepare('SELECT winner FROM weekly_rounds WHERE id = 2').get().winner, null);
  assert.equal(notifications().length, before);
  assert.deepEqual(r.data.totals, {1: 0, 2: 1});
  assert.equal(r.data.nextTrophy, 2);
  assert.deepEqual(standing([]).wins, {1: 0, 2: 0});
});

test('the last-four-hours reminder goes out once', async () => {
  at(START);
  const {env, score, start, notifications} = await setup();
  await start();
  await score(0, 'block', 500);
  await score(1, 'block', 100);
  await score(1, 'tower', 3);
  await score(0, 'flappy', 4);
  const n0 = notifications().length;
  await weeklyTick(env, END - 4 * 3600 - 60);
  assert.equal(notifications().length, n0);
  await weeklyTick(env, END - 4 * 3600 + 30);
  await weeklyTick(env, END - 3600);
  const n = notifications().slice(n0);
  assert.equal(n.length, 2);
  assert.equal(n[0].title, 'Meydan okuma: son 4 saat ⏳');
  assert.match(n[0].body, /^2-1 öndesin\. ari yetişmeden/);
  assert.match(n[1].body, /^1-2 geridesin\. Altın Kupa için son şans!$/);
  await weeklyTick(env, END + 1);
  assert.equal(notifications().slice(n0).length, 4);      // + the two result pushes
});

test('the admin can cancel a running round', async () => {
  at(START);
  const {call, score, start} = await setup();
  await start();
  await score(0, 'block', 500);
  assert.equal((await call('/weekly/cancel', {}, 1)).status, 403);
  const r = await call('/weekly/cancel', {});
  assert.equal(r.data.round, null);
  assert.deepEqual(r.data.history, []);
  assert.equal((await call('/weekly/cancel', {})).status, 409);
});

test('weekly needs a player code', async () => {
  const {env} = await setup();
  const response = await worker.fetch(new Request('https://worker.example/weekly', {headers: {Origin: env.APP_ORIGIN}}), env, {waitUntil() {}});
  assert.equal(response.status, 401);
});
