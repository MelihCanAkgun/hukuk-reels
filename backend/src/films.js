// Shared watchlist ("İzle" tab): films and single TV episodes (each Black
// Mirror episode is its own item). The Worker proxies TMDB (search, Turkish
// title, poster, rating, TR streaming providers) and OMDb (IMDb rating); the
// API keys never leave the Worker secrets. Letterboxd has no API, so the app
// only links to letterboxd.com/tmdb/<id> (films only: Letterboxd has no TV).
const TMDB = 'https://api.themoviedb.org/3';
const OMDB = 'https://www.omdbapi.com/';
// Details and ratings change slowly: one stale film is refreshed per list load.
const REFRESH_AFTER = 7 * 86400;
// Additions within this window share one (delayed) notification.
const DIGEST_WINDOW = 600;
const MAX_FILMS = 400;
// Episodes added in one request (each costs two upstream calls).
const MAX_EPISODES = 10;
// Replies under the two reviews of one film.
const MAX_REPLIES = 200;
const MAX_REPLY = 280;
const HIDDEN = /[\x00-\x1f\x7f-\x9f\u200b-\u200f\u2028-\u202e\u2060-\u2069\ufeff]/;

const fail = (message, status = 400) => { throw Object.assign(new Error(message), {status}); };
const nowSec = () => Math.floor(Date.now() / 1000);
const clip = (value, max) => String(value ?? '').trim().slice(0, max);
// Poster and logo paths are joined to image.tmdb.org on the client.
const imagePath = p => typeof p === 'string' && /^\/[A-Za-z0-9_-]{1,80}\.(jpg|png|svg)$/.test(p) ? p : null;
const yearOf = date => /^\d{4}/.test(date || '') ? Number(date.slice(0, 4)) : null;
const rating = v => Number.isFinite(v) && v > 0 && v <= 10 ? Math.round(v * 10) / 10 : null;

async function upstream(url, service) {
  let response;
  try {
    response = await fetch(url, {headers: {Accept: 'application/json'}, redirect: 'manual',
      signal: AbortSignal.timeout(8000)});
  } catch (error) {
    // Never log the URL: it carries the API key.
    console.warn('film_upstream_failed', {service, type: error.name});
    fail('Film servisine ulaşılamadı. Biraz sonra tekrar dene.', 502);
  }
  if (!response.ok) {
    await response.body?.cancel();
    console.warn('film_upstream_rejected', {service, status: response.status});
    fail(response.status === 404 ? 'Film ya da dizi bulunamadı.' : 'Film servisine ulaşılamadı. Biraz sonra tekrar dene.',
      response.status === 404 ? 404 : 502);
  }
  return response.json();
}

function tmdb(env, path, params) {
  if (!env.TMDB_API_KEY) fail('Film servisi henüz etkin değil.', 503);
  const url = new URL(TMDB + path);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  url.searchParams.set('api_key', env.TMDB_API_KEY);
  return upstream(url, 'tmdb');
}

// IMDb rating is optional: a missing key or an OMDb error leaves it empty.
async function imdbRating(env, imdbId) {
  if (!imdbId || !env.OMDB_API_KEY) return null;
  try {
    const url = new URL(OMDB);
    url.searchParams.set('i', imdbId);
    url.searchParams.set('apikey', env.OMDB_API_KEY);
    const data = await upstream(url, 'omdb');
    return rating(Number.parseFloat(data.imdbRating));
  } catch {
    return null;
  }
}

