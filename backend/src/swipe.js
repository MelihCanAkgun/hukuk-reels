// "Ortak karar" (film swipe) for the İzle tab. One player starts a session:
// a short fixed deck of unwatched list items plus a few TMDB suggestions.
// Both swipe in their own time (pass / like / one super like each). Nobody
// sees the other's votes until both are done; then the mutual likes are the
// result, super-liked ones first. A matched suggestion joins the watchlist.
import {clip, filmDetails, imagePath, rating, tmdb, yearOf} from './films.js';

// Kept short on purpose: 10 from the list + 5 suggestions.
const DECK = 15, FROM_LIST = 10, MIN_SUGGESTIONS = 5, MAX_SUGGESTIONS = 10, MIN_CARDS = 3;
// An unfinished session can be replaced after three days.
const STALE = 3 * 86400;
// "Sıra sende" is only sent when the start notification is not fresh.
const NUDGE_AFTER = 600;
const START_COOLDOWN = 60;
const KEEP_SESSIONS = 5;
// TMDB movie genre ids (stable) in Turkish, as the tr-TR API names them.
const GENRES = {28: 'Aksiyon', 12: 'Macera', 16: 'Animasyon', 35: 'Komedi', 80: 'Suç', 99: 'Belgesel', 18: 'Dram',
  10751: 'Aile', 14: 'Fantastik', 36: 'Tarih', 27: 'Korku', 10402: 'Müzik', 9648: 'Gizem', 10749: 'Romantik',
  878: 'Bilim-Kurgu', 10770: 'TV film', 53: 'Gerilim', 10752: 'Savaş', 37: 'Vahşi Batı'};

const fail = (message, status = 400) => { throw Object.assign(new Error(message), {status}); };
const nowSec = () => Math.floor(Date.now() / 1000);
function shuffle(items, random = Math.random) {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}

// Well-liked films similar to what the two already enjoyed (or have listed);
// trending films fill the gaps. Never anything that is already in the list.
// A TMDB failure just means fewer (or no) suggestions.
async function suggestions(env, count) {
  if (!env.TMDB_API_KEY || count <= 0) return [];
  const {results: loved} = await env.DB.prepare(`SELECT f.tmdb_id FROM films f JOIN film_ratings r ON r.film_id = f.id
    WHERE f.kind = 'movie' GROUP BY f.id HAVING AVG(COALESCE(r.halves, r.hearts * 2)) >= 8 ORDER BY RANDOM() LIMIT 3`).all();
  const {results: listed} = loved.length >= 2 ? {results: []} : await env.DB.prepare(
    "SELECT tmdb_id FROM films WHERE kind = 'movie' ORDER BY RANDOM() LIMIT ?").bind(3 - loved.length).all();
  const seeds = [...new Set([...loved, ...listed].map(r => r.tmdb_id))];
  const replies = await Promise.allSettled([
    ...seeds.map(id => tmdb(env, `/movie/${id}/recommendations`, {language: 'tr-TR', page: '1'})),
    tmdb(env, '/trending/movie/week', {language: 'tr-TR'}),
  ]);
  const {results: have} = await env.DB.prepare("SELECT tmdb_id FROM films WHERE kind = 'movie'").all();
  const inList = new Set(have.map(r => r.tmdb_id));
  const found = new Map();
  for (const r of replies) {
    for (const f of r.status === 'fulfilled' ? r.value.results || [] : []) {
      if (!Number.isSafeInteger(f.id) || f.id <= 0 || inList.has(f.id) || found.has(f.id) || f.adult) continue;
      const poster = imagePath(f.poster_path), score = rating(f.vote_average);
      if (!poster || !score || score < 6.5 || !(Number(f.vote_count) >= 200)) continue;
      found.set(f.id, {
        film_id: null, tmdb_id: f.id, suggested: 1, title: clip(f.title || f.original_title, 120) || 'Adsız film',
        original_title: clip(f.original_title, 120), year: yearOf(f.release_date), runtime: null,
        genres: JSON.stringify((f.genre_ids || []).map(g => GENRES[g]).filter(Boolean).slice(0, 4)),
        overview: clip(f.overview, 1200), poster, tmdb_rating: score, imdb_rating: null,
        show_title: null, season: null, episode: null,
      });
    }
  }
  // Random picks among the best rated, so each session differs.
  const best = [...found.values()].sort((a, b) => b.tmdb_rating - a.tmdb_rating).slice(0, count * 3);
  return shuffle(best).slice(0, count);
}

