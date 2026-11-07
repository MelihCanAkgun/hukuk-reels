// Shared film watchlist ("Filmler" tab). The Worker proxies TMDB (search,
// Turkish title, poster, rating, TR streaming providers) and OMDb (IMDb
// rating); the API keys never leave the Worker secrets. Letterboxd has no API,
// so the app only links to letterboxd.com/tmdb/<id>.
const TMDB = 'https://api.themoviedb.org/3';
const OMDB = 'https://www.omdbapi.com/';
// Details and ratings change slowly: one stale film is refreshed per list load.
const REFRESH_AFTER = 7 * 86400;
// Additions within this window share one (delayed) notification.
const DIGEST_WINDOW = 600;
const MAX_FILMS = 400;
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
    fail(response.status === 404 ? 'Film bulunamadı.' : 'Film servisine ulaşılamadı. Biraz sonra tekrar dene.',
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
  const providers = (m['watch/providers']?.results?.TR?.flatrate || []).slice(0, 6)
    .map(p => ({name: clip(p.provider_name, 40), logo: imagePath(p.logo_path)})).filter(p => p.name);
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
    providers,
  };
}

const filmJson = f => ({
  id: f.id, tmdbId: f.tmdb_id, imdbId: f.imdb_id, title: f.title, originalTitle: f.original_title,
  year: f.year, runtime: f.runtime, genres: JSON.parse(f.genres), overview: f.overview, poster: f.poster,
  tmdbRating: f.tmdb_rating, imdbRating: f.imdb_rating, providers: JSON.parse(f.providers),
  addedBy: f.added_by, added: f.added, watched: f.watched, watchedBy: f.watched_by,
});

async function list(env, me) {
  const {results: films} = await env.DB.prepare('SELECT * FROM films ORDER BY added DESC, id DESC').all();
  const {results: ratings} = await env.DB.prepare(
    'SELECT film_id AS film, player_id AS player, hearts, comment, updated FROM film_ratings').all();
  const {results: players} = await env.DB.prepare('SELECT id, name FROM players WHERE active = 1 ORDER BY id').all();
  return {films: films.map(filmJson), ratings, players, me, now: nowSec()};
}

async function refreshStale(env) {
  if (!env.TMDB_API_KEY) return;
  const film = await env.DB.prepare('SELECT id, tmdb_id FROM films WHERE info_updated < ? ORDER BY info_updated LIMIT 1')
    .bind(nowSec() - REFRESH_AFTER).first();
  if (!film) return;
  try {
    const d = await filmDetails(env, film.tmdb_id);
    await env.DB.prepare(`UPDATE films SET imdb_id = ?, title = ?, original_title = ?, year = ?, runtime = ?, genres = ?,
      overview = ?, poster = ?, tmdb_rating = ?, imdb_rating = COALESCE(?, imdb_rating), providers = ?, info_updated = ?
      WHERE id = ?`).bind(d.imdbId, d.title, d.originalTitle, d.year, d.runtime, JSON.stringify(d.genres), d.overview,
      d.poster, d.tmdbRating, d.imdbRating, JSON.stringify(d.providers), nowSec(), film.id).run();
  } catch {
    // Try again on a later load instead of the same film on every request.
    await env.DB.prepare('UPDATE films SET info_updated = ? WHERE id = ?')
      .bind(nowSec() - REFRESH_AFTER + 86400, film.id).run();
  }
}

// First addition: "<name> watchlist'e bir film ekledi! 🎬" at once. More
// additions within DIGEST_WINDOW update one queued notification that becomes
// due when the window ends (the delivery queue picks rows whose `attempted`
// is more than two minutes old).
async function notifyAdded(env, ctx, player, film, deliver) {
  const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
  if (!other) return;
  const now = nowSec();
  const digest = await env.DB.prepare('SELECT * FROM film_digest WHERE player_id = ?').bind(player.id).first();
  if (!digest || now - digest.notified >= DIGEST_WINDOW) {
    await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
      .bind(other.id, `${player.name} watchlist'e bir film ekledi! 🎬`, film.title).run();
    await env.DB.prepare(`INSERT INTO film_digest(player_id, notified, last_film, notification_id) VALUES (?, ?, ?, NULL)
      ON CONFLICT(player_id) DO UPDATE SET notified = excluded.notified, last_film = excluded.last_film,
      notification_id = NULL`).bind(player.id, now, film.id).run();
    ctx?.waitUntil(deliver(env));
    return;
  }
  const {results} = await env.DB.prepare('SELECT title FROM films WHERE added_by = ? AND id > ? ORDER BY id')
    .bind(player.id, digest.last_film).all();
  if (!results.length) return;
  const title = `${player.name} watchlist'e ${results.length} film daha ekledi! 🎬`;
  const body = clip(results.map(r => r.title).join(', '), 180);
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
    if (query.length < 1 || query.length > 80 || HIDDEN.test(query)) fail('1–80 karakterlik bir film adı yaz.');
    const found = await tmdb(env, '/search/movie', {query, language: 'tr-TR', include_adult: 'false', page: '1'});
    const results = (found.results || []).filter(m => Number.isSafeInteger(m.id) && m.id > 0).slice(0, 12);
    const {results: listed} = await env.DB.prepare('SELECT tmdb_id FROM films').all();
    const inList = new Set(listed.map(r => r.tmdb_id));
    return {results: results.map(m => ({
      tmdbId: m.id, title: clip(m.title || m.original_title, 120), originalTitle: clip(m.original_title, 120),
      year: yearOf(m.release_date), poster: imagePath(m.poster_path), tmdbRating: rating(m.vote_average),
      inList: inList.has(m.id),
    }))};
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
    await notifyAdded(env, ctx, player, {id: added.id, title: d.title}, deliver);
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
          .bind(other.id, `${player.name}, ${clip(f.title, 60)} filmini izlendi olarak işaretledi`, 'Puanını ver! 🍿').run();
        ctx?.waitUntil(deliver(env));
      }
    }
    return list(env, player.id);
  }
  if (path === '/films/rate') {
    const f = await film(env, filmId(data));
    if (!f.watched) fail('Puan için önce filmi izlendi olarak işaretle.');
    if (!Number.isSafeInteger(data.hearts) || data.hearts < 1 || data.hearts > 5) fail('1–5 arası kalp seç.');
    const comment = typeof data.comment === 'string' ? data.comment.trim() : '';
    if (comment.length > 140 || HIDDEN.test(comment)) fail('Yorum en fazla 140 karakter, tek satır olabilir.');
    await env.DB.prepare(`INSERT INTO film_ratings(film_id, player_id, hearts, comment, updated) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(film_id, player_id) DO UPDATE SET hearts = excluded.hearts, comment = excluded.comment,
      updated = excluded.updated`).bind(f.id, player.id, data.hearts, comment, nowSec()).run();
    return list(env, player.id);
  }
  if (path === '/films/delete') {
    const id = filmId(data);
    await env.DB.prepare('DELETE FROM film_ratings WHERE film_id = ?').bind(id).run();
    await env.DB.prepare('DELETE FROM films WHERE id = ?').bind(id).run();
    return list(env, player.id);
  }
  fail('Bulunamadı.', 404);
}