export async function filmDetails(env, tmdbId) {
  const m = await tmdb(env, `/movie/${tmdbId}`, {language: 'tr-TR', append_to_response: 'external_ids,watch/providers'});
  let overview = clip(m.overview, 1200);
  if (!overview) {
    try { overview = clip((await tmdb(env, `/movie/${tmdbId}`, {language: 'en-US'})).overview, 1200); } catch {}
  }
  const imdbId = [m.imdb_id, m.external_ids?.imdb_id].find(id => /^tt\d{5,10}$/.test(id || '')) || null;
  return {
    imdbId,
    title: clip(m.title || m.original_title, 120) || 'Adsız film',
    originalTitle: clip(m.original_title, 120),
    year: yearOf(m.release_date),
    runtime: Number.isSafeInteger(m.runtime) && m.runtime > 0 ? m.runtime : null,
    genres: (m.genres || []).map(g => clip(g.name, 30)).filter(Boolean).slice(0, 4),
    overview,
    poster: imagePath(m.poster_path),
    tmdbRating: rating(m.vote_average),
    imdbRating: await imdbRating(env, imdbId),
    providers: providersOf(m),
  };
}

const providersOf = m => (m['watch/providers']?.results?.TR?.flatrate || []).slice(0, 6)
  .map(p => ({name: clip(p.provider_name, 40), logo: imagePath(p.logo_path)})).filter(p => p.name);
const positive = v => Number.isSafeInteger(v) && v > 0 ? v : null;
// TMDB fills untranslated episode names with "Bölüm 3"; the English name is better.
const placeholder = name => /^(bölüm|episode)\s*\d+$/i.test(String(name || '').trim());

async function showInfo(env, showId) {
  const s = await tmdb(env, `/tv/${showId}`, {language: 'tr-TR', append_to_response: 'watch/providers'});
  return {
    title: clip(s.name || s.original_name, 120) || 'Adsız dizi',
    originalTitle: clip(s.original_name, 120),
    year: yearOf(s.first_air_date),
    poster: imagePath(s.poster_path),
    genres: (s.genres || []).map(g => clip(g.name, 30)).filter(Boolean).slice(0, 4),
    providers: providersOf(s),
    seasons: (s.seasons || []).filter(x => Number.isSafeInteger(x.season_number) && x.season_number >= 0
      && positive(x.episode_count)).map(x => ({season: x.season_number, name: clip(x.name, 60),
      episodes: x.episode_count, year: yearOf(x.air_date), poster: imagePath(x.poster_path)}))
      // Specials (season 0) go last.
      .sort((a, b) => (a.season || 1e9) - (b.season || 1e9)),
  };
}

// One season in Turkish with English names/overviews as the fallback.
async function seasonEpisodes(env, showId, season) {
  const [tr, en] = await Promise.allSettled([
    tmdb(env, `/tv/${showId}/season/${season}`, {language: 'tr-TR'}),
    tmdb(env, `/tv/${showId}/season/${season}`, {language: 'en-US'}),
  ]);
  if (tr.status === 'rejected') throw tr.reason;
  const english = new Map((en.status === 'fulfilled' ? en.value.episodes || [] : []).map(e => [e.episode_number, e]));
  return {
    poster: imagePath(tr.value.poster_path),
    episodes: (tr.value.episodes || []).filter(e => positive(e.id) && positive(e.episode_number)).map(e => {
      const eng = english.get(e.episode_number) || {};
      const name = clip(placeholder(e.name) ? eng.name || e.name : e.name, 120);
      const englishName = clip(eng.name, 120);
      return {
        id: e.id, episode: e.episode_number, title: name || `Bölüm ${e.episode_number}`,
        englishTitle: englishName && englishName !== name && !placeholder(englishName) ? englishName : null,
        overview: clip(e.overview, 1200) || clip(eng.overview, 1200),
        runtime: positive(e.runtime), year: yearOf(e.air_date), still: imagePath(e.still_path),
        tmdbRating: rating(e.vote_average),
      };
    }),
  };
}

