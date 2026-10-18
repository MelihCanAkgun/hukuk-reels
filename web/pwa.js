'use strict';
// Satır içi betik yerine ayrı dosya: içerik güvenlik politikası (CSP) satır
// içi betiklere izin vermez.

// Başka bir sitenin çerçevesi (iframe) içinde açılmayı reddet (clickjacking).
if (window.top !== window.self) {
  document.documentElement.style.display = 'none';
  try { window.top.location.replace(window.self.location.href); } catch (_) {}
}

// ── Android Chrome PWA Install Prompt ──
let _deferredInstallPrompt = null;

window.addEventListener('beforeinstallprompt', function (e) {
  e.preventDefault();
  _deferredInstallPrompt = e;
});

// Flutter'dan çağrılabilir: Chrome'un native install dialog'unu göster
async function triggerInstallPrompt() {
  if (!_deferredInstallPrompt) return false;
  _deferredInstallPrompt.prompt();
  const result = await _deferredInstallPrompt.userChoice;
  _deferredInstallPrompt = null;
  return result.outcome === 'accepted';
}

// PWA modunda mı çalışıyor kontrolü
function isRunningStandalone() {
  return window.matchMedia('(display-mode: standalone)').matches
      || window.navigator.standalone === true;
}

window.addEventListener('appinstalled', function () {
  _deferredInstallPrompt = null;
});

// ── Güvenli alan (çentik, ana ekran çizgisi) ──
// Flutter web iOS'un güvenli alan boşluklarını bilmez (MediaQuery.padding
// hep 0): alt sekme çubuğu ana ekran çizgisinin altına ve ekranın yuvarlak
// köşesine taşar. Boşluklar CSS env() ile ölçülüp Flutter'a verilir.
(function () {
  let probe = null;
  window.hukukSafeArea = function () {
    if (!probe) {
      probe = document.createElement('div');
      probe.setAttribute('aria-hidden', 'true');
      probe.style.cssText = 'position:fixed;left:0;top:0;width:0;height:0;'
        + 'visibility:hidden;pointer-events:none;padding:'
        + 'env(safe-area-inset-top) env(safe-area-inset-right) '
        + 'env(safe-area-inset-bottom) env(safe-area-inset-left)';
      document.body.appendChild(probe);
    }
    const cs = getComputedStyle(probe);
    const px = (v) => Math.max(0, parseFloat(v) || 0);
    const insets = {
      top: px(cs.paddingTop), right: px(cs.paddingRight),
      bottom: px(cs.paddingBottom), left: px(cs.paddingLeft),
    };
    // Ana ekrandan açılan uygulamada env() 0 dönerse: ana ekran çizgili
    // iPhone'larda (Face ID, uzun kenar ≥ 812) çizginin payı.
    if (insets.bottom === 0 && navigator.standalone === true
        && /iPhone/.test(navigator.userAgent)
        && Math.max(screen.width, screen.height) >= 812) {
      insets.bottom = window.innerWidth > window.innerHeight ? 21 : 34;
    }
    return JSON.stringify(insets);
  };
})();
