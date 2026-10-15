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
