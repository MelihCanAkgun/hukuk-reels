import {test, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
const realFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = realFetch; });

// Fake TMDB/OMDb: records every upstream URL and answers from small fixtures.
function upstream({tmdbDown = false} = {}) {
  const urls = [];
  globalThis.fetch = async (input) => {
    const url = new URL(String(input));
    urls.push(url);
    const reply = (data, status = 200) => new Response(JSON.stringify(data), {status});
    if (url.hostname === 'www.omdbapi.com') return reply({imdbRating: url.searchParams.get('i') === 'tt1375666' ? '8.8' : 'N/A'});
    if (tmdbDown) return reply({status_message: 'down'}, 503);
    if (url.pathname === '/3/search/movie') return reply({results: [
      {id: 27205, title: 'Başlangıç', original_title: 'Inception', release_date: '2010-07-15', poster_path: '/inc.jpg', vote_average: 8.369},
      {id: 99, title: 'Kötü <b>', original_title: 'Bad', release_date: '', poster_path: 'javascript:alert(1)', vote_average: 0},
    ]});
    const id = Number(url.pathname.split('/').at(-1));
    if (id === 404) return reply({}, 404);
    return reply({
      id, title: id === 27205 ? 'Başlangıç' : `Film ${id}`, original_title: id === 27205 ? 'Inception' : `Movie ${id}`,
      release_date: '2010-07-15', runtime: 148, genres: [{name: 'Aksiyon'}, {name: 'Bilim-Kurgu'}],
      overview: id === 27205 ? 'Rüya içinde rüya.' : '', poster_path: '/p.jpg', vote_average: 8.4,
      imdb_id: id === 27205 ? 'tt1375666' : null,
      'watch/providers': {results: {TR: {flatrate: [{provider_name: 'Netflix', logo_path: '/nf.jpg'}]},
        US: {flatrate: [{provider_name: 'Max', logo_path: '/max.jpg'}]}}},
    });
  };
  return urls;
}

