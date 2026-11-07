import {test, afterEach} from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import worker, {tokenHash} from '../src/worker.js';

const tokens = ['a'.repeat(43), 'b'.repeat(43)];
const realFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = realFetch; });

// Black Mirror (TMDB 42009): season 3 in Turkish has an untranslated
// placeholder name ("Bölüm 1") and an empty overview for episode 1.
const SEASON3 = {
  'tr-TR': [{id: 1200001, episode_number: 1, name: 'Bölüm 1', overview: '', runtime: 63, air_date: '2016-10-21',
    still_path: '/nose.jpg', vote_average: 7.9}, {id: 1200002, episode_number: 2, name: 'Oyun Testi',
    overview: 'Bir oyun testi.', runtime: 57, air_date: '2016-10-21', still_path: 'bad path', vote_average: 7.6}],
  'en-US': [{id: 1200001, episode_number: 1, name: 'Nosedive', overview: 'Ratings rule.'},
    {id: 1200002, episode_number: 2, name: 'Playtest', overview: 'A game test.'}],
};
function tvReply(url) {
  const path = url.pathname;
  if (path === '/3/search/tv') return [{results: /black/i.test(url.searchParams.get('query'))
    ? [{id: 42009, name: 'Black Mirror', original_name: 'Black Mirror', first_air_date: '2011-12-04', poster_path: '/bm.jpg',
      vote_average: 8.3, vote_count: 5000}] : []}];
  if (path === '/3/tv/42009') return [{id: 42009, name: 'Black Mirror', original_name: 'Black Mirror',
    first_air_date: '2011-12-04', poster_path: '/bm.jpg', genres: [{name: 'Bilim-Kurgu'}, {name: 'Dram'}],
    seasons: [{season_number: 0, name: 'Özel Bölümler', episode_count: 1, air_date: '2014-12-16'},
      {season_number: 3, name: 'Sezon 3', episode_count: 6, air_date: '2016-10-21', poster_path: '/s3.jpg'},
      {season_number: 1, name: 'Sezon 1', episode_count: 3, air_date: '2011-12-04'}],
    'watch/providers': {results: {TR: {flatrate: [{provider_name: 'Netflix', logo_path: '/nf.jpg'}]}}}}];
  if (path === '/3/tv/42009/season/3') return [{poster_path: '/s3.jpg', episodes: SEASON3[url.searchParams.get('language')]}];
  if (path === '/3/tv/42009/season/3/episode/1/external_ids') return [{imdb_id: 'tt5497778'}];
  if (path === '/3/tv/42009/season/3/episode/2/external_ids') return [{imdb_id: null}];
  if (path.startsWith('/3/tv/')) return [{}, 404];
  return null;
}

// Fake TMDB/OMDb: records every upstream URL and answers from small fixtures.
function upstream({tmdbDown = false} = {}) {
  const urls = [];
  globalThis.fetch = async (input) => {
    const url = new URL(String(input));
    urls.push(url);
    const reply = (data, status = 200) => new Response(JSON.stringify(data), {status});
    if (url.hostname === 'www.omdbapi.com') return reply({imdbRating: {tt1375666: '8.8', tt5497778: '8.3'}[url.searchParams.get('i')] || 'N/A'});
    if (tmdbDown) return reply({status_message: 'down'}, 503);
    const tv = tvReply(url);
    if (tv) return reply(...tv);
    // Each language ranks differently, like TMDB: the 2019 "Parasite" only
    // comes up in the English search.
    if (url.pathname === '/3/search/movie') return reply({results: url.searchParams.get('language') === 'tr-TR' ? [
      {id: 99, title: 'Kötü <b>', original_title: 'Bad', release_date: '', poster_path: 'javascript:alert(1)', vote_average: 0, vote_count: 5},
      {id: 1982, title: 'Parasite', original_title: 'Parasite', release_date: '1982-03-12', vote_count: 91},
      {id: 27205, title: 'Başlangıç', original_title: 'Inception', release_date: '2010-07-15', poster_path: '/inc.jpg', vote_average: 8.369, vote_count: 30000},
      {id: 129, title: 'Ruhların Kaçışı', original_title: '千と千尋の神隠し', release_date: '2001-07-20', vote_count: 19189},
    ] : [
      {id: 496243, title: 'Parasite', original_title: '기생충', release_date: '2019-05-30', vote_count: 21647},
      {id: 1982, title: 'Parasite', original_title: 'Parasite', release_date: '1982-03-12', vote_count: 91},
      {id: 27205, title: 'Inception', original_title: 'Inception', release_date: '2010-07-15', poster_path: '/inc.jpg', vote_average: 8.369, vote_count: 30000},
      {id: 129, title: 'Spirited Away', original_title: '千と千尋の神隠し', release_date: '2001-07-20', vote_count: 19189},
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
  const pending = [];
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
    }), env, {waitUntil(p) { pending.push(p); }});
    return {status: response.status, data: await response.json()};
  }
  const notifications = () => db.prepare('SELECT player_id, title, body, attempted FROM notifications ORDER BY id')
    .all().map(r => ({...r}));
  const settle = () => Promise.all(pending.splice(0));
  return {db, call, notifications, settle};
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
  assert.deepEqual(urls.map(u => [u.pathname, u.searchParams.get('language')]).sort(), [
    ['/3/search/movie', 'en-US'], ['/3/search/movie', 'tr-TR'], ['/3/search/tv', 'en-US'], ['/3/search/tv', 'tr-TR']]);
  assert.deepEqual(r.data.results[0], {kind: 'movie', tmdbId: 27205, title: 'Başlangıç', originalTitle: 'Inception', englishTitle: null,
    year: 2010, poster: '/inc.jpg', tmdbRating: 8.4, inList: false});
  // Unsafe poster paths are dropped; text is returned as plain data.
  const bad = r.data.results.find(x => x.tmdbId === 99);
  assert.equal(bad.poster, null);
  assert.equal(bad.year, null);
  assert.ok(!JSON.stringify(r.data).includes('secret'));
  assert.equal((await call('/films/search', {query: ''})).status, 400);
  assert.equal((await call('/films/search', {query: 'x'.repeat(81)})).status, 400);
  assert.equal((await call('/films/search', {query: 'a\u202eb'})).status, 400);
});

