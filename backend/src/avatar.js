// Profile photos for the two registered players only.
//
// - Two copies: a small display JPEG (`avatars`, synced to both players) and
//   an optional full-quality JPEG (`avatar_full*`) only Player 1 can download.
// - Stored in D1 (never on GitHub Pages); every request needs a player's
//   Bearer code. The battle-only test identity is refused.
// - Only small baseline/progressive JPEGs are accepted. EXIF/XMP/ICC
//   (APP1–APP15) and comment segments are removed server-side as a second
//   line of defence (the client already re-encodes through a canvas), so
//   GPS/location or device metadata can never be stored.
// - Responses are JSON with `no-store`; image bytes are never served with an
//   image/HTML content type, so they cannot be embedded or sniffed elsewhere.

export const AVATAR_MAX_BYTES = 96 * 1024;
// Full-quality copy (edited on the device, re-encoded through a canvas).
export const FULL_MAX_BYTES = 12 * 1024 * 1024;
const FULL_MAX_CHARS = Math.ceil(FULL_MAX_BYTES / 3) * 4;
const FULL_MAX_SIDE = 8192;
const PART_CHARS = 1_000_000; // D1 values are limited to ~2 MB.
// Only the header is decoded and cleaned: scanning a multi-megabyte body
// in JS would exceed the Free plan's CPU budget.
const FULL_HEAD_CHARS = 64 * 1024; // canvas JPEG headers are a few KB
const MAX_BODY_CHARS = Math.ceil(AVATAR_MAX_BYTES * 4 / 3) + 512;
const MAX_SIDE = 1024;
const UPLOAD_COOLDOWN_SECONDS = 10;

const err = (message, status = 400) => Object.assign(new Error(message), {status});

/** Returns the JPEG without metadata segments, or throws a 4xx error. */
export function sanitizeJpeg(bytes) {
  const bad = () => err('Fotoğraf geçersiz. Lütfen başka bir fotoğraf seç.');
  if (!(bytes instanceof Uint8Array) || bytes.length < 64) throw bad();
  if (bytes.length > AVATAR_MAX_BYTES) throw err('Fotoğraf çok büyük.', 413);
  if (bytes[0] !== 0xFF || bytes[1] !== 0xD8) throw bad();
  if (bytes[bytes.length - 2] !== 0xFF || bytes[bytes.length - 1] !== 0xD9) throw bad();
  const parts = [bytes.subarray(0, 2)];
  let i = 2, width = 0, height = 0, scan = false;
  while (i + 4 <= bytes.length) {
    if (bytes[i] !== 0xFF) throw bad();
    const marker = bytes[i + 1];
    if (marker === 0xFF) { i++; continue; }
    // Standalone markers are not valid before the first scan.
    if (marker === 0xD8 || marker === 0xD9 || marker === 0x01 || (marker >= 0xD0 && marker <= 0xD7)) throw bad();
    const length = (bytes[i + 2] << 8) | bytes[i + 3];
    if (length < 2 || i + 2 + length > bytes.length) throw bad();
    if (marker === 0xDA) { parts.push(bytes.subarray(i)); scan = true; break; }
    const isFrame = marker >= 0xC0 && marker <= 0xCF && ![0xC4, 0xC8, 0xCC].includes(marker);
    if (isFrame) {
      if (length < 8) throw bad();
      height = (bytes[i + 5] << 8) | bytes[i + 6];
      width = (bytes[i + 7] << 8) | bytes[i + 8];
    }
    const metadata = (marker >= 0xE1 && marker <= 0xEF) || marker === 0xFE;
    if (!metadata) parts.push(bytes.subarray(i, i + 2 + length));
    i += 2 + length;
  }
  if (!scan || !width || !height || width > MAX_SIDE || height > MAX_SIDE) throw bad();
  const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let o = 0;
  for (const p of parts) { out.set(p, o); o += p.length; }
  return out;
}