// Details for one or more episodes of one season, shaped like filmDetails.
export async function episodeDetails(env, showId, season, numbers) {
  const [show, s] = await Promise.all([showInfo(env, showId), seasonEpisodes(env, showId, season)]);
  return Promise.all(numbers.map(async n => {
    const e = s.episodes.find(x => x.episode === n) || fail('Bölüm bulunamadı.', 404);
    let imdbId = null;
    try {
      const ids = await tmdb(env, `/tv/${showId}/season/${season}/episode/${n}/external_ids`, {});
      imdbId = /^tt\d{5,10}$/.test(ids.imdb_id || '') ? ids.imdb_id : null;
    } catch {}
    return {
      tmdbId: -e.id, imdbId, title: e.title, originalTitle: e.englishTitle || '', year: e.year, runtime: e.runtime,
      genres: show.genres, overview: e.overview, poster: s.poster || show.poster, still: e.still,
      tmdbRating: e.tmdbRating, imdbRating: await imdbRating(env, imdbId), providers: show.providers,
      showId, showTitle: show.title, season, episode: n,
    };
  }));
}

// Comparison key for titles: case, accents, dotted/dotless i and punctuation
// are ignored ("Amélie" == "amelie", "Ruhların Kaçışı" == "ruhlarin kacisi").
const titleKey = t => String(t || '').normalize('NFKD').replace(/\p{M}/gu, '')
  .replace(/[İIı]/g, 'i').toLowerCase().replace(/[^\p{L}\p{N}]/gu, '');

// Turkish and English searches run together: TMDB ranks a query best in the
// language it is written in ("Parasite" in tr-TR puts the 1982 film first).
// Results are merged and ranked: exact title match (Turkish, English or
// original), then prefix match, then the rest; well-known films (more votes)
// first within each group. A trailing year ("parasite 2019") filters by year.
async function search(env, raw) {
  const m = raw.match(/^(.*\S)\s+((?:19|20)\d{2})$/);
  const query = m ? m[1] : raw;
  const params = {query, include_adult: 'false', page: '1'};
  // TV shows are searched too (a show is opened to pick episodes).
  const kinds = [['movie', 'tr-TR'], ['movie', 'en-US'], ['tv', 'tr-TR'], ['tv', 'en-US']];
  const replies = await Promise.allSettled(kinds.map(([kind, language]) =>
    tmdb(env, `/search/${kind}`, {...params, ...(m ? {[kind === 'tv' ? 'first_air_date_year' : 'year']: m[2]} : {}),
      language})));
  if (replies.every(r => r.status === 'rejected')) throw replies[0].reason;
  const items = new Map();
  replies.forEach((r, i) => {
    if (r.status !== 'fulfilled') return;
    const [kind, language] = kinds[i];
    for (const f of r.value.results || []) {
      if (!positive(f.id)) continue;
      const entry = items.get(`${kind}:${f.id}`) || {kind, item: f};
      entry[language === 'tr-TR' ? 'tr' : 'en'] = clip(kind === 'tv' ? f.name : f.title, 120);
      items.set(`${kind}:${f.id}`, entry);
    }
  });
  const key = titleKey(query);
  const originalOf = e => e.kind === 'tv' ? e.item.original_name : e.item.original_title;
  const rank = e => {
    const titles = [e.tr, e.en, originalOf(e)].map(titleKey).filter(Boolean);
    return titles.includes(key) ? 0 : titles.some(t => t.startsWith(key)) ? 1 : 2;
  };
  return [...items.values()]
    .map(e => ({e, rank: rank(e), votes: Number(e.item.vote_count) || 0}))
    .sort((a, b) => a.rank - b.rank || b.votes - a.votes)
    .slice(0, 12)
    .map(({e}) => {
      const original = clip(originalOf(e), 120);
      const title = e.tr || e.en || original;
      return {
        kind: e.kind, tmdbId: e.item.id, title, originalTitle: original,
        englishTitle: e.en && e.en !== title && e.en !== original ? e.en : null,
        year: yearOf(e.kind === 'tv' ? e.item.first_air_date : e.item.release_date),
        poster: imagePath(e.item.poster_path), tmdbRating: rating(e.item.vote_average),
      };
    });
}

