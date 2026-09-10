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

// Web Push is handled by the existing offline worker, including when the app is closed.
self.addEventListener('push', (event) => {
  let data = {};
  try { data = event.data?.json() || {}; } catch (_) {}
  event.waitUntil(self.registration.showNotification(data.title || 'Block Blast', {
    body: data.body || 'Yeni bir bildirimin var.',
    icon: new URL('icons/Icon-192.png', self.registration.scope).href,
    tag: data.tag || 'block-blast',
    data: {url: self.registration.scope},
  }));
});
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    for (const client of windows) {
      if (client.url.startsWith(self.registration.scope) && 'focus' in client) return client.focus();
    }
    return self.clients.openWindow(self.registration.scope);
  })());
});
