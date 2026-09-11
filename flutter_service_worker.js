'use strict';
// tools/build_web.py injects a content hash and an atomic offline game shell.
const CACHE = 'hukuk-games-a4705547c484c916';
const CORE = [".last_build_id", "assets/AssetManifest.bin", "assets/AssetManifest.bin.json", "assets/FontManifest.json", "assets/NOTICES", "assets/assets/fonts/Inter.ttf", "assets/assets/images/SHINY_Cuh.png", "assets/assets/images/ani.jpg", "assets/assets/images/bat.png", "assets/assets/images/cat_pink.png", "assets/assets/images/dopdolu.jpg", "assets/assets/images/spider_cat.png", "assets/assets/sfx/clear.wav", "assets/assets/sfx/combo.wav", "assets/assets/sfx/over.wav", "assets/assets/sfx/place.wav", "assets/fonts/MaterialIcons-Regular.otf", "assets/packages/cupertino_icons/assets/CupertinoIcons.ttf", "assets/shaders/ink_sparkle.frag", "assets/shaders/stretch_effect.frag", "audio.js", "battle.js", "canvaskit/canvaskit.js", "canvaskit/canvaskit.wasm", "flutter.js", "flutter_bootstrap.js", "icons/favicon.png", "icons/icon-128x128.png", "icons/icon-144x144.png", "icons/icon-152x152.png", "icons/icon-167x167.png", "icons/icon-180x180.png", "icons/icon-192x192.png", "icons/icon-512x512.png", "icons/icon-72x72.png", "icons/icon-96x96.png", "icons/splash-1170x2532.png", "icons/splash-1290x2796.png", "icons/splash-1640x2360.png", "icons/splash-750x1334.png", "index.html", "main.dart.js", "manifest.json", "social.js", "version.json"];
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
