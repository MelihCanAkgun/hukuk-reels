'use strict';
// tools/build_web.py injects a content hash and an atomic offline game shell.
const CACHE = 'hukuk-games-__BUILD_VERSION__';
const CORE = __CORE_FILES__;
self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(CORE)));
  // A new version waits until the user chooses to reload or closes all tabs.
});
self.addEventListener('message', (event) => {
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
    // Music is loaded on demand. Do not fill the offline game cache with it.
    return fetch(request);
  })());
});