const filmJson = f => ({
  id: f.id, tmdbId: f.tmdb_id, imdbId: f.imdb_id, title: f.title, originalTitle: f.original_title,
  year: f.year, runtime: f.runtime, genres: JSON.parse(f.genres), overview: f.overview, poster: f.poster,
  tmdbRating: f.tmdb_rating, imdbRating: f.imdb_rating, providers: JSON.parse(f.providers),
  addedBy: f.added_by, added: f.added, watched: f.watched, watchedBy: f.watched_by,
  kind: f.kind, showId: f.show_id, showTitle: f.show_title, season: f.season, episode: f.episode, still: f.still,
});
// "Black Mirror S3:B1 · Nosedive" for notifications.
const label = f => f.kind === 'episode' ? `${f.show_title} S${f.season}:B${f.episode} · ${f.title}` : f.title;

async function list(env, me) {
  const {results: films} = await env.DB.prepare('SELECT * FROM films ORDER BY added DESC, id DESC').all();
  const {results: ratings} = await env.DB.prepare(`SELECT film_id AS film, player_id AS player, hearts,
    COALESCE(halves, hearts * 2) AS halves, comment, updated FROM film_ratings`).all();
  const {results: replies} = await env.DB.prepare(`SELECT id, film_id AS film, review_by AS reviewBy,
    player_id AS player, text, created FROM film_replies ORDER BY id`).all();
  const {results: likes} = await env.DB.prepare(
    'SELECT film_id AS film, target, player_id AS player FROM film_likes WHERE liked = 1').all();
  const {results: players} = await env.DB.prepare('SELECT id, name FROM players WHERE active = 1 ORDER BY id').all();
  return {films: films.map(filmJson), ratings, replies, likes, players, me, now: nowSec()};
}

async function refreshStale(env) {
  if (!env.TMDB_API_KEY) return;
  const film = await env.DB.prepare(`SELECT id, tmdb_id, kind, show_id, season, episode FROM films
    WHERE info_updated < ? ORDER BY info_updated LIMIT 1`).bind(nowSec() - REFRESH_AFTER).first();
  if (!film) return;
  try {
    const d = film.kind === 'episode'
      ? (await episodeDetails(env, film.show_id, film.season, [film.episode]))[0]
      : await filmDetails(env, film.tmdb_id);
    await env.DB.prepare(`UPDATE films SET imdb_id = ?, title = ?, original_title = ?, year = ?, runtime = ?, genres = ?,
      overview = ?, poster = ?, tmdb_rating = ?, imdb_rating = COALESCE(?, imdb_rating), providers = ?, info_updated = ?,
      show_title = COALESCE(?, show_title), still = COALESCE(?, still) WHERE id = ?`).bind(d.imdbId, d.title,
      d.originalTitle, d.year, d.runtime, JSON.stringify(d.genres), d.overview, d.poster, d.tmdbRating, d.imdbRating,
      JSON.stringify(d.providers), nowSec(), d.showTitle ?? null, d.still ?? null, film.id).run();
  } catch {
    // Try again on a later load instead of the same film on every request.
    await env.DB.prepare('UPDATE films SET info_updated = ? WHERE id = ?')
      .bind(nowSec() - REFRESH_AFTER + 86400, film.id).run();
  }
}

// "film", "bölüm", or "yapım" for a mix.
const noun = rows => rows.every(r => r.kind === 'episode') ? 'bölüm' : rows.some(r => r.kind === 'episode') ? 'yapım' : 'film';

