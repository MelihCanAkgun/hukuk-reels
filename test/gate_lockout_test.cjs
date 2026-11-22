// Erişim kapısı: iki gerçek oyuncunun web/social.js tarafında kilitlenmediğini
// doğrular. Çalıştır: node test/gate_lockout_test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const source = fs.readFileSync('web/social.js', 'utf8');
const key = 'hukuk_social_v1';
const token = 'A'.repeat(43);
const url = 'https://social.example';
// Kapıdan önceki biçim: `me` yok (iki gerçek oyuncunun cihazındaki kayıt).
const oldFormat = JSON.stringify({url, token, best: 120, bests: {flappy: 4}, blockSeason: 2, plays: {}});

// social.js'i yeni bir sayfa yüklemesi gibi çalıştırır. `respond(path)` bir
// Response benzeri döndürür ya da fırlatır (çevrimdışı).
function load({store = new Map(), respond = () => { throw new TypeError('Failed to fetch'); }, storage = 'ok'} = {}) {
  const requests = [];
  const localStorage = {
    getItem: k => { if (storage === 'throw') throw new Error('SecurityError'); return store.has(k) ? store.get(k) : null; },
    setItem: (k, v) => { if (storage !== 'ok') throw new Error('QuotaExceededError'); store.set(k, String(v)); },
    removeItem: k => { if (storage === 'throw') throw new Error('SecurityError'); store.delete(k); },
  };
  const window = {addEventListener() {}};
  const ctx = vm.createContext({
    window, localStorage, console, JSON, Promise, Error, TypeError, URL, AbortSignal, Uint8Array, atob,
    document: {hidden: false, addEventListener() {}},
    navigator: {userAgent: 'iPhone', maxTouchPoints: 5},
    setInterval: () => 0, setTimeout: () => 0, clearTimeout() {},
    fetch: async (u, opts = {}) => { requests.push({u, auth: opts.headers?.Authorization}); return respond(u.replace(url, '')); },
  });
  vm.runInContext(source, ctx);
  const call = async (action, data = {}) => JSON.parse(await window.hukukSocialCall(action, JSON.stringify(data)));
  return {store, call, requests};
}
const res = (status, body = {}) => ({status, ok: status >= 200 && status < 300, json: async () => body});
const board = {me: 2, players: [{id: 1, best: 0}, {id: 2, best: 120}], scores: []};
const tick = () => new Promise(r => setImmediate(r));