const cardJson = c => ({
  pos: c.pos, filmId: c.film_id, tmdbId: c.tmdb_id, suggested: c.suggested === 1, title: c.title,
  originalTitle: c.original_title, year: c.year, runtime: c.runtime, genres: JSON.parse(c.genres), overview: c.overview,
  poster: c.poster, tmdbRating: c.tmdb_rating, imdbRating: c.imdb_rating, showTitle: c.show_title, season: c.season,
  episode: c.episode,
});

// The session both players see: the open one, else the last finished one.
const current = env => env.DB.prepare("SELECT * FROM swipe_sessions WHERE status != 'cancelled' ORDER BY id DESC LIMIT 1").first();
const counts = async (env, id) => Object.fromEntries((await env.DB.prepare(
  'SELECT player_id AS player, COUNT(*) AS count FROM swipe_votes WHERE session_id = ? GROUP BY player_id').bind(id).all())
  .results.map(r => [r.player, r.count]));
const total = async (env, id) => (await env.DB.prepare('SELECT COUNT(*) AS count FROM swipe_cards WHERE session_id = ?')
  .bind(id).first()).count;

/** Small state for the film list reply (banner on the İzle tab). */
export async function swipeSummary(env, me) {
  const s = await current(env);
  if (!s) return null;
  const [n, done] = [await total(env, s.id), await counts(env, s.id)];
  return {id: s.id, status: s.status, startedBy: s.started_by, created: s.created, total: n,
    mine: done[me] || 0, otherDone: (done[3 - me] || 0) >= n};
}

// Mutual likes, best first: more super likes, then the higher rating.
function matchesOf(cards, votes) {
  const by = new Map();
  for (const v of votes) by.set(`${v.pos}:${v.player}`, v.vote);
  return cards.map(c => ({c, v1: by.get(`${c.pos}:1`) || 0, v2: by.get(`${c.pos}:2`) || 0}))
    .filter(m => m.v1 > 0 && m.v2 > 0)
    .map(m => ({...cardJson(m.c), supers: [m.v1 === 2 ? 1 : null, m.v2 === 2 ? 2 : null].filter(Boolean)}))
    .sort((a, b) => b.supers.length - a.supers.length
      || (b.imdbRating ?? b.tmdbRating ?? 0) - (a.imdbRating ?? a.tmdbRating ?? 0) || a.pos - b.pos);
}

async function state(env, me) {
  const s = await current(env);
  if (!s) return {session: null, me};
  const {results: cards} = await env.DB.prepare('SELECT * FROM swipe_cards WHERE session_id = ? ORDER BY pos').bind(s.id).all();
  const {results: votes} = await env.DB.prepare(
    'SELECT pos, player_id AS player, vote FROM swipe_votes WHERE session_id = ?').bind(s.id).all();
  const mine = votes.filter(v => v.player === me);
  const others = votes.length - mine.length;
  const {results: players} = await env.DB.prepare('SELECT id, name FROM players WHERE active = 1 ORDER BY id').all();
  return {me, players, session: {
    id: s.id, status: s.status, startedBy: s.started_by, created: s.created, finished: s.finished, total: cards.length,
    cards: cards.map(cardJson),
    // The other player's votes stay hidden until both are done.
    votes: Object.fromEntries(mine.map(v => [v.pos, v.vote])),
    superUsed: mine.some(v => v.vote === 2), otherCount: others, otherDone: others >= cards.length,
    matches: s.status === 'done' ? matchesOf(cards, votes) : null,
  }};
}