// First addition: "<name> watchlist'e bir film ekledi! 🎬" at once (several
// episodes added together count as one addition). More additions within
// DIGEST_WINDOW update one queued notification that becomes due when the
// window ends (the delivery queue picks rows whose `attempted` is more than two
// minutes old).
async function notifyAdded(env, ctx, player, added, deliver) {
  const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
  if (!other) return;
  const now = nowSec();
  const digest = await env.DB.prepare('SELECT * FROM film_digest WHERE player_id = ?').bind(player.id).first();
  if (!digest || now - digest.notified >= DIGEST_WINDOW) {
    const what = added.length > 1 ? `${added.length} ${noun(added)}` : `bir ${noun(added)}`;
    const icon = added.every(r => r.kind === 'episode') ? '📺' : '🎬';
    await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
      .bind(other.id, `${player.name} watchlist'e ${what} ekledi! ${icon}`, clip(added.map(label).join(', '), 180)).run();
    await env.DB.prepare(`INSERT INTO film_digest(player_id, notified, last_film, notification_id) VALUES (?, ?, ?, NULL)
      ON CONFLICT(player_id) DO UPDATE SET notified = excluded.notified, last_film = excluded.last_film,
      notification_id = NULL`).bind(player.id, now, Math.max(...added.map(r => r.id))).run();
    ctx?.waitUntil(deliver(env));
    return;
  }
  const {results} = await env.DB.prepare(`SELECT title, kind, show_title, season, episode FROM films
    WHERE added_by = ? AND id > ? ORDER BY id`).bind(player.id, digest.last_film).all();
  if (!results.length) return;
  const title = `${player.name} watchlist'e ${results.length} ${noun(results)} daha ekledi! 🎬`;
  const body = clip(results.map(label).join(', '), 180);
  const pending = digest.notification_id && await env.DB.prepare(
    'SELECT id FROM notifications WHERE id = ? AND sent = 0 AND attempts = 0').bind(digest.notification_id).first();
  if (pending) {
    await env.DB.prepare('UPDATE notifications SET title = ?, body = ? WHERE id = ?').bind(title, body, pending.id).run();
    return;
  }
  const queued = await env.DB.prepare(
    'INSERT INTO notifications(player_id, title, body, attempted) VALUES (?, ?, ?, ?) RETURNING id')
    .bind(other.id, title, body, digest.notified + DIGEST_WINDOW - 120).first();
  await env.DB.prepare('UPDATE film_digest SET notification_id = ? WHERE player_id = ?').bind(queued.id, player.id).run();
}

const filmId = data => Number.isSafeInteger(data.id) && data.id > 0 ? data.id : fail('Geçersiz film.');
async function film(env, id) {
  return await env.DB.prepare('SELECT * FROM films WHERE id = ?').bind(id).first() || fail('Film listede yok.', 404);
}

