'use strict';
// tools/build_web.py injects a content hash and an atomic offline game shell.
const VERSION = '__BUILD_VERSION__';
const CACHE = 'hukuk-games-' + VERSION;
const CORE = __CORE_FILES__;
// WebAssembly engine (main.dart.wasm + skwasm): precached only on a device
// that chose it in Settings (flutter_bootstrap.js writes the 'hukuk-engine'
// marker); otherwise cached the first time it is fetched.
const WASM = __WASM_FILES__;
const scoped = (path) => new URL(path, self.registration.scope).href;
async function wantsWasm() {
  try {
    const marker = await (await caches.open('hukuk-engine')).match('mode');
    return marker ? (await marker.text()) === 'wasm' : false;
  } catch (_) { return false; }
}
self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const files = (await wantsWasm()) ? CORE.concat(WASM) : CORE;
    const cache = await caches.open(CACHE);
    await cache.addAll(files.map((path) => new Request(scoped(path), {cache: 'reload'})));
  })());
  // A new version waits until the user chooses to reload or closes all tabs.
});
self.addEventListener('message', (event) => {
  if (event.data === 'getVersion') event.ports[0]?.postMessage(VERSION);
  if (event.data === 'skipWaiting') self.skipWaiting();
});
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((key) => key.startsWith('hukuk-games-') && key !== CACHE)
      .map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin ||
      !url.href.startsWith(self.registration.scope) || request.headers.has('range')) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const key = request.mode === 'navigate' ? new URL('index.html', self.registration.scope).href : request;
    const cached = await cache.match(key);
    if (cached) return cached;
    if (WASM.some((path) => scoped(path) === url.href)) {
      const response = await fetch(request);
      if (response.ok) await cache.put(request, response.clone());
      return response;
    }
    // Music is loaded on demand. Do not fill the offline game cache with it.
    return fetch(request);
  })());
});

// Web Push is handled by the existing offline worker, including when the app is closed.
self.addEventListener('push', (event) => {
  let data = {};
  try { data = event.data?.json() || {}; } catch (_) {}
  event.waitUntil(self.registration.showNotification(data.title || 'Block Blast', {
    body: data.body || 'Yeni bir bildirimin var.',
    icon: new URL('icons/icon-192x192.png', self.registration.scope).href,
    tag: data.tag || 'block-blast',
    renotify: data.tag === 'battle-invite',
    data: {url: new URL(data.url || './', self.registration.scope).href},
  }));
});
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || self.registration.scope;
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    // Açık uygulama öne gelir (davetse oda koduyla); yoksa yeni pencere açılır.
    const open = windows.find(client => client.url.startsWith(self.registration.scope) && 'focus' in client);
    if (open) {
      const room = new URL(url).searchParams.get('oda');
      if (room) open.postMessage({hukukInvite: room});
      return open.focus();
    }
    return self.clients.openWindow(url);
  })());
});