// Both are done: close the session once, add matched suggestions to the
// watchlist and tell the player who finished earlier.
async function finish(env, ctx, player, session, deliver) {
  const closed = await env.DB.prepare("UPDATE swipe_sessions SET status = 'done', finished = ? WHERE id = ? AND status = 'open' RETURNING id")
    .bind(nowSec(), session.id).first();
  if (!closed) return;
  const {results: cards} = await env.DB.prepare('SELECT * FROM swipe_cards WHERE session_id = ? ORDER BY pos').bind(session.id).all();
  const {results: votes} = await env.DB.prepare(
    'SELECT pos, player_id AS player, vote FROM swipe_votes WHERE session_id = ?').bind(session.id).all();
  const matches = matchesOf(cards, votes);
  for (const m of matches.filter(x => x.suggested && !x.filmId)) {
    try {
      let row = await env.DB.prepare('SELECT id FROM films WHERE tmdb_id = ?').bind(m.tmdbId).first();
      if (!row) {
        const d = await filmDetails(env, m.tmdbId);
        const now = nowSec();
        await env.DB.prepare(`INSERT INTO films(tmdb_id, imdb_id, title, original_title, year, runtime, genres,
          overview, poster, tmdb_rating, imdb_rating, providers, added_by, added, info_updated)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(tmdb_id) DO NOTHING`)
          .bind(m.tmdbId, d.imdbId, d.title, d.originalTitle, d.year, d.runtime, JSON.stringify(d.genres), d.overview,
            d.poster, d.tmdbRating, d.imdbRating, JSON.stringify(d.providers), session.started_by, now, now).run();
        row = await env.DB.prepare('SELECT id FROM films WHERE tmdb_id = ?').bind(m.tmdbId).first();
      }
      if (row) await env.DB.prepare('UPDATE swipe_cards SET film_id = ? WHERE session_id = ? AND pos = ?')
        .bind(row.id, session.id, m.pos).run();
    } catch { /* The match is still shown; it can be added by hand. */ }
  }
  const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
  if (other) {
    await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)').bind(other.id,
      matches.length ? (matches.length > 1 ? `${matches.length} filmde eşleştiniz! 🎉` : 'Eşleşme var! 🎉') : 'Bu sefer eşleşme çıkmadı 😅',
      matches.length ? clip(`İkiniz de beğendi: ${matches.map(m => m.title).join(', ')}`, 180)
        : `${player.name} de seçimini yaptı ama ortak film çıkmadı. Yeni bir tur deneyin!`).run();
    ctx?.waitUntil(deliver(env));
  }
}