async function main() {
  const results = [];
  const scenario = async (name, fn) => {
    try { await fn(); results.push(['PASS', name]); }
    catch (e) { results.push(['FAIL', name, e.message]); process.exitCode = 1; }
  };

  await scenario('1 offline startup keeps stored code', async () => {
    const {store, call} = load({store: new Map([[key, oldFormat]])});
    await tick();
    assert.deepEqual(await call('recheck', {url}), {ok: false, reason: 'offline'});
    assert.equal(JSON.parse(store.get(key)).token, token);
  });

  for (const [label, respond, reason] of [
    ['500', () => res(500, {error: 'x'}), 'server'],
    ['429', () => res(429, {error: 'x'}), 'rate'],
    ['403 origin', () => res(403, {error: 'x'}), 'server'],
    ['timeout', () => { throw Object.assign(new Error('timeout'), {name: 'TimeoutError'}); }, 'offline'],
    ['non-JSON 200', () => ({status: 200, ok: true, json: async () => { throw new SyntaxError('x'); }}), 'server'],
  ]) {
    await scenario(`2 recheck ${label} → not "invalid", code kept`, async () => {
      const {store, call} = load({store: new Map([[key, oldFormat]]), respond: p => p === '/board' ? respond() : res(200, {})});
      const r = await call('recheck', {url});
      assert.deepEqual(r, {ok: false, reason});
      assert.equal(JSON.parse(store.get(key)).token, token);
    });
  }

  await scenario('3 recheck 401 → invalid, stored code NOT deleted', async () => {
    const {store, call} = load({store: new Map([[key, oldFormat]]), respond: () => res(401, {error: 'Oyuncu kodunu kontrol et.'})});
    assert.deepEqual(await call('recheck', {url}), {ok: false, reason: 'invalid'});
    assert.equal(JSON.parse(store.get(key)).token, token);
    assert.equal(JSON.parse(store.get(key)).best, 120);
  });

  await scenario('4 PWA update: existing storage survives reload, me cached', async () => {
    const store = new Map([[key, oldFormat]]);
    const first = load({store, respond: p => p === '/board' ? res(200, board) : res(200, {})});
    await tick();
    assert.equal(JSON.parse(store.get(key)).token, token, 'startup does not drop the token');
    assert.deepEqual(await first.call('recheck', {url}), {ok: true, me: 2});
    load({store}); // "new version" loads the same localStorage
    await tick();
    const saved = JSON.parse(store.get(key));
    assert.equal(saved.token, token); assert.equal(saved.me, 2); assert.equal(saved.best, 120);
  });

  await scenario('5a localStorage throws on every access: loads, verify does not crash', async () => {
    const {call} = load({storage: 'throw', respond: () => res(200, board)});
    const r = await call('verify', {url, token});
    assert.equal(typeof r, 'object');
  });

  await scenario('5b setItem throws (Safari private): valid code can still pass verify', async () => {
    const {call} = load({storage: 'readonly', respond: () => res(200, board)});
    const r = await call('verify', {url, token});
    assert.equal(r.ok, true, `verify returned ${JSON.stringify(r)}`);
  });

  await scenario('6 leave clears the token (next launch shows the gate)', async () => {
    const {store, call} = load({store: new Map([[key, oldFormat]]), respond: p => p === '/board' ? res(200, board) : res(200, {})});
    await call('leave');
    assert.equal(JSON.parse(store.get(key)).token, '');
  });

  for (const bad of ['{', 'not json', '{"token":"' + token + '",']) {
    await scenario(`7 malformed stored JSON ${JSON.stringify(bad.slice(0, 12))} → no crash, value not wiped`, async () => {
      const store = new Map([[key, bad]]);
      load({store});
      await tick();
      assert.equal(store.get(key), bad);
    });
  }

  await scenario('8 old format (no me): token untouched at startup, recheck adds me', async () => {
    const store = new Map([[key, oldFormat]]);
    const {call} = load({store, respond: p => p === '/board' ? res(200, board) : res(200, {})});
    await tick();
    assert.equal(store.get(key), oldFormat, 'startup rewrites nothing');
    assert.deepEqual(await call('recheck', {url}), {ok: true, me: 2});
    assert.equal(JSON.parse(store.get(key)).token, token);
  });

  await scenario('9 recheck 401 marks revoked (token kept); verify clears it', async () => {
    const store = new Map([[key, oldFormat]]);
    const {call} = load({store, respond: () => res(401, {})});
    assert.deepEqual(await call('recheck', {url}), {ok: false, reason: 'invalid'});
    let saved = JSON.parse(store.get(key));
    assert.equal(saved.token, token); assert.equal(saved.revoked, true);
    const again = load({store, respond: p => p === '/board' ? res(200, board) : res(200, {})});
    assert.equal((await again.call('verify', {url, token})).ok, true);
    saved = JSON.parse(store.get(key));
    assert.equal(saved.revoked, undefined); assert.equal(saved.best, 120, 'same code keeps scores');
  });

  await scenario('10 stale recheck 401 for an old code does not mark the new one', async () => {
    const fresh = 'B'.repeat(43);
    let releaseSlow;
    const slow = new Promise(r => { releaseSlow = r; });
    let first = true;
    // İlk /board (recheck, eski kod) gecikir ve 401 döner; verify hemen 200.
    const page = load({store: new Map([[key, oldFormat]]), respond: async (p) => {
      if (p === '/board' && first) { first = false; await slow; return res(401, {}); }
      return res(200, {me: 2});
    }});
    const stale = page.call('recheck', {url});
    await tick();
    assert.equal((await page.call('verify', {url, token: fresh})).ok, true);
    releaseSlow();
    assert.deepEqual(await stale, {ok: true});
    const saved = JSON.parse(page.store.get(key));
    assert.equal(saved.token, fresh); assert.equal(saved.revoked, undefined);
  });

  await scenario('11 verify with another player\'s code resets per-player data', async () => {
    const store = new Map([[key, JSON.stringify({...JSON.parse(oldFormat), me: 1, legacyBest: 9}) ],
      ['hukuk_home_v1', '{}'], ['hukuk_films_v1', '{}'], ['hukuk_weekly_v1', '{}']]);
    const {call} = load({store, respond: () => res(200, {me: 2})});
    assert.equal((await call('verify', {url, token: 'C'.repeat(43)})).ok, true);
    const saved = JSON.parse(store.get(key));
    assert.equal(saved.token, 'C'.repeat(43)); assert.equal(saved.me, 2);
    assert.equal(saved.best, 0); assert.deepEqual(saved.bests, {}); assert.equal(saved.legacyBest, undefined);
    assert.equal(store.has('hukuk_home_v1'), false); assert.equal(store.has('hukuk_weekly_v1'), false);
  });

  for (const r of results) console.log(r.join(' | '));
}
main().catch(e => { console.error(e); process.exitCode = 1; });