test('Turkish and English results are merged; exact and well-known titles come first', async () => {
  const urls = upstream();
  const {call} = await setup();
  let r = await call('/films/search', {query: 'parasite'});
  assert.deepEqual(r.data.results.slice(0, 2).map(x => [x.tmdbId, x.title, x.year]),
    [[496243, 'Parasite', 2019], [1982, 'Parasite', 1982]]);
  // English names find the film; the Turkish title is shown with the English one.
  r = await call('/films/search', {query: 'Spirited away'});
  assert.deepEqual(r.data.results[0], {kind: 'movie', tmdbId: 129, title: 'Ruhların Kaçışı', originalTitle: '千と千尋の神隠し',
    englishTitle: 'Spirited Away', year: 2001, poster: null, tmdbRating: null, inList: false});
  r = await call('/films/search', {query: 'ruhlarin kacisi'});
  assert.equal(r.data.results[0].tmdbId, 129);
  // A trailing year filters by year.
  urls.length = 0;
  await call('/films/search', {query: 'parasite 2019'});
  assert.deepEqual(urls.map(u => [u.pathname, u.searchParams.get('query'),
    u.searchParams.get('year') || u.searchParams.get('first_air_date_year')]),
    [['/3/search/movie', 'parasite', '2019'], ['/3/search/movie', 'parasite', '2019'],
      ['/3/search/tv', 'parasite', '2019'], ['/3/search/tv', 'parasite', '2019']]);
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
    providers: [{name: 'Netflix', logo: '/nf.jpg'}], addedBy: 2, added: 0, watched: null, watchedBy: null,
    kind: 'movie', showId: null, showTitle: null, season: null, episode: null, still: null});
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

test('a TV show is found by name and lists its seasons, specials last', async () => {
  upstream();
  const {call} = await setup();
  let r = await call('/films/search', {query: 'black mirror'});
  assert.deepEqual(r.data.results[0], {kind: 'tv', tmdbId: 42009, title: 'Black Mirror', originalTitle: 'Black Mirror',
    englishTitle: null, year: 2011, poster: '/bm.jpg', tmdbRating: 8.3, inList: false, listedEpisodes: 0});
  r = await call('/films/show', {tmdbId: 42009});
  assert.equal(r.data.show.title, 'Black Mirror');
  assert.deepEqual(r.data.show.seasons.map(x => [x.season, x.episodes, x.year]), [[1, 3, 2011], [3, 6, 2016], [0, 1, 2014]]);
  assert.equal((await call('/films/show', {tmdbId: 'x'})).status, 400);
  assert.equal((await call('/films/show', {tmdbId: 7})).status, 404);
});

test('a season lists its episodes; untranslated names fall back to English', async () => {
  upstream();
  const {call} = await setup();
  const r = await call('/films/season', {tmdbId: 42009, season: 3});
  assert.equal(r.status, 200);
  assert.deepEqual(r.data.episodes, [
    {episode: 1, title: 'Nosedive', englishTitle: null, overview: 'Ratings rule.', runtime: 63, year: 2016,
      still: '/nose.jpg', tmdbRating: 7.9, inList: false},
    {episode: 2, title: 'Oyun Testi', englishTitle: 'Playtest', overview: 'Bir oyun testi.', runtime: 57, year: 2016,
      still: null, tmdbRating: 7.6, inList: false},
  ]);
  assert.equal((await call('/films/season', {tmdbId: 42009, season: -1})).status, 400);
});

