import webpush from 'web-push';
import {validRoom, roomCode} from './battle-room.js';
import {avatarRoute, avatarFullRoute} from './avatar.js';
export {BattleRoom} from './battle-room.js';

const json = (data, status = 200) => new Response(JSON.stringify(data), {
  status, headers: {'Content-Type': 'application/json', 'Cache-Control': 'no-store'},
});
const fail = (message, status = 400) => { throw Object.assign(new Error(message), {status}); };
export async function tokenHash(token) {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token)))]
    .map(x => x.toString(16).padStart(2, '0')).join('');
}
export function validSubscription(s) {
  try {
    const url = new URL(s.endpoint);
    // Only known browser push gateways may receive encrypted notifications.
    const allowed = url.hostname === 'web.push.apple.com' || url.hostname.endsWith('.push.apple.com') ||
      url.hostname === 'fcm.googleapis.com' || url.hostname === 'updates.push.services.mozilla.com' ||
      url.hostname.endsWith('.notify.windows.com');
    return allowed && url.protocol === 'https:' && !url.port && !url.username && !url.password &&
      s.endpoint.length < 2048 && /^[A-Za-z0-9_-]{87}$/.test(s.keys.p256dh) &&
      /^[A-Za-z0-9_-]{22}$/.test(s.keys.auth);
  } catch { return false; }
}
// Comparison key for names: dotted/dotless i, accents, case, spaces,
// punctuation and emoji are ignored ("ARIFE" == "arife 🌷", "mqcän" == "mqcan").
export const nameKey = name => String(name || '').normalize('NFKD').replace(/\p{M}/gu, '')
  .replace(/[İIı]/g, 'i').toLowerCase().replace(/[^\p{L}\p{N}]/gu, '');
async function body(request) {
  if (Number(request.headers.get('Content-Length') || 0) > 4096) fail('İstek çok büyük.', 413);
  const value = await request.text();
  if (value.length > 4096) fail('İstek çok büyük.', 413);
  try { return JSON.parse(value); } catch { fail('Geçersiz istek.'); }
}
// Arcade games with their own leaderboard (game_scores). Block Blast keeps players.best.
export const GAMES = ['flappy', 'subway', 'tower'];
async function board(env, playerId) {
  // `avatar` is only a version tag; the photo itself needs an authenticated /avatar request.
  const {results} = await env.DB.prepare(`SELECT p.id, p.name, p.best, p.active, a.version AS avatar,
    f.size AS avatarFull, f.width AS avatarWidth, f.height AS avatarHeight
    FROM players p LEFT JOIN avatars a ON a.player_id = p.id
    LEFT JOIN avatar_full f ON f.player_id = p.id AND f.version = a.version ORDER BY p.best DESC, p.id`).all();
  const {results: scores} = await env.DB.prepare('SELECT player_id AS id, game, best FROM game_scores ORDER BY game, best DESC').all();
  const other = await env.DB.prepare('SELECT COUNT(*) AS count FROM subscriptions WHERE player_id != ?').bind(playerId).first();
  const latest = playerId === 1 ? await env.DB.prepare(
    'SELECT sent, attempts, created, delivery_status FROM notifications WHERE player_id = 2 ORDER BY id DESC LIMIT 1').first() : null;
  return {lastNotification: latest, players: results, scores, me: playerId, otherCanReceive: other.count > 0,
    otherRegisteredDevices: other.count, publicKey: env.VAPID_PUBLIC_KEY};
}

// Home screen data in one request: flights and cork-board notes.
// A trip stays visible for a day after arrival ("vardı!"); a note for 24 h.
// Reads only filter; old rows are deleted on writes.
const NOTE_TTL = 86400;
async function home(env, me) {
  const now = Math.floor(Date.now() / 1000);
  const {results: trips} = await env.DB.prepare(`SELECT t.id, t.player_id AS player, p.name, t.destination, t.arrival, t.created
    FROM trips t JOIN players p ON p.id = t.player_id WHERE t.arrival >= ? ORDER BY t.arrival, t.id LIMIT 20`)
    .bind(now - 86400).all();
  const {results: notes} = await env.DB.prepare(`SELECT n.id, n.player_id AS player, p.name, n.text, n.created,
    n.created + ${NOTE_TTL} AS expires FROM notes n JOIN players p ON p.id = n.player_id
    WHERE n.deleted = 0 AND n.created > ? ORDER BY n.player_id LIMIT 2`).bind(now - NOTE_TTL).all();
  return {trips, notes, now, me};
}
const pruneNotes = env => env.DB.prepare('DELETE FROM notes WHERE created <= ?')
  .bind(Math.floor(Date.now() / 1000) - NOTE_TTL).run();