export function toBase64(bytes) {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

function fromBase64(text) {
  if (typeof text !== 'string' || text.length > MAX_BODY_CHARS || !/^[A-Za-z0-9+/]+={0,2}$/.test(text)) {
    throw err('Fotoğraf geçersiz. Lütfen başka bir fotoğraf seç.');
  }
  const raw = atob(text);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes;
}

async function readUpload(request) {
  if (Number(request.headers.get('Content-Length') || 0) > MAX_BODY_CHARS + 64) throw err('Fotoğraf çok büyük.', 413);
  const value = await request.text();
  if (value.length > MAX_BODY_CHARS + 64) throw err('Fotoğraf çok büyük.', 413);
  try { return JSON.parse(value); } catch { throw err('Geçersiz istek.'); }
}

async function version(bytes) {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return [...digest.slice(0, 10)].map(x => x.toString(16).padStart(2, '0')).join('');
}

const BASE64_TAIL = /^[A-Za-z0-9+/]{2}(?:[A-Za-z0-9+/]{2}|[A-Za-z0-9+/]=|==)$/;

/**
 * Cleans a base64 full-quality JPEG without decoding all of it. Only the
 * header (up to the first scan) is decoded: metadata segments (EXIF/XMP/
 * Photoshop-IPTC/comment; Safari's encoder adds EXIF + APP13) are removed,
 * the colour profile (APP2 "ICC_PROFILE") and Adobe APP14 are kept. The rest
 * of the base64 text is reused as-is; to keep it aligned, JPEG fill bytes
 * (0xFF before a marker) make the removed length a multiple of 3.
 * Returns {text, width, height, size}.
 */
export function cleanFullJpeg(text) {
  const bad = () => err('Fotoğraf geçersiz. Lütfen başka bir fotoğraf seç.');
  if (typeof text !== 'string' || text.length < 88 || text.length % 4) throw bad();
  if (text.length > FULL_MAX_CHARS) throw err('Fotoğraf çok büyük.', 413);
  if (!BASE64_TAIL.test(text.slice(-4))) throw bad();
  const whole = text.length <= FULL_HEAD_CHARS + 4;
  const headText = whole ? text : text.slice(0, FULL_HEAD_CHARS);
  if (!(whole ? /^[A-Za-z0-9+/]+={0,2}$/ : /^[A-Za-z0-9+/]+$/).test(headText)) throw bad();
  const decode = t => {
    const raw = atob(t), out = new Uint8Array(raw.length);
    for (let k = 0; k < raw.length; k++) out[k] = raw.charCodeAt(k);
    return out;
  };
  const head = decode(headText);
  const tail = decode(text.slice(-8));
  if (tail[tail.length - 2] !== 0xFF || tail[tail.length - 1] !== 0xD9) throw bad();
  if (head[0] !== 0xFF || head[1] !== 0xD8) throw bad();
  const kept = [head.subarray(0, 2)];
  let i = 2, width = 0, height = 0;
  for (;;) {
    if (i + 4 > head.length || head[i] !== 0xFF) throw bad();
    const marker = head[i + 1];
    if (marker === 0xFF) { i++; continue; }
    if (marker === 0xD8 || marker === 0xD9 || marker === 0x01 || (marker >= 0xD0 && marker <= 0xD7)) throw bad();
    if (marker === 0xDA) break;
    const length = (head[i + 2] << 8) | head[i + 3];
    if (length < 2 || i + 2 + length > head.length) throw bad();
    const icc = marker === 0xE2 && length > 14 &&
      String.fromCharCode(...head.subarray(i + 4, i + 16)) === 'ICC_PROFILE\0';
    const metadata = (marker >= 0xE1 && marker <= 0xEF && !icc && marker !== 0xEE) || marker === 0xFE;
    if (!metadata) kept.push(head.subarray(i, i + 2 + length));
    if (marker >= 0xC0 && marker <= 0xCF && ![0xC4, 0xC8, 0xCC].includes(marker)) {
      if (length < 8) throw bad();
      height = (head[i + 5] << 8) | head[i + 6];
      width = (head[i + 7] << 8) | head[i + 8];
    }
    i += 2 + length;
  }
  if (!width || !height || width > FULL_MAX_SIDE || height > FULL_MAX_SIDE) throw bad();
  const keptLength = kept.reduce((n, p) => n + p.length, 0);
  const fill = whole ? 0 : (i - keptLength) % 3;
  const rebuilt = new Uint8Array(keptLength + fill + head.length - i);
  let o = 0;
  for (const p of kept) { rebuilt.set(p, o); o += p.length; }
  rebuilt.fill(0xFF, o, o + fill);
  rebuilt.set(head.subarray(i), o + fill);
  const out = toBase64(rebuilt) + (whole ? '' : text.slice(FULL_HEAD_CHARS));
  const pad = out.endsWith('==') ? 2 : out.endsWith('=') ? 1 : 0;
  return {text: out, width, height, size: out.length / 4 * 3 - pad};
}

/** Removes the full-quality copy (when only a display photo is uploaded or the photo is deleted). */
function clearFull(env, playerId) {
  return [
    env.DB.prepare('DELETE FROM avatar_full WHERE player_id = ?').bind(playerId),
    env.DB.prepare('DELETE FROM avatar_full_parts WHERE player_id = ?').bind(playerId),
  ];
}

async function runAll(env, statements) {
  if (env.DB.batch) return env.DB.batch(statements); // atomic on D1
  for (const s of statements) await s.run();
}

async function checkCooldown(env, playerId, now) {
  const last = await env.DB.prepare('SELECT updated FROM avatars WHERE player_id = ?').bind(playerId).first();
  if (last && last.updated > now - UPLOAD_COOLDOWN_SECONDS) throw err('Yeni fotoğraf için birkaç saniye bekle.', 429);
}

/**
 * GET  /avatar/full?id=1|2 → base64 text of the full-quality JPEG (Player 1 only)
 * POST /avatar/full        → text body "<display JPEG base64>\n<full JPEG base64>"; board
 */
export async function avatarFullRoute(request, env, player, board, json) {
  if (request.method === 'GET') {
    if (player.id !== 1) throw err('Tam boyutlu fotoğrafları yalnız Oyuncu 1 indirebilir.', 403);
    const id = Number(new URL(request.url).searchParams.get('id'));
    if (id !== 1 && id !== 2) throw err('Geçersiz oyuncu.');
    const meta = await env.DB.prepare(`SELECT f.version, f.parts, f.size FROM avatar_full f
      JOIN avatars a ON a.player_id = f.player_id AND a.version = f.version WHERE f.player_id = ?`).bind(id).first();
    if (!meta) throw err('Bu fotoğrafın tam boyutlu kopyası yok.', 404);
    let part = 0;
    const encoder = new TextEncoder();
    const body = new ReadableStream({
      async pull(controller) {
        if (part >= meta.parts) { controller.close(); return; }
        const row = await env.DB.prepare('SELECT data FROM avatar_full_parts WHERE player_id = ? AND version = ? AND part = ?')
          .bind(id, meta.version, part++).first();
        if (!row) { controller.error(new Error('missing part')); return; }
        controller.enqueue(encoder.encode(row.data));
      },
    });
    return new Response(body, {headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Content-Disposition': 'attachment',
      'Cache-Control': 'no-store',
      'X-Avatar-Version': meta.version,
      'X-Avatar-Size': String(meta.size),
      'Access-Control-Expose-Headers': 'X-Avatar-Version, X-Avatar-Size',
    }});
  }
  if (request.method !== 'POST') throw err('Bulunamadı.', 404);
  const limit = FULL_MAX_CHARS + MAX_BODY_CHARS + 16;
  if (Number(request.headers.get('Content-Length') || 0) > limit) throw err('Fotoğraf çok büyük.', 413);
  const text = await request.text();
  if (text.length > limit) throw err('Fotoğraf çok büyük.', 413);
  const nl = text.indexOf('\n');
  if (nl < 0) throw err('Geçersiz istek.');
  const thumb = sanitizeJpeg(fromBase64(text.slice(0, nl)));
  const info = cleanFullJpeg(text.slice(nl + 1));
  const full = info.text;
  const now = Math.floor(Date.now() / 1000);
  await checkCooldown(env, player.id, now);
  const ver = await version(thumb);
  const parts = Math.ceil(full.length / PART_CHARS);
  // Parts first (a failure leaves only unreferenced rows), then switch over atomically.
  for (let p = 0; p < parts; p++) {
    await env.DB.prepare('INSERT OR REPLACE INTO avatar_full_parts(player_id, version, part, data) VALUES (?, ?, ?, ?)')
      .bind(player.id, ver, p, full.slice(p * PART_CHARS, (p + 1) * PART_CHARS)).run();
  }
  await runAll(env, [
    env.DB.prepare(`INSERT INTO avatars(player_id, data, version, updated) VALUES (?, ?, ?, ?)
      ON CONFLICT(player_id) DO UPDATE SET data = excluded.data, version = excluded.version, updated = excluded.updated`)
      .bind(player.id, toBase64(thumb), ver, now),
    env.DB.prepare(`INSERT INTO avatar_full(player_id, version, size, width, height, parts) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(player_id) DO UPDATE SET version = excluded.version, size = excluded.size,
      width = excluded.width, height = excluded.height, parts = excluded.parts`)
      .bind(player.id, ver, info.size, info.width, info.height, parts),
    env.DB.prepare('DELETE FROM avatar_full_parts WHERE player_id = ? AND (version != ? OR part >= ?)').bind(player.id, ver, parts),
  ]);
  return json(await board(env, player.id));
}

