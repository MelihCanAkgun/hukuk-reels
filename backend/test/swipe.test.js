import {test, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
const realFetch = globalThis.fetch, realNow = Date.now;
afterEach(() => { globalThis.fetch = realFetch; Date.now = realNow; });

// Fake TMDB: recommendations and trending return films 9001.., details any id.
function upstream({down = false} = {}) {
  const urls = [];
  globalThis.fetch = async (input) => {
    const url = new URL(String(input));
    urls.push(url);
    const reply = (data, status = 200) => new Response(JSON.stringify(data), {status});
    if (url.hostname === 'www.omdbapi.com') return reply({imdbRating: 'N/A'});
    if (down) return reply({}, 503);
    const item = (id, extra = {}) => ({id, title: `Öneri ${id}`, original_title: `Pick ${id}`, overview: 'Özet.',
      poster_path: `/s${id}.jpg`, release_date: '2020-01-01', vote_average: 7.5, vote_count: 900, genre_ids: [18, 53], ...extra});
    if (url.pathname.endsWith('/recommendations')) return reply({results: [
      item(9001), item(9002), item(1001) /* already listed */, item(9003, {vote_average: 5.1}), item(9004, {vote_count: 12}),
      item(9005, {poster_path: null}), item(9006, {adult: true})]});
    if (url.pathname === '/3/trending/movie/week') return reply({results: [9001, 9010, 9011, 9012, 9013, 9014, 9015].map(i => item(i))});
    const id = Number(url.pathname.split('/').at(-1));
    return reply({id, title: `Öneri ${id}`, original_title: `Pick ${id}`, release_date: '2020-01-01', runtime: 101,
      genres: [{name: 'Dram'}], overview: 'Uzun özet.', poster_path: `/s${id}.jpg`, vote_average: 7.5, imdb_id: null});
  };
  return urls;
}

async function setup({films = 12} = {}) {
  const pending = [];
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i = 0; i < 2; i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i + 1, await tokenHash(tokens[i]), ['mqcan', 'ari'][i]);
  for (let i = 1; i <= films; i++) db.prepare(`INSERT INTO films(tmdb_id, title, added_by, added, info_updated, watched)
    VALUES (?, ?, 1, 1, 1, ?)`).run(1000 + i, `Film ${i}`, i === 1 ? 5 : null);       // film 1 is watched
  const env = {APP_ORIGIN: 'https://app.example', APP_URL: 'https://app.example/', TMDB_API_KEY: 'tmdb-secret',
    DB: {prepare(sql) {
      let args = [];
      const stmt = db.prepare(sql);
      return {bind(...v) { args = v; return this; }, async first() { return stmt.get(...args) || null; },
        async all() { return {results: stmt.all(...args)}; }, async run() { return stmt.run(...args); }};
    }}};
  async function call(path, data = {}, id = 0) {
    const response = await worker.fetch(new Request('https://worker.example' + path, {
      method: data === null ? 'GET' : 'POST', headers: {Origin: env.APP_ORIGIN, Authorization: 'Bearer ' + tokens[id]},
      ...(data === null ? {} : {body: JSON.stringify(data)}),
    }), env, {waitUntil(p) { pending.push(p.catch(() => {})); }});
    return {status: response.status, data: await response.json()};
  }
  const notifications = () => db.prepare('SELECT player_id, title, body FROM notifications ORDER BY id').all().map(r => ({...r}));
  // Votes every card: `likes` positions get 1, `superPos` gets 2, the rest 0.
  async function swipeAll(id, session, likes, superPos = null) {
    let last;
    for (const c of session.cards) {
      last = await call('/films/swipe/vote', {session: session.id, pos: c.pos,
        vote: c.pos === superPos ? 2 : likes.includes(c.pos) ? 1 : 0}, id);
      assert.equal(last.status, 200);
    }
    return last;
  }
  return {db, call, notifications, swipeAll};
}

test('a session is a short deck: 10 unwatched list films and 5 suggestions', async () => {
  const urls = upstream();
  const {call, notifications} = await setup();
  assert.equal((await call('/films/swipe')).data.session, null);
  const r = await call('/films/swipe/start');
  assert.equal(r.status, 200);
  const s = r.data.session;
  assert.equal(s.total, 15);
  assert.equal(s.status, 'open');
  assert.equal(s.startedBy, 1);
  assert.deepEqual(s.cards.map(c => c.pos), [...Array(15).keys()]);
  const listed = s.cards.filter(c => !c.suggested), extra = s.cards.filter(c => c.suggested);
  assert.equal(listed.length, 10);
  assert.equal(extra.length, 5);
  assert.ok(listed.every(c => c.filmId && c.title !== 'Film 1'));        // never a watched film
  // Suggestions: not in the list, rated, voted, with a poster, no adult titles.
  assert.ok(extra.every(c => c.filmId === null && ![1001, 9003, 9004, 9005, 9006].includes(c.tmdbId)));
  assert.deepEqual(extra[0].genres, ['Dram', 'Gerilim']);
  assert.ok(urls.every(u => u.searchParams.get('api_key') === 'tmdb-secret'));
  assert.ok(!JSON.stringify(r.data).includes('secret'));
  assert.deepEqual(notifications(), [{player_id: 2, title: 'mqcan film seçimi başlattı! 🍿',
    body: '15 film arasından beğendiklerini seç, eşleşenleri birlikte görün.'}]);
  // One at a time.
  assert.equal((await call('/films/swipe/start', {}, 1)).status, 409);
  // The film list reply carries a summary for the banner.
  const list = await call('/films', null, 1);
  assert.deepEqual(list.data.swipe, {id: s.id, status: 'open', startedBy: 1, created: s.created, total: 15, mine: 0, otherDone: false});
});

