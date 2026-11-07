{{flutter_js}}
{{flutter_build_config}}

// Görüntü motoru: Ayarlar → Uygulama'dan seçilir. 'wasm' seçiliyse Safari'de
// de WebAssembly (skwasm) derlemesi açılır (Flutter WebKit'te varsayılan
// olarak kapalı tutar); seçilmediyse Flutter'ın varsayılanı. WebAssembly
// açılışı yarıda kalır ya da hata verirse bir sonraki açılış JS'e döner.
(function () {
  const KEY = 'hukuk_engine', BOOT = 'hukuk_engine_boot';
  const get = (k) => { try { return localStorage.getItem(k); } catch (_) { return null; } };
  const put = (k, v) => { try { v == null ? localStorage.removeItem(k) : localStorage.setItem(k, v); } catch (_) {} };

  let mode = get(KEY);
  if (mode === 'wasm' && get(BOOT) === 'pending') {
    console.warn('[Flutter] WebAssembly açılışı tamamlanmamış; JavaScript motoruna dönülüyor.');
    mode = 'js';
    put(KEY, 'js');
  }
  // Servis çalışanı bir sonraki sürümde WebAssembly dosyalarını önceden
  // indirsin mi (web/sw.js 'hukuk-engine' işaretini okur).
  const mark = (value) => {
    try {
      return caches.open('hukuk-engine').then((c) => c.put('mode', new Response(value))).catch(() => {});
    } catch (_) { return Promise.resolve(); }
  };
  window.hukukSetEngine = (next) => {
    if (next !== 'wasm' && next !== 'js') return false;
    put(KEY, next);
    put(BOOT, null);
    mark(next).then(() => location.reload());
    return true;
  };

  const config = { canvasKitBaseUrl: 'canvaskit/', canvasKitVariant: 'full' };
  if (mode) void mark(mode);
  if (mode === 'wasm') {
    config.wasmAllowList = { blink: true, webkit: true, gecko: true, unknown: false };
    put(BOOT, 'pending');
  } else if (mode === 'js') {
    config.renderer = 'canvaskit';
  }

  _flutter.loader.load({ config: config }).then(function () {
    put(BOOT, null);
  }).catch(function (error) {
    console.error('[Flutter]', error);
    if (mode === 'wasm') {
      put(KEY, 'js');
      void mark('js');
      put(BOOT, null);
      location.reload();
      return;
    }
    const loading = document.getElementById('loading');
    if (loading) {
      loading.textContent = 'Uygulama yüklenemedi. Bağlantını kontrol edip yeniden aç.';
      loading.style.color = '#ffffff';
    }
  });
})();
