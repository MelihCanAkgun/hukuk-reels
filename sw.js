// ─────────────────────────────────────────────────────
// Hukuk Reels — Custom Service Worker
// Cache-first stratejisi ile tam çevrimdışı destek
// ─────────────────────────────────────────────────────

const CACHE_NAME = 'hukuk-reels-v1';

// Önceden önbelleğe alınacak kaynaklar
const PRE_CACHE = [
  './',
  './index.html',
  './manifest.json',
  './flutter_bootstrap.js',
  './icons/icon-192x192.png',
  './icons/icon-512x512.png',
];

// ── INSTALL: Ön önbellekleme ──
self.addEventListener('install', (event) => {
  console.log('[SW] Install');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRE_CACHE).catch((err) => {
        // Pre-cache hataları kritik değil — devam et
        console.warn('[SW] Pre-cache kısmen başarısız:', err);
      });
    })
  );
  // Eski SW'yi beklemeden aktif ol
  self.skipWaiting();
});

// ── ACTIVATE: Eski önbellekleri temizle ──
self.addEventListener('activate', (event) => {
  console.log('[SW] Activate');
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => {
            console.log('[SW] Eski cache siliniyor:', key);
            return caches.delete(key);
          })
      );
    })
  );
  // Tüm açık sekmelerde hemen devral
  self.clients.claim();
});

// ── FETCH: Cache-first, network fallback ──
self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Sadece GET isteklerini önbellekle
  if (request.method !== 'GET') return;

  // Navigation istekleri → index.html (SPA routing)
  if (request.mode === 'navigate') {
    event.respondWith(
      caches.match('./index.html').then((cached) => {
        return cached || fetch(request).then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        });
      }).catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Statik kaynaklar → Cache-first
  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;

      return fetch(request).then((response) => {
        // Geçerli yanıtları önbelleğe al
        if (response.ok && response.type === 'basic') {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
        }
        return response;
      }).catch(() => {
        // Çevrimdışı ve cache'te yok → basit fallback
        if (request.destination === 'image') {
          return new Response(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
            { headers: { 'Content-Type': 'image/svg+xml' } }
          );
        }
        return new Response('Çevrimdışı — içerik önbellekte bulunamadı.', {
          status: 503,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
      });
    })
  );
});