/** `/films/swipe` (state) and `/films/swipe/*`, all POST, for an active, registered player. */
export async function swipeRoute(env, ctx, player, path, method, data, deliver, random = Math.random) {
  if (method !== 'POST') fail('Bulunamadı.', 404);
  if (path === '/films/swipe') return state(env, player.id);
  const now = nowSec();
  if (path === '/films/swipe/start') {
    const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
    if (!other) fail('Diğer oyuncu henüz katılmadı.');
    const last = await env.DB.prepare('SELECT * FROM swipe_sessions ORDER BY id DESC LIMIT 1').first();
    const open = await env.DB.prepare("SELECT * FROM swipe_sessions WHERE status = 'open' ORDER BY id DESC LIMIT 1").first();
    if (open && now - open.created < STALE) fail('Zaten süren bir seçim var.', 409);
    if (last && now - last.created < START_COOLDOWN) fail('Yeni seçim için bir dakika bekle.', 429);
    const {results: listed} = await env.DB.prepare(
      'SELECT * FROM films WHERE watched IS NULL ORDER BY RANDOM() LIMIT ?').bind(FROM_LIST).all();
    const extra = await suggestions(env, Math.min(MAX_SUGGESTIONS, Math.max(MIN_SUGGESTIONS, DECK - listed.length)));
    const cards = shuffle([...listed.map(f => ({
      film_id: f.id, tmdb_id: f.tmdb_id, suggested: 0, title: f.title, original_title: f.original_title, year: f.year,
      runtime: f.runtime, genres: f.genres, overview: f.overview, poster: f.poster, tmdb_rating: f.tmdb_rating,
      imdb_rating: f.imdb_rating, show_title: f.kind === 'episode' ? f.show_title : null,
      season: f.kind === 'episode' ? f.season : null, episode: f.kind === 'episode' ? f.episode : null,
    })), ...extra], random);
    if (cards.length < MIN_CARDS) fail('Seçim için izleyeceklerinize birkaç film ekleyin.');
    await env.DB.prepare("UPDATE swipe_sessions SET status = 'cancelled' WHERE status = 'open'").run();
    const session = await env.DB.prepare('INSERT INTO swipe_sessions(started_by, created) VALUES (?, ?) RETURNING id')
      .bind(player.id, now).first();
    for (const [pos, c] of cards.entries()) {
      await env.DB.prepare(`INSERT INTO swipe_cards(session_id, pos, film_id, tmdb_id, suggested, title, original_title, year,
        runtime, genres, overview, poster, tmdb_rating, imdb_rating, show_title, season, episode)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).bind(session.id, pos, c.film_id, c.tmdb_id, c.suggested,
        c.title, c.original_title, c.year, c.runtime, c.genres, c.overview, c.poster, c.tmdb_rating, c.imdb_rating,
        c.show_title, c.season, c.episode).run();
    }
    // Votes and cards of old sessions go with them.
    const {results: old} = await env.DB.prepare('SELECT id FROM swipe_sessions ORDER BY id DESC LIMIT -1 OFFSET ?')
      .bind(KEEP_SESSIONS).all();
    for (const o of old) {
      await env.DB.prepare('DELETE FROM swipe_votes WHERE session_id = ?').bind(o.id).run();
      await env.DB.prepare('DELETE FROM swipe_cards WHERE session_id = ?').bind(o.id).run();
      await env.DB.prepare('DELETE FROM swipe_sessions WHERE id = ?').bind(o.id).run();
    }
    await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)').bind(other.id,
      `${player.name} film seçimi başlattı! 🍿`,
      `${cards.length} film arasından beğendiklerini seç, eşleşenleri birlikte görün.`).run();
    ctx?.waitUntil(deliver(env));
    return state(env, player.id);
  }
  const id = Number.isSafeInteger(data.session) && data.session > 0 ? data.session : fail('Geçersiz seçim.');
  const session = await env.DB.prepare('SELECT * FROM swipe_sessions WHERE id = ?').bind(id).first();
  if (!session) fail('Bu seçim artık yok.', 404);
  if (path === '/films/swipe/cancel') {
    await env.DB.prepare("UPDATE swipe_sessions SET status = 'cancelled' WHERE id = ? AND status = 'open'").bind(id).run();
    return state(env, player.id);
  }
  if (path === '/films/swipe/vote') {
    if (session.status !== 'open') fail('Bu seçim tamamlandı.', 409);
    if (![0, 1, 2].includes(data.vote)) fail('Geçersiz oy.');
    const card = Number.isSafeInteger(data.pos) && await env.DB.prepare(
      'SELECT pos FROM swipe_cards WHERE session_id = ? AND pos = ?').bind(id, data.pos).first();
    if (!card) fail('Geçersiz kart.');
    if (data.vote === 2 && await env.DB.prepare(
      'SELECT pos FROM swipe_votes WHERE session_id = ? AND player_id = ? AND vote = 2 AND pos != ?')
      .bind(id, player.id, data.pos).first()) fail('Süper beğeni hakkını kullandın.', 409);
    await env.DB.prepare(`INSERT INTO swipe_votes(session_id, pos, player_id, vote) VALUES (?, ?, ?, ?)
      ON CONFLICT(session_id, pos, player_id) DO UPDATE SET vote = excluded.vote`).bind(id, data.pos, player.id, data.vote).run();
    const [n, done] = [await total(env, id), await counts(env, id)];
    const other = 3 - player.id;
    if ((done[player.id] || 0) >= n && (done[other] || 0) >= n) await finish(env, ctx, player, session, deliver);
    else if ((done[player.id] || 0) >= n && now - session.created > NUDGE_AFTER) {
      const first = await env.DB.prepare('UPDATE swipe_sessions SET nudged = 1 WHERE id = ? AND nudged = 0 RETURNING id').bind(id).first();
      const target = first && await env.DB.prepare('SELECT id FROM players WHERE id = ? AND active = 1').bind(other).first();
      if (target) {
        await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)').bind(target.id,
          `${player.name} seçimini yaptı, sıra sende ⏳`, `${n} filmi kaydır, eşleşmeleri görün.`).run();
        ctx?.waitUntil(deliver(env));
      }
    }
    return state(env, player.id);
  }
  fail('Bulunamadı.', 404);
}