async function setup(extra = {}) {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  for (let i = 0; i < 2; i++) db.prepare('INSERT INTO players(id, token_hash, name, active) VALUES (?, ?, ?, 1)')
    .run(i + 1, await tokenHash(tokens[i]), ['mqcan 😎', 'ari'][i]);
  const env = {APP_ORIGIN: 'https://app.example', APP_URL: 'https://app.example/',
    TMDB_API_KEY: 'tmdb-secret', OMDB_API_KEY: 'omdb-secret', ...extra, DB: {prepare(sql) {
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
  const notifications = () => db.prepare('SELECT player_id, title, body, attempted FROM notifications ORDER BY id')
    .all().map(r => ({...r}));
  return {db, call, notifications};
}

test('films need a player code; the list starts empty', async () => {
  upstream();
  const {call} = await setup();
  assert.equal((await call('/films', undefined, 0, {auth: false})).status, 401);
  assert.equal((await call('/films/search', {query: 'x'}, 0, {auth: false})).status, 401);
  const r = await call('/films');
  assert.equal(r.status, 200);
  assert.deepEqual(r.data.films, []);
  assert.deepEqual(r.data.players.map(p => p.name), ['mqcan 😎', 'ari']);
  assert.equal(r.data.me, 1);
});

test('search goes through the worker with the secret key and sanitizes results', async () => {
  const urls = upstream();
  const {call} = await setup();
  const r = await call('/films/search', {query: '  inception '});
  assert.equal(r.status, 200);
  assert.equal(urls[0].searchParams.get('api_key'), 'tmdb-secret');
  assert.equal(urls[0].searchParams.get('query'), 'inception');
  assert.equal(urls[0].searchParams.get('language'), 'tr-TR');
  assert.deepEqual(r.data.results[0], {tmdbId: 27205, title: 'Başlangıç', originalTitle: 'Inception', year: 2010,
    poster: '/inc.jpg', tmdbRating: 8.4, inList: false});
  // Unsafe poster paths are dropped; text is returned as plain data.
  assert.equal(r.data.results[1].poster, null);
  assert.equal(r.data.results[1].year, null);
  assert.ok(!JSON.stringify(r.data).includes('secret'));
  assert.equal((await call('/films/search', {query: ''})).status, 400);
  assert.equal((await call('/films/search', {query: 'x'.repeat(81)})).status, 400);
  assert.equal((await call('/films/search', {query: 'a\u202eb'})).status, 400);
});

test('adding a film stores TMDB details, the IMDb rating and TR providers, once', async () => {
  upstream();
  const {call, notifications} = await setup();
  const r = await call('/films', {tmdbId: 27205}, 1);
  assert.equal(r.status, 200);
  const [film] = r.data.films;
  assert.equal(r.data.added, film.id);
  assert.deepEqual({...film, id: 0, added: 0}, {id: 0, tmdbId: 27205, imdbId: 'tt1375666', title: 'Başlangıç',
    originalTitle: 'Inception', year: 2010, runtime: 148, genres: ['Aksiyon', 'Bilim-Kurgu'],
    overview: 'Rüya içinde rüya.', poster: '/p.jpg', tmdbRating: 8.4, imdbRating: 8.8,
    providers: [{name: 'Netflix', logo: '/nf.jpg'}], addedBy: 2, added: 0, watched: null, watchedBy: null});
  assert.deepEqual(notifications().map(n => [n.player_id, n.title, n.body]),
    [[1, "ari watchlist'e bir film ekledi! 🎬", 'Başlangıç']]);
  const again = await call('/films', {tmdbId: 27205});
  assert.equal(again.status, 409);
  assert.equal(again.data.error, 'Bu film zaten listede.');
  assert.equal((await call('/films/search', {query: 'inception'})).data.results[0].inList, true);
  assert.equal((await call('/films', {tmdbId: 404})).status, 404);
  assert.equal((await call('/films', {tmdbId: '27205'})).status, 400);
});

test('more additions within ten minutes are collected into one delayed notification', async () => {
  upstream();
  const {db, call, notifications} = await setup();
  await call('/films', {tmdbId: 1});
  await call('/films', {tmdbId: 2});
  await call('/films', {tmdbId: 3});
  const rows = notifications();
  assert.equal(rows.length, 2);
  assert.equal(rows[0].title, "mqcan 😎 watchlist'e bir film ekledi! 🎬");
  assert.equal(rows[1].title, "mqcan 😎 watchlist'e 2 film daha ekledi! 🎬");
  assert.equal(rows[1].body, 'Film 2, Film 3');
  const {notified} = db.prepare('SELECT notified FROM film_digest WHERE player_id = 1').get();
  // Due when the window ends (the queue takes rows attempted > 2 minutes ago).
  assert.equal(rows[1].attempted, notified + 480);
  // After the window a new addition notifies at once again.
  db.prepare('UPDATE film_digest SET notified = notified - 600').run();
  await call('/films', {tmdbId: 4});
  assert.equal(notifications().at(-1).title, "mqcan 😎 watchlist'e bir film ekledi! 🎬");
  assert.equal(notifications().at(-1).body, 'Film 4');
});

test('watched notifies once, can be undone, and both players rate separately', async () => {
  upstream();
  const {call, notifications} = await setup();
  const id = (await call('/films', {tmdbId: 27205}, 1)).data.added;
  assert.equal((await call('/films/rate', {id, hearts: 5, comment: ''})).status, 400);
  let r = await call('/films/watched', {id, watched: true});
  assert.equal(r.status, 200);
  assert.equal(r.data.films[0].watchedBy, 1);
  assert.ok(r.data.films[0].watched > 0);
  assert.deepEqual(notifications().at(-1).title, 'mqcan 😎, Başlangıç filmini izlendi olarak işaretledi');
  await call('/films/watched', {id, watched: false});
  r = await call('/films/watched', {id, watched: true}, 1);
  assert.equal(notifications().length, 2, 'undo/redo must not notify again');
  assert.equal((await call('/films/rate', {id, hearts: 6})).status, 400);
  assert.equal((await call('/films/rate', {id, hearts: 4, comment: 'x'.repeat(141)})).status, 400);
  await call('/films/rate', {id, hearts: 5, comment: '  Harikaydı  '});
  r = await call('/films/rate', {id, hearts: 3, comment: 'Uzundu'}, 1);
  assert.deepEqual(r.data.ratings.map(x => [x.player, x.hearts, x.comment]).sort(),
    [[1, 5, 'Harikaydı'], [2, 3, 'Uzundu']]);
  r = await call('/films/rate', {id, hearts: 4, comment: ''}, 1);
  assert.deepEqual(r.data.ratings.find(x => x.player === 2).hearts, 4);
  r = await call('/films/delete', {id});
  assert.deepEqual(r.data.films, []);
  assert.deepEqual(r.data.ratings, []);
  assert.equal((await call('/films/watched', {id, watched: true})).status, 404);
});

test('missing OMDb key leaves the IMDb rating empty; TMDB errors never leak the key', async () => {
  upstream();
  const {call} = await setup({OMDB_API_KEY: undefined});
  const r = await call('/films', {tmdbId: 27205});
  assert.equal(r.data.films[0].imdbRating, null);
  upstream({tmdbDown: true});
  const down = await call('/films/search', {query: 'x'});
  assert.equal(down.status, 502);
  assert.ok(!JSON.stringify(down.data).includes('secret'));
  const {call: noKey} = await setup({TMDB_API_KEY: undefined});
  assert.equal((await noKey('/films/search', {query: 'x'})).status, 503);
});

test('an empty Turkish overview falls back to English', async () => {
  const urls = upstream();
  const {call} = await setup();
  const r = await call('/films', {tmdbId: 7});
  assert.equal(r.data.films[0].overview, '');
  assert.ok(urls.some(u => u.searchParams.get('language') === 'en-US'));
});