/** `/films` (GET list) and `/films/*` (POST) for an active, registered player. */
export async function filmsRoute(env, ctx, player, path, method, data, deliver) {
  if (path === '/films' && method === 'GET') {
    ctx?.waitUntil(refreshStale(env).catch(() => {}));
    return list(env, player.id);
  }
  if (method !== 'POST') fail('Bulunamadı.', 404);
  if (path === '/films/search') {
    const query = typeof data.query === 'string' ? data.query.trim() : '';
    if (query.length < 1 || query.length > 80 || HIDDEN.test(query)) fail('1–80 karakterlik bir film ya da dizi adı yaz.');
    const results = await search(env, query);
    const {results: listed} = await env.DB.prepare("SELECT tmdb_id FROM films WHERE kind = 'movie'").all();
    const inList = new Set(listed.map(r => r.tmdb_id));
    const {results: shows} = await env.DB.prepare(
      "SELECT show_id, COUNT(*) AS count FROM films WHERE kind = 'episode' GROUP BY show_id").all();
    const episodes = new Map(shows.map(r => [r.show_id, r.count]));
    return {results: results.map(r => r.kind === 'tv'
      ? {...r, inList: false, listedEpisodes: episodes.get(r.tmdbId) || 0}
      : {...r, inList: inList.has(r.tmdbId)})};
  }
  if (path === '/films/show') {
    const showId = positive(data.tmdbId) || fail('Geçersiz dizi.');
    return {show: {tmdbId: showId, ...await showInfo(env, showId)}};
  }
  if (path === '/films/season') {
    const showId = positive(data.tmdbId) || fail('Geçersiz dizi.');
    const season = Number.isSafeInteger(data.season) && data.season >= 0 && data.season < 1000 ? data.season : fail('Geçersiz sezon.');
    const s = await seasonEpisodes(env, showId, season);
    const {results: listed} = await env.DB.prepare(
      "SELECT episode FROM films WHERE kind = 'episode' AND show_id = ? AND season = ?").bind(showId, season).all();
    const inList = new Set(listed.map(r => r.episode));
    return {episodes: s.episodes.map(({id, ...e}) => ({...e, inList: inList.has(e.episode)}))};
  }
  if (path === '/films/episodes') {
    const showId = positive(data.showId) || fail('Geçersiz dizi.');
    const season = Number.isSafeInteger(data.season) && data.season >= 0 && data.season < 1000 ? data.season : fail('Geçersiz sezon.');
    const wanted = Array.isArray(data.episodes) && data.episodes.length >= 1 && data.episodes.length <= MAX_EPISODES
      && data.episodes.every(positive) ? [...new Set(data.episodes)] : fail(`1–${MAX_EPISODES} bölüm seç.`);
    const {results: listed} = await env.DB.prepare(
      "SELECT episode FROM films WHERE kind = 'episode' AND show_id = ? AND season = ?").bind(showId, season).all();
    const have = new Set(listed.map(r => r.episode));
    const numbers = wanted.filter(n => !have.has(n));
    if (!numbers.length) fail(wanted.length > 1 ? 'Bu bölümler zaten listede.' : 'Bu bölüm zaten listede.', 409);
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM films').first();
    if (count.count + numbers.length > MAX_FILMS) fail(`Listede en fazla ${MAX_FILMS} film ve bölüm olabilir.`);
    const details = await episodeDetails(env, showId, season, numbers);
    const now = nowSec();
    const added = [];
    for (const d of details) {
      const row = await env.DB.prepare(`INSERT INTO films(tmdb_id, imdb_id, title, original_title, year, runtime, genres,
        overview, poster, tmdb_rating, imdb_rating, providers, added_by, added, info_updated, kind, show_id, show_title,
        season, episode, still) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'episode', ?, ?, ?, ?, ?)
        ON CONFLICT DO NOTHING RETURNING id`).bind(d.tmdbId, d.imdbId, d.title, d.originalTitle, d.year, d.runtime,
        JSON.stringify(d.genres), d.overview, d.poster, d.tmdbRating, d.imdbRating, JSON.stringify(d.providers), player.id,
        now, now, d.showId, d.showTitle, d.season, d.episode, d.still).first();
      if (row) added.push({id: row.id, kind: 'episode', title: d.title, show_title: d.showTitle, season, episode: d.episode});
    }
    if (!added.length) fail('Bu bölümler zaten listede.', 409);
    await notifyAdded(env, ctx, player, added, deliver);
    return {...await list(env, player.id), added: added.map(r => r.id)};
  }
  if (path === '/films') {
    const tmdbId = Number.isSafeInteger(data.tmdbId) && data.tmdbId > 0 ? data.tmdbId : fail('Geçersiz film.');
    if (await env.DB.prepare('SELECT id FROM films WHERE tmdb_id = ?').bind(tmdbId).first()) fail('Bu film zaten listede.', 409);
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM films').first();
    if (count.count >= MAX_FILMS) fail(`Listede en fazla ${MAX_FILMS} film olabilir.`);
    const d = await filmDetails(env, tmdbId);
    const now = nowSec();
    const added = await env.DB.prepare(`INSERT INTO films(tmdb_id, imdb_id, title, original_title, year, runtime, genres,
      overview, poster, tmdb_rating, imdb_rating, providers, added_by, added, info_updated)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(tmdb_id) DO NOTHING RETURNING id`)
      .bind(tmdbId, d.imdbId, d.title, d.originalTitle, d.year, d.runtime, JSON.stringify(d.genres), d.overview,
        d.poster, d.tmdbRating, d.imdbRating, JSON.stringify(d.providers), player.id, now, now).first();
    if (!added) fail('Bu film zaten listede.', 409);
    await notifyAdded(env, ctx, player, [{id: added.id, kind: 'movie', title: d.title}], deliver);
    return {...await list(env, player.id), added: added.id};
  }
  if (path === '/films/watched') {
    const f = await film(env, filmId(data));
    if (typeof data.watched !== 'boolean') fail('Geçersiz istek.');
    if (!data.watched) {
      await env.DB.prepare('UPDATE films SET watched = NULL, watched_by = NULL WHERE id = ?').bind(f.id).run();
    } else if (!f.watched) {
      await env.DB.prepare('UPDATE films SET watched = ?, watched_by = ? WHERE id = ?').bind(nowSec(), player.id, f.id).run();
      // Only the first time: an undo/redo loop must not spam the other player.
      const first = await env.DB.prepare('UPDATE films SET watch_notified = 1 WHERE id = ? AND watch_notified = 0 RETURNING id')
        .bind(f.id).first();
      const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
      if (first && other) {
        await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
          .bind(other.id, f.kind === 'episode'
            ? `${player.name}, ${clip(f.show_title, 50)} S${f.season}:B${f.episode} bölümünü izlendi olarak işaretledi`
            : `${player.name}, ${clip(f.title, 60)} filmini izlendi olarak işaretledi`, 'Puanını ver! 🍿').run();
        ctx?.waitUntil(deliver(env));
      }
    }
    return list(env, player.id);
  }
  if (path === '/films/rate') {
    const f = await film(env, filmId(data));
    if (!f.watched) fail(f.kind === 'episode' ? 'Puan için önce bölümü izlendi olarak işaretle.'
      : 'Puan için önce filmi izlendi olarak işaretle.');
    // Half hearts: `halves` 1–10; older apps send whole `hearts` 1–5.
    const halves = data.halves !== undefined
      ? (Number.isSafeInteger(data.halves) && data.halves >= 1 && data.halves <= 10 ? data.halves : fail('½–5 arası kalp seç.'))
      : (Number.isSafeInteger(data.hearts) && data.hearts >= 1 && data.hearts <= 5 ? data.hearts * 2 : fail('1–5 arası kalp seç.'));
    const comment = typeof data.comment === 'string' ? data.comment.trim() : '';
    if (comment.length > 140 || HIDDEN.test(comment)) fail('Yorum en fazla 140 karakter, tek satır olabilir.');
    await env.DB.prepare(`INSERT INTO film_ratings(film_id, player_id, hearts, halves, comment, updated) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(film_id, player_id) DO UPDATE SET hearts = excluded.hearts, halves = excluded.halves,
      comment = excluded.comment, updated = excluded.updated`)
      .bind(f.id, player.id, Math.ceil(halves / 2), halves, comment, nowSec()).run();
    return list(env, player.id);
  }
  if (path === '/films/reply') {
    const f = await film(env, filmId(data));
    const review = Number.isSafeInteger(data.reviewBy) && await env.DB.prepare(
      'SELECT player_id FROM film_ratings WHERE film_id = ? AND player_id = ?').bind(f.id, data.reviewBy).first();
    if (!review) fail('Bu yorum artık yok.', 404);
    const text = typeof data.text === 'string' ? data.text.trim() : '';
    if (text.length < 1 || text.length > MAX_REPLY || HIDDEN.test(text)) fail(`Yanıt 1–${MAX_REPLY} karakter, tek satır olabilir.`);
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM film_replies WHERE film_id = ?').bind(f.id).first();
    if (count.count >= MAX_REPLIES) fail(`Bir filmde en fazla ${MAX_REPLIES} yanıt olabilir.`);
    await env.DB.prepare('INSERT INTO film_replies(film_id, review_by, player_id, text, created) VALUES (?, ?, ?, ?, ?)')
      .bind(f.id, data.reviewBy, player.id, text, nowSec()).run();
    const {results: others} = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).all();
    for (const other of others) {
      const whose = other.id === data.reviewBy ? 'yorumuna' : 'yorumlara';
      await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
        .bind(other.id, `${player.name} ${whose} yanıt verdi 💬`, clip(`${label(f)}: ${text}`, 180)).run();
    }
    if (others.length) ctx?.waitUntil(deliver(env));
    return list(env, player.id);
  }
  if (path === '/films/reply/delete') {
    const id = Number.isSafeInteger(data.reply) && data.reply > 0 ? data.reply : fail('Geçersiz yanıt.');
    const row = await env.DB.prepare('SELECT film_id, player_id FROM film_replies WHERE id = ?').bind(id).first();
    if (row && row.player_id !== player.id) fail('Yalnız kendi yanıtını silebilirsin.', 403);
    if (row) {
      await env.DB.prepare('DELETE FROM film_likes WHERE film_id = ? AND target = ?').bind(row.film_id, `r${id}`).run();
      await env.DB.prepare('DELETE FROM film_replies WHERE id = ?').bind(id).run();
    }
    return list(env, player.id);
  }
  if (path === '/films/like') {
    const f = await film(env, filmId(data));
    if (typeof data.like !== 'boolean') fail('Geçersiz istek.');
    const m = typeof data.target === 'string' ? /^([cr])([1-9]\d{0,9})$/.exec(data.target) : null;
    if (!m) fail('Geçersiz yorum.');
    const target = m[1] === 'c'
      ? await env.DB.prepare("SELECT player_id AS owner, comment AS text FROM film_ratings WHERE film_id = ? AND player_id = ? AND comment != ''")
        .bind(f.id, Number(m[2])).first()
      : await env.DB.prepare('SELECT player_id AS owner, text FROM film_replies WHERE film_id = ? AND id = ?')
        .bind(f.id, Number(m[2])).first();
    if (!target) fail('Bu yorum artık yok.', 404);
    if (target.owner === player.id) fail('Kendi yorumunu beğenemezsin.');
    if (!data.like) {
      await env.DB.prepare('UPDATE film_likes SET liked = 0 WHERE film_id = ? AND target = ? AND player_id = ?')
        .bind(f.id, data.target, player.id).run();
      return list(env, player.id);
    }
    const first = await env.DB.prepare(`INSERT INTO film_likes(film_id, target, player_id, liked, created) VALUES (?, ?, ?, 1, ?)
      ON CONFLICT DO NOTHING RETURNING film_id`).bind(f.id, data.target, player.id, nowSec()).first();
    if (first) {
      // Only the first like notifies: unlike/like again stays quiet.
      await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
        .bind(target.owner, `${player.name} ${m[1] === 'c' ? 'yorumunu' : 'yanıtını'} beğendi 💗`,
          clip(`${label(f)}: ${target.text}`, 180)).run();
      ctx?.waitUntil(deliver(env));
    } else {
      await env.DB.prepare('UPDATE film_likes SET liked = 1 WHERE film_id = ? AND target = ? AND player_id = ?')
        .bind(f.id, data.target, player.id).run();
    }
    return list(env, player.id);
  }
  if (path === '/films/delete') {
    const id = filmId(data);
    await env.DB.prepare('DELETE FROM film_likes WHERE film_id = ?').bind(id).run();
    await env.DB.prepare('DELETE FROM film_replies WHERE film_id = ?').bind(id).run();
    await env.DB.prepare('DELETE FROM film_ratings WHERE film_id = ?').bind(id).run();
    await env.DB.prepare('DELETE FROM films WHERE id = ?').bind(id).run();
    return list(env, player.id);
  }
  fail('Bulunamadı.', 404);
}
