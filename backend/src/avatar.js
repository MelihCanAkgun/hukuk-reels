// Profile photos for the two registered players only.
//
// - Stored in D1 (never on GitHub Pages); every request needs a player's
//   Bearer code. The battle-only test identity is refused.
// - Only small baseline/progressive JPEGs are accepted. EXIF/XMP/ICC
//   (APP1–APP15) and comment segments are removed server-side as a second
//   line of defence (the client already re-encodes through a canvas), so
//   GPS/location or device metadata can never be stored.
// - Responses are JSON with `no-store`; image bytes are never served with an
//   image/HTML content type, so they cannot be embedded or sniffed elsewhere.

export const AVATAR_MAX_BYTES = 96 * 1024;
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
    await env.DB.prepare('DELETE FROM avatars WHERE player_id = ?').bind(player.id).run();
    return json(await board(env, player.id));
  }
  const data = await readUpload(request);
  const clean = sanitizeJpeg(fromBase64(data?.data));
  const now = Math.floor(Date.now() / 1000);
  const last = await env.DB.prepare('SELECT updated FROM avatars WHERE player_id = ?').bind(player.id).first();
  if (last && last.updated > now - UPLOAD_COOLDOWN_SECONDS) throw err('Yeni fotoğraf için birkaç saniye bekle.', 429);
  await env.DB.prepare(`INSERT INTO avatars(player_id, data, version, updated) VALUES (?, ?, ?, ?)
    ON CONFLICT(player_id) DO UPDATE SET data = excluded.data, version = excluded.version, updated = excluded.updated`)
    .bind(player.id, toBase64(clean), await version(clean), now).run();
  return json(await board(env, player.id));
}