const pruneTrips = env => env.DB.prepare('DELETE FROM trips WHERE arrival < ?')
  .bind(Math.floor(Date.now() / 1000) - 86400).run();

export async function route(request, env, ctx) {
  const path = new URL(request.url).pathname;
  if (path === '/health' && request.method === 'GET') return json({ok: true});
  // Per-IP limit before any token/database work: blocks code guessing and
  // keeps the Free plan quota from being burned. Normal play stays far below.
  if (env.REQUEST_LIMIT) {
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const {success} = await env.REQUEST_LIMIT.limit({key: ip});
    if (!success) fail('Çok fazla istek. Biraz bekleyip tekrar dene.', 429);
  }
  if (path.startsWith('/battle/socket/')) {
    const room = path.split('/').at(-1);
    if (!validRoom(room) || request.headers.get('Upgrade')?.toLowerCase() !== 'websocket' ||
        request.headers.get('Origin') !== env.APP_ORIGIN) fail('Geçersiz bağlantı.',403);
    const url = new URL(request.url);
    const ticket = url.searchParams.get('ticket') || '';
    if (ticket.length > 100) fail('Geçersiz bağlantı.',401);
    return env.BATTLES.get(env.BATTLES.idFromName(room)).fetch(
      new Request('https://room/socket?ticket='+encodeURIComponent(ticket),request));
  }
  const token = request.headers.get('Authorization')?.replace(/^Bearer /, '') || '';
  if (!/^[A-Za-z0-9_-]{43}$/.test(token)) fail('Oyuncu kodunu kontrol et.', 401);
  const hash = await tokenHash(token);
  // Optional battle-only test identity (no DB record, no leaderboard, no
  // persistent state). It exists only when the TEST_PLAYER_HASH secret is set;
  // production leaves it unset because an earlier test code is public in git.
  const testHash = typeof env.TEST_PLAYER_HASH === 'string' && /^[0-9a-f]{64}$/.test(env.TEST_PLAYER_HASH)
    ? env.TEST_PLAYER_HASH : null;
  const player = testHash && hash === testHash
    ? {id: 0, name: 'Test Oyuncu', active: 1, token_hash: hash}
    : await env.DB.prepare('SELECT * FROM players WHERE token_hash = ?').bind(hash).first();
  if (!player) fail('Oyuncu kodunu kontrol et.', 401);
  const isTestPlayer = player.id === 0;
  if (path === '/message' && player.id !== 1) fail('Bildirim gönderme yetkisi yalnızca Oyuncu 1\u2019e aittir.', 403);
  if (path === '/board' && request.method === 'GET') return json(await board(env, player.id));
  if (['/home', '/trips', '/trips/delete', '/notes', '/notes/delete'].includes(path)) {
    if (isTestPlayer) fail('Bu bölüm yalnız kayıtlı oyunculara açıktır.', 403);
    if (!player.active) fail('Önce oyuncu adını kaydet.', 403);
    if ((path === '/home' || path === '/trips') && request.method === 'GET') return json(await home(env, player.id));
  }
  if (isTestPlayer && ['/profile', '/score', '/subscribe', '/unsubscribe'].includes(path))
    return json({ok: true, players: [], me: 0});
  if (path === '/avatar' || path === '/avatar/delete' || path === '/avatar/full') {
    if (isTestPlayer) fail('Profil fotoğrafları yalnız kayıtlı oyunculara açıktır.', 403);
    if (!player.active) fail('Önce oyuncu adını kaydet.', 403);
    if (path === '/avatar/full') return avatarFullRoute(request, env, player, board, json);
    return avatarRoute(request, env, player, path, board, json);
  }
  if (request.method !== 'POST') fail('Bulunamadı.', 404);
  const data = await body(request);
  if (path === '/profile') {
    const name = typeof data.name === 'string' ? data.name.trim() : '';
    // Control, zero-width and bidirectional override characters could hide or spoof a name.
    if (name.length < 1 || name.length > 24 ||
        /[\x00-\x1f\x7f-\x9f\u200b-\u200f\u2028-\u202e\u2060-\u2069\ufeff]/.test(name)) fail('1–24 karakterlik bir isim yaz.');
    // No impersonation: a name may not match the other player's, ignoring
    // case, spaces, punctuation and emoji ("mqcan 😎" == "MQCAN").
    const other = await env.DB.prepare('SELECT name FROM players WHERE id != ?').bind(player.id).first();
    if (other && nameKey(other.name) && nameKey(other.name) === nameKey(name)) fail('Bu isim diğer oyuncuya ait.');
    await env.DB.prepare('UPDATE players SET name = ?, active = 1 WHERE id = ?').bind(name, player.id).run();
    return json(await board(env, player.id));
  }
  if (!player.active) fail('Önce oyuncu adını kaydet.');
  if (path === '/battle/create' || path === '/battle/join') {
    const room = path.endsWith('/create') ? roomCode() : String(data.room || '').toUpperCase();
    if (!validRoom(room)) fail('6 karakterlik oda kodunu kontrol et.');
    if (!env.BATTLES) fail('Battle servisi henüz etkin değil.',503);
    return env.BATTLES.get(env.BATTLES.idFromName(room)).fetch(new Request(
      'https://room/'+(path.endsWith('/create')?'create':'join'),
      {method:'POST',body:JSON.stringify({room,id:player.id,name:player.name})}));
  }
  if (path === '/trips') {
    const destination = typeof data.destination === 'string' ? data.destination.trim() : '';
    if (destination.length < 1 || destination.length > 40 ||
        /[\x00-\x1f\x7f-\x9f\u200b-\u200f\u2028-\u202e\u2060-\u2069\ufeff]/.test(destination)) fail('1–40 karakterlik bir varış yeri yaz.');
    const now = Math.floor(Date.now() / 1000);
    if (!Number.isSafeInteger(data.arrival) || data.arrival < now - 300) fail('Varış zamanı gelecekte olmalı.');
    if (data.arrival > now + 2 * 365 * 86400) fail('Varış en fazla iki yıl sonrası olabilir.');
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM trips WHERE player_id = ? AND arrival > ?').bind(player.id, now).first();
    if (count.count >= 10) fail('En fazla 10 yaklaşan uçuş eklenebilir.');
    await env.DB.prepare('INSERT INTO trips(player_id, destination, arrival, created) VALUES (?, ?, ?, ?)')
      .bind(player.id, destination, data.arrival, now).run();
    await pruneTrips(env);
    return json(await home(env, player.id));
  }
  if (path === '/trips/delete') {
    // Everyone removes their own flights; Player 1 (admin) can remove any.
    if (!Number.isSafeInteger(data.id)) fail('Geçersiz uçuş.');
    await env.DB.prepare('DELETE FROM trips WHERE id = ? AND (player_id = ? OR ? = 1)').bind(data.id, player.id, player.id).run();
    await pruneTrips(env);
    return json(await home(env, player.id));
  }
  if (path === '/notes') {
    const text = typeof data.text === 'string' ? data.text.trim().replace(/\r\n?/g, '\n') : '';
    if (text.length < 1 || text.length > 200 || text.split('\n').length > 8 ||
        /[\x00-\x09\x0b-\x1f\x7f-\x9f\u200b-\u200f\u2028-\u202e\u2060-\u2069\ufeff]/.test(text)) fail('1–200 karakterlik bir not yaz.');
    const now = Math.floor(Date.now() / 1000);
    const active = await env.DB.prepare('SELECT id FROM notes WHERE player_id = ? AND deleted = 0 AND created > ?')
      .bind(player.id, now - NOTE_TTL).first();
    if (active) fail('Panoda zaten bir notun var. Yeni not için önce onu sil.', 409);
    // Notify at most once per 10 minutes per player (delete/re-post loops).
    const recent = await env.DB.prepare('SELECT id FROM notes WHERE player_id = ? AND created > ?')
      .bind(player.id, now - 600).first();
    await env.DB.prepare('INSERT INTO notes(player_id, text, created) VALUES (?, ?, ?)').bind(player.id, text, now).run();
    await pruneNotes(env);
    const other = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
    if (other && !recent) {
      await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
        .bind(other.id, `${player.name} sana not bıraktı! 📌`, 'Kaybolmadan görüntüle.').run();
      ctx.waitUntil(deliver(env));
    }
    return json(await home(env, player.id));
  }
  if (path === '/notes/delete') {
    // Own note; Player 1 (admin) can remove any. Kept as deleted until expiry.
    if (!Number.isSafeInteger(data.id)) fail('Geçersiz not.');
    await env.DB.prepare('UPDATE notes SET deleted = 1 WHERE id = ? AND (player_id = ? OR ? = 1)').bind(data.id, player.id, player.id).run();
    return json(await home(env, player.id));
  }
  if (path === '/score') {
    if (!Number.isSafeInteger(data.score) || data.score < 0 || data.score > 100000000) fail('Geçersiz skor.');
    const game = data.game ?? 'block';
    if (game !== 'block' && !GAMES.includes(game)) fail('Geçersiz oyun.');
    // MAX and the SQL triggers run atomically: retries cannot lower scores or duplicate overtakes.
    if (game === 'block') {
      await env.DB.prepare('UPDATE players SET best = MAX(best, ?) WHERE id = ?').bind(data.score, player.id).run();
    } else {
      await env.DB.prepare(`INSERT INTO game_scores(player_id, game, best) VALUES (?, ?, ?)
        ON CONFLICT(player_id, game) DO UPDATE SET best = MAX(best, excluded.best)`).bind(player.id, game, data.score).run();
    }
    ctx.waitUntil(deliver(env));
    return json(await board(env, player.id));
  }
  if (path === '/subscribe') {
    if (!validSubscription(data)) fail('Geçersiz bildirim aboneliği.');
    // Two phones, with a small allowance for reinstalling or a second device.
    const existing = await env.DB.prepare('SELECT player_id FROM subscriptions WHERE endpoint = ?').bind(data.endpoint).first();
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM subscriptions WHERE player_id = ?').bind(player.id).first();
    if (!existing && count.count >= 5) fail('Cihaz sınırına ulaşıldı. Eski cihazda bildirimleri kapat.');
    await env.DB.prepare('INSERT INTO subscriptions(endpoint, player_id, subscription) VALUES (?, ?, ?) ON CONFLICT(endpoint) DO UPDATE SET player_id=excluded.player_id, subscription=excluded.subscription')
      .bind(data.endpoint, player.id, JSON.stringify(data)).run();
    return json({ok: true});
  }
  if (path === '/unsubscribe') {
    await env.DB.prepare('DELETE FROM subscriptions WHERE endpoint = ? AND player_id = ?').bind(String(data.endpoint), player.id).run();
    return json({ok: true});
  }
  if (path === '/message') {
    const message = typeof data.message === 'string' ? data.message.trim() : '';
    if (!message || message.length > 180) fail('1–180 karakterlik bir mesaj yaz.');
    // self:true → yalnızca yöneticinin kendi cihazlarına önizleme (nasıl göründüğünü görmek için).
    const toSelf = data.self === true;
    const target = toSelf ? {id: player.id}
      : await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
    if (!target) fail('Diğer oyuncu henüz katılmadı.');
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM subscriptions WHERE player_id = ?').bind(target.id).first();
    if (!count.count) fail(toSelf
      ? 'Bu hesabın kayıtlı bildirim cihazı yok. Uygulamayı ana ekrandan açıp Bildirimleri aç düğmesine dokun.'
      : 'Diğer oyuncunun kayıtlı bildirim cihazı yok. Uygulamayı ana ekrandan açıp Bildirimleri aç düğmesine dokunması gerekiyor.');
    // Atomic cooldown prevents double taps/retries from sending multiple messages.
    const now = Math.floor(Date.now()/1000);
    const result = await env.DB.prepare('UPDATE players SET last_message = ? WHERE id = ? AND last_message <= ? RETURNING id')
      .bind(now, player.id, now-30).first();
    if (!result) fail('Yeni bildirim için 30 saniye bekle.', 429);
    await env.DB.prepare('INSERT INTO notifications(player_id, title, body) VALUES (?, ?, ?)')
      .bind(target.id, `${player.name} sana mesaj gönderdi`, message).run();
    ctx.waitUntil(deliver(env));
    return json({ok: true, message: 'Bildirim gönderim sırasına alındı.'});
  }
  fail('Bulunamadı.', 404);
}

