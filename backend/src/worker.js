import webpush from 'web-push';

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
async function body(request) {
  if (Number(request.headers.get('Content-Length') || 0) > 4096) fail('İstek çok büyük.', 413);
  const value = await request.text();
  if (value.length > 4096) fail('İstek çok büyük.', 413);
  try { return JSON.parse(value); } catch { fail('Geçersiz istek.'); }
}
async function board(env, playerId) {
  const {results} = await env.DB.prepare('SELECT id, name, best, active FROM players ORDER BY best DESC, id').all();
  const other = await env.DB.prepare('SELECT COUNT(*) AS count FROM subscriptions WHERE player_id != ?').bind(playerId).first();
  const latest = playerId === 1 ? await env.DB.prepare(
    'SELECT sent, attempts, created, delivery_status FROM notifications WHERE player_id = 2 ORDER BY id DESC LIMIT 1').first() : null;
  return {lastNotification: latest, players: results, me: playerId, otherCanReceive: other.count > 0,
    otherRegisteredDevices: other.count, publicKey: env.VAPID_PUBLIC_KEY};
}

export async function route(request, env, ctx) {
  const path = new URL(request.url).pathname;
  if (path === '/health' && request.method === 'GET') return json({ok: true});
  const token = request.headers.get('Authorization')?.replace(/^Bearer /, '') || '';
  if (!/^[A-Za-z0-9_-]{43}$/.test(token)) fail('Oyuncu kodunu kontrol et.', 401);
  const player = await env.DB.prepare('SELECT * FROM players WHERE token_hash = ?').bind(await tokenHash(token)).first();
  if (!player) fail('Oyuncu kodunu kontrol et.', 401);
  if (path === '/message' && player.id !== 1) fail('Bildirim gönderme yetkisi yalnızca Oyuncu 1’e aittir.', 403);
  if (path === '/board' && request.method === 'GET') return json(await board(env, player.id));
  if (request.method !== 'POST') fail('Bulunamadı.', 404);
  const data = await body(request);
  if (path === '/profile') {
    const name = typeof data.name === 'string' ? data.name.trim() : '';
    if (name.length < 1 || name.length > 24 || /[\x00-\x1f\x7f]/.test(name)) fail('1–24 karakterlik bir isim yaz.');
    await env.DB.prepare('UPDATE players SET name = ?, active = 1 WHERE id = ?').bind(name, player.id).run();
    return json(await board(env, player.id));
  }
  if (!player.active) fail('Önce oyuncu adını kaydet.');
  if (path === '/score') {
    if (!Number.isSafeInteger(data.score) || data.score < 0 || data.score > 100000000) fail('Geçersiz skor.');
    // MAX and the SQL trigger run atomically: retries cannot lower scores or duplicate overtakes.
    await env.DB.prepare('UPDATE players SET best = MAX(best, ?) WHERE id = ?').bind(data.score, player.id).run();
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
    const target = await env.DB.prepare('SELECT id FROM players WHERE id != ? AND active = 1').bind(player.id).first();
    if (!target) fail('Diğer oyuncu henüz katılmadı.');
    const count = await env.DB.prepare('SELECT COUNT(*) AS count FROM subscriptions WHERE player_id = ?').bind(target.id).first();
    if (!count.count) fail('Diğer oyuncunun kayıtlı bildirim cihazı yok. Uygulamayı ana ekrandan açıp Bildirimleri aç düğmesine dokunması gerekiyor.');
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
      catch (error) { response = json({error:error.status ? error.message : 'Servise ulaşılamadı. Biraz sonra tekrar dene.'}, error.status || 500); }
    }
    response.headers.set('Access-Control-Allow-Origin', env.APP_ORIGIN);
    response.headers.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set('Vary', 'Origin');
    return response;
  },
  scheduled(_event, env, ctx) { ctx.waitUntil(deliver(env)); },
};