test('episodes are added one by one as their own items, next to films', async () => {
  upstream();
  const {call, notifications} = await setup();
  // A film whose TMDB id equals an episode id does not collide with it.
  await call('/films', {tmdbId: 1200001});
  const r = await call('/films/episodes', {showId: 42009, season: 3, episodes: [1, 2, 2]}, 1);
  assert.equal(r.status, 200);
  assert.equal(r.data.added.length, 2);
  const episodes = r.data.films.filter(f => f.kind === 'episode').sort((a, b) => a.episode - b.episode);
  assert.deepEqual({...episodes[0], id: 0, added: 0}, {id: 0, tmdbId: -1200001, imdbId: 'tt5497778', title: 'Nosedive',
    originalTitle: '', year: 2016, runtime: 63, genres: ['Bilim-Kurgu', 'Dram'], overview: 'Ratings rule.',
    poster: '/s3.jpg', tmdbRating: 7.9, imdbRating: 8.3, providers: [{name: 'Netflix', logo: '/nf.jpg'}], addedBy: 2,
    added: 0, watched: null, watchedBy: null, kind: 'episode', showId: 42009, showTitle: 'Black Mirror', season: 3,
    episode: 1, still: '/nose.jpg'});
  assert.equal(episodes[1].originalTitle, 'Playtest');
  assert.equal(episodes[1].imdbRating, null);
  assert.equal(r.data.films.filter(f => f.kind === 'movie').length, 1);
  assert.deepEqual(notifications().at(-1), {player_id: 1, title: "ari watchlist'e 2 bölüm ekledi! 📺",
    body: 'Black Mirror S3:B1 · Nosedive, Black Mirror S3:B2 · Oyun Testi', attempted: notifications().at(-1).attempted});
  // Already listed episodes are skipped; all listed is a 409.
  const again = await call('/films/episodes', {showId: 42009, season: 3, episodes: [1, 2]});
  assert.equal(again.status, 409);
  assert.equal(again.data.error, 'Bu bölümler zaten listede.');
  assert.deepEqual((await call('/films/season', {tmdbId: 42009, season: 3})).data.episodes.map(e => e.inList), [true, true]);
  assert.equal((await call('/films/search', {query: 'black mirror'})).data.results[0].listedEpisodes, 2);
  // Validation.
  assert.equal((await call('/films/episodes', {showId: 42009, season: 3, episodes: []})).status, 400);
  assert.equal((await call('/films/episodes', {showId: 42009, season: 3,
    episodes: Array.from({length: 11}, (_, i) => i + 1)})).status, 400);
  assert.equal((await call('/films/episodes', {showId: 42009, season: 3, episodes: [9]})).status, 404);
  assert.equal((await call('/films/episodes', {showId: 42009, season: 3, episodes: ['1']})).status, 400);
});

test('watching and rating an episode works like a film', async () => {
  upstream();
  const {call, notifications} = await setup();
  const [id] = (await call('/films/episodes', {showId: 42009, season: 3, episodes: [1]}, 1)).data.added;
  assert.equal(notifications().at(-1).title, "ari watchlist'e bir bölüm ekledi! 📺");
  const early = await call('/films/rate', {id, hearts: 5, comment: ''});
  assert.equal(early.data.error, 'Puan için önce bölümü izlendi olarak işaretle.');
  await call('/films/watched', {id, watched: true});
  assert.equal(notifications().at(-1).title, 'mqcan 😎, Black Mirror S3:B1 bölümünü izlendi olarak işaretledi');
  const r = await call('/films/rate', {id, hearts: 5, comment: 'Ürkütücü'});
  assert.deepEqual(r.data.ratings.map(x => [x.film, x.hearts]), [[id, 5]]);
});

test('a stale episode is refreshed through the episode endpoints', async () => {
  const urls = upstream();
  const {db, call, settle} = await setup();
  const [id] = (await call('/films/episodes', {showId: 42009, season: 3, episodes: [1]})).data.added;
  db.prepare("UPDATE films SET info_updated = 0, title = 'Eski', still = NULL WHERE id = ?").run(id);
  urls.length = 0;
  await call('/films');
  await settle();
  const row = db.prepare('SELECT title, still, kind FROM films WHERE id = ?').get(id);
  assert.deepEqual({...row}, {title: 'Nosedive', still: '/nose.jpg', kind: 'episode'});
  assert.ok(urls.some(u => u.pathname === '/3/tv/42009/season/3'));
  assert.ok(!urls.some(u => u.pathname.startsWith('/3/movie/')));
});