export async function deliver(env, send = sendPush) {
  const now = Math.floor(Date.now()/1000);
  // Claim a bounded batch. An expired lease can be retried by the five-minute cron.
  const {results} = await env.DB.prepare(`UPDATE notifications SET attempted = ?, attempts = attempts + 1
    WHERE id IN (SELECT id FROM notifications WHERE sent = 0 AND attempts < 4
    AND attempted < ? AND created > ? ORDER BY id LIMIT 4) RETURNING *`)
    .bind(now, now-120, now-3600).all();
  for (const event of results) {
    const {results: subscriptions} = await env.DB.prepare('SELECT * FROM subscriptions WHERE player_id = ?').bind(event.player_id).all();
    let retry = false;
    let accepted = false;
    let deliveryStatus = 'no_device';
    for (const entry of subscriptions) {
      try {
        const status = await send(JSON.parse(entry.subscription), {
          title: event.title, body: event.body, tag: `event-${event.id}`, url: env.APP_URL,
        }, env);
        if (status >= 200 && status < 300) {
          accepted = true;
          deliveryStatus = 'accepted';
        } else {
          deliveryStatus = `http_${status}`;
          console.warn('push_rejected', {eventId: event.id, status});
        }
        if (status === 404 || status === 410) {
          await env.DB.prepare('DELETE FROM subscriptions WHERE endpoint = ?').bind(entry.endpoint).run();
        } else if (status >= 300) retry = true;
      } catch (error) {
        retry = true;
        deliveryStatus = error.name === 'TimeoutError' ? 'timeout' : 'send_error';
        // Never log payloads, endpoint URLs or keys.
        console.warn('push_failed', {eventId: event.id, type: error.name});
      }
    }
    await env.DB.prepare('UPDATE notifications SET sent = ?, delivery_status = ? WHERE id = ?')
      .bind(!retry ? 1 : 0, accepted ? (retry ? 'partial' : 'accepted') : deliveryStatus, event.id).run();
  }
  await env.DB.prepare('DELETE FROM notifications WHERE created < ?').bind(now-86400*7).run();
}
export async function sendPush(subscription, payload, env, transport = fetch) {
  const details = webpush.generateRequestDetails(subscription, JSON.stringify(payload), {
    TTL: 3600,
    vapidDetails: {subject: env.VAPID_SUBJECT, publicKey: env.VAPID_PUBLIC_KEY, privateKey: env.VAPID_PRIVATE_KEY},
  });
  const response = await transport(details.endpoint, {
    method: details.method, headers: details.headers, body: details.body,
    // Workers reject redirect:'error' before making any request. Manual mode
    // prevents forwarding VAPID credentials; 3xx remains a delivery failure.
    redirect: 'manual', signal: AbortSignal.timeout(10000),
  });
  await response.body?.cancel();
  return response.status;
}
export default {
  async fetch(request, env, ctx) {
    const origin = request.headers.get('Origin');
    if (origin && origin !== env.APP_ORIGIN) return json({error:'İzin verilmeyen kaynak.'}, 403);
    let response;
    if (request.method === 'OPTIONS') response = new Response(null, {status:204});
    else {
      try { response = await route(request, env, ctx); }
      catch (error) {
        if (!error.status) console.error('worker_failed', {type:error.name, stack:error.stack?.split('\n').slice(1,4)});
        response = json({error:error.status ? error.message : 'Servise ulaşılamadı. Biraz sonra tekrar dene.'}, error.status || 500); }
    }
    if (response.status === 101) return response;
    response = new Response(response.body, response);
    response.headers.set('Access-Control-Allow-Origin', env.APP_ORIGIN);
    response.headers.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set('Vary', 'Origin');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('Referrer-Policy', 'no-referrer');
    response.headers.set('X-Frame-Options', 'DENY');
    response.headers.set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
    return response;
  },
  scheduled(_event, env, ctx) { ctx.waitUntil(deliver(env)); },
};