/**
 * GET  /avatar?id=1|2   → {id, version, data}   (404 when none)
 * POST /avatar {data}   → board (stores the sanitized JPEG)
 * POST /avatar/delete   → board
 * `player` is an authenticated, active, registered player (id 1 or 2).
 */
export async function avatarRoute(request, env, player, path, board, json) {
  if (path === '/avatar' && request.method === 'GET') {
    const id = Number(new URL(request.url).searchParams.get('id'));
    if (id !== 1 && id !== 2) throw err('Geçersiz oyuncu.');
    const row = await env.DB.prepare('SELECT version, data FROM avatars WHERE player_id = ?').bind(id).first();
    if (!row) throw err('Profil fotoğrafı yok.', 404);
    const response = json({id, version: row.version, data: row.data});
    response.headers.set('X-Content-Type-Options', 'nosniff');
    return response;
  }
  if (request.method !== 'POST') throw err('Bulunamadı.', 404);
  if (path === '/avatar/delete') {
    await runAll(env, [env.DB.prepare('DELETE FROM avatars WHERE player_id = ?').bind(player.id), ...clearFull(env, player.id)]);
    return json(await board(env, player.id));
  }
  const data = await readUpload(request);
  const clean = sanitizeJpeg(fromBase64(data?.data));
  const now = Math.floor(Date.now() / 1000);
  await checkCooldown(env, player.id, now);
  // A display-only upload (older app version) replaces the full-quality copy too.
  await runAll(env, [env.DB.prepare(`INSERT INTO avatars(player_id, data, version, updated) VALUES (?, ?, ?, ?)
    ON CONFLICT(player_id) DO UPDATE SET data = excluded.data, version = excluded.version, updated = excluded.updated`)
    .bind(player.id, toBase64(clean), await version(clean), now), ...clearFull(env, player.id)]);
  return json(await board(env, player.id));
}
