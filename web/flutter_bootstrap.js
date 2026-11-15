{{flutter_js}}
{{flutter_build_config}}

// Görüntü motoru: varsayılan WebAssembly (skwasm), Safari dahil (Flutter
// WebKit'te varsayılan olarak kapalı tutar). Ayarlar → Uygulama'dan
// JavaScript'e (CanvasKit) geçilebilir. WebAssembly açılışı yarıda kalır ya
// da hata verirse bir sonraki açılış JS'e döner. Servis çalışanı sayfayı
// cross-origin isolated sunduğunda skwasm çizimi ayrı bir iş parçacığında
// yapar (web/sw.js).
(function () {
  const KEY = 'hukuk_engine', BOOT = 'hukuk_engine_boot', FAIL = 'hukuk_engine_fail';
  const get = (k) => { try { return localStorage.getItem(k); } catch (_) { return null; } };
  const put = (k, v) => { try { v == null ? localStorage.removeItem(k) : localStorage.setItem(k, v); } catch (_) {} };

  // Tek bir yarım kalan ya da hatalı WebAssembly açılışı (uygulama yüklenirken
  // kapatıldı, bağlantı koptu) yalnız bir sonraki açılışı JavaScript'e
  // düşürür; WebAssembly sonra yeniden denenir. Üst üste MAX_FAILS kez
  // başarısız olursa cihaz kalıcı olarak JavaScript'e geçer (Ayarlar'dan
  // yeniden açılabilir).
  const MAX_FAILS = 3;
  const preferred = get(KEY) === 'js' ? 'js' : 'wasm';
  const boot = get(BOOT);
  let fails = Number(get(FAIL)) || 0;
  let mode = preferred;
  if (mode === 'wasm' && boot === 'pending') put(FAIL, String(++fails));
  if (mode === 'wasm' && fails >= MAX_FAILS) {
    console.warn('[Flutter] WebAssembly üst üste açılamadı; JavaScript motoruna geçiliyor.');
    mode = 'js';
    put(KEY, 'js');
    put(FAIL, null);
  } else if (mode === 'wasm' && (boot === 'pending' || boot === 'fallback')) {
    console.warn('[Flutter] Önceki WebAssembly açılışı tamamlanmadı; bu açılış JavaScript ile.');
    mode = 'js';
  }
  put(BOOT, null);
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
    put(FAIL, null);
    mark(next).then(() => location.reload());
    return true;
  };

  const config = { canvasKitBaseUrl: 'canvaskit/', canvasKitVariant: 'full' };
  void mark(get(KEY) === 'js' ? 'js' : 'wasm');
  if (mode === 'wasm') {
    config.wasmAllowList = { blink: true, webkit: true, gecko: true, unknown: false };
    put(BOOT, 'pending');
  } else {
    config.renderer = 'canvaskit';
  }

  _flutter.loader.load({ config: config }).then(function () {
    put(BOOT, null);
    if (mode === 'wasm') put(FAIL, null);
  }).catch(function (error) {
    console.error('[Flutter]', error);
    if (mode === 'wasm') {
      put(FAIL, String(fails + 1));
      put(BOOT, 'fallback');
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