test('a short list gets more suggestions; TMDB down still works with the list', async () => {
  upstream();
  let t = await setup({films: 4});            // 3 unwatched
  let s = (await t.call('/films/swipe/start')).data.session;
  assert.equal(s.cards.filter(c => !c.suggested).length, 3);
  assert.ok(s.cards.filter(c => c.suggested).length >= 5);
  assert.ok(s.total <= 15);
  upstream({down: true});
  t = await setup({films: 6});
  s = (await t.call('/films/swipe/start')).data.session;
  assert.equal(s.total, 5);
  t = await setup({films: 2});
  assert.equal((await t.call('/films/swipe/start')).status, 400);
});

test('votes stay hidden until both are done; matches are ranked by super likes', async () => {
  upstream();
  const {call, swipeAll, notifications, db} = await setup();
  const s = (await call('/films/swipe/start')).data.session;
  const sug = s.cards.find(c => c.suggested).pos;
  const listed = s.cards.filter(c => !c.suggested).map(c => c.pos);
  let r = await swipeAll(0, s, [listed[0], listed[1], sug], listed[1]);
  assert.equal(r.data.session.status, 'open');
  assert.equal(r.data.session.matches, null);
  assert.equal(r.data.session.superUsed, true);
  assert.equal(r.data.session.otherDone, false);
  // Player 2 sees only their own (empty) votes.
  r = await call('/films/swipe', {}, 1);
  assert.deepEqual(r.data.session.votes, {});
  assert.equal(r.data.session.otherDone, true);
  assert.equal(r.data.session.matches, null);
  // One super like per player.
  await call('/films/swipe/vote', {session: s.id, pos: listed[3], vote: 2}, 1);
  assert.equal((await call('/films/swipe/vote', {session: s.id, pos: listed[4], vote: 2}, 1)).status, 409);
  assert.equal((await call('/films/swipe/vote', {session: s.id, pos: 99, vote: 1}, 1)).status, 400);
  assert.equal((await call('/films/swipe/vote', {session: s.id, pos: 0, vote: 3}, 1)).status, 400);
  r = await swipeAll(1, s, [listed[0], listed[1], listed[2], sug]);
  const done = r.data.session;
  assert.equal(done.status, 'done');
  assert.deepEqual(done.matches.map(m => m.pos), [listed[1], ...[listed[0], sug].sort((a, b) =>
    (done.matches.find(m => m.pos === b).tmdbRating ?? 0) - (done.matches.find(m => m.pos === a).tmdbRating ?? 0) || a - b)]);
  assert.deepEqual(done.matches[0].supers, [1]);
  // The matched suggestion joined the watchlist (without an "ekledi" push).
  const added = done.matches.find(m => m.pos === sug);
  assert.ok(added.filmId);
  assert.equal(db.prepare('SELECT runtime FROM films WHERE id = ?').get(added.filmId).runtime, 101);
  const n = notifications();
  assert.equal(n.length, 2);
  assert.deepEqual({player_id: n[1].player_id, title: n[1].title}, {player_id: 1, title: '3 filmde eşleştiniz! 🎉'});
  assert.match(n[1].body, /^İkiniz de beğendi: /);
  // Finished: no more votes; a new session may start after the cooldown.
  assert.equal((await call('/films/swipe/vote', {session: s.id, pos: 0, vote: 1})).status, 409);
  assert.equal((await call('/films/swipe/start')).status, 429);
  const later = Date.now() + 120000;
  Date.now = () => later;
  assert.equal((await call('/films/swipe/start', {}, 1)).data.session.startedBy, 2);
});

test('no match, the late "sıra sende" nudge and cancel', async () => {
  upstream();
  const {call, swipeAll, notifications} = await setup();
  let s = (await call('/films/swipe/start')).data.session;
  const start = Date.now();
  Date.now = () => start + 3600000;
  await swipeAll(0, s, [0]);
  let n = notifications();
  assert.deepEqual({player_id: n[1].player_id, title: n[1].title}, {player_id: 2, title: 'mqcan seçimini yaptı, sıra sende ⏳'});
  await call('/films/swipe/vote', {session: s.id, pos: 0, vote: 1});          // changing a vote does not nudge again
  assert.equal(notifications().length, 2);
  const r = await swipeAll(1, s, [1]);
  assert.deepEqual(r.data.session.matches, []);
  n = notifications();
  assert.equal(n[2].title, 'Bu sefer eşleşme çıkmadı 😅');
  assert.equal(n[2].player_id, 1);
  s = (await call('/films/swipe/start')).data.session;
  assert.equal((await call('/films/swipe/cancel', {session: s.id}, 1)).status, 200);
  // After a cancel the last finished session is shown again.
  assert.equal((await call('/films/swipe')).data.session.status, 'done');
  assert.equal((await call('/films/swipe/vote', {session: s.id, pos: 0, vote: 1})).status, 409);
});

test('swipe needs a player code', async () => {
  const {call} = await setup();
  const response = await worker.fetch(new Request('https://worker.example/films/swipe', {method: 'POST', body: '{}',
    headers: {Origin: 'https://app.example'}}), {APP_ORIGIN: 'https://app.example'}, {waitUntil() {}});
  assert.equal(response.status, 401);
  assert.equal((await call('/films/swipe', null)).status, 404);
});
