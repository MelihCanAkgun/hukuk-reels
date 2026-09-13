(() => {
  'use strict';
  const key = 'hukuk-update-pending';
  const pageVersion = document.querySelector('meta[name="app-build"]')?.content;
  const saved = (value) => {
    try {
      if (value === undefined) return sessionStorage.getItem(key);
      if (value === null) sessionStorage.removeItem(key);
      else sessionStorage.setItem(key, value);
    } catch (_) { /* Updating also works when storage is unavailable. */ }
  };
  function versionOf(worker) {
    return new Promise((resolve, reject) => {
      const channel = new MessageChannel();
      const timer = setTimeout(() => { channel.port1.close(); reject(new Error('Sürüm yanıtı alınamadı')); }, 4000);
      channel.port1.onmessage = (event) => {
        clearTimeout(timer); channel.port1.close(); resolve(event.data);
      };
      worker.postMessage('getVersion', [channel.port2]);
    });
  }
  window.addEventListener('flutter-first-frame', async () => {
    document.getElementById('loading')?.remove();
    if (!('serviceWorker' in navigator)) return;
    const sw = navigator.serviceWorker;
    let applying = false, reloading = false, target = null, timer;
    function reloadWhenReady() {
      if (!applying || reloading || sw.controller !== target) return;
      reloading = true;
      clearTimeout(timer);
      window.location.reload();
    }
    sw.addEventListener('controllerchange', reloadWhenReady);
    function notice(title, detail, success = false) {
      document.getElementById('update-app')?.remove();
      const card = document.createElement('section');
      card.id = 'update-app';
      card.className = success ? 'update-card success' : 'update-card';
      card.setAttribute('role', 'status');
      card.setAttribute('aria-live', 'polite');
      const icon = document.createElement('span');
      icon.className = 'update-icon'; icon.textContent = success ? '✓' : '↗';
      icon.setAttribute('aria-hidden', 'true');
      const copy = document.createElement('div'); copy.className = 'update-copy';
      const heading = document.createElement('strong'); heading.textContent = title;
      const description = document.createElement('p'); description.textContent = detail;
      copy.append(heading, description); card.append(icon, copy); document.body.appendChild(card);
      return {card, heading, description};
    }
    try {
      if (saved() && sw.controller) {
        const activeVersion = await versionOf(sw.controller).catch(() => null);
        if (activeVersion === pageVersion && saved() === pageVersion) {
          saved(null);
          const {card} = notice('Güncelleme tamamlandı!', 'En yeni sürüm hazır. Keyfini çıkar ✨', true);
          setTimeout(() => card.remove(), 6000);
        }
      }
      const reg = await sw.register('flutter_service_worker.js', {updateViaCache: 'none'});
      function offerUpdate() {
        if (!reg.waiting || !sw.controller || applying) return;
        const {card, heading, description} = notice('Yeni bir şeyler var ✨', 'Yeni sürüm hazır. Hazır olduğunda güncelle.');
        const button = document.createElement('button'); button.textContent = 'Şimdi güncelle';
        card.appendChild(button);
        button.onclick = async () => {
          if (applying) return;
          target = reg.waiting;
          if (!target) { card.remove(); return; }
          applying = true; button.disabled = true;
          card.classList.add('applying'); button.textContent = 'Güncelleniyor…';
          heading.textContent = 'Son dokunuşlar yapılıyor';
          description.textContent = 'Uygulama birazdan yeniden açılacak.';
          try {
            const version = await versionOf(target);
            saved(version);
            timer = setTimeout(() => {
              if (reloading) return;
              applying = false; saved(null); card.classList.remove('applying');
              heading.textContent = 'Güncelleme tamamlanamadı';
              description.textContent = 'Tekrar deneyebilirsin.';
              button.disabled = false; button.textContent = 'Tekrar dene';
            }, 20000);
            target.postMessage('skipWaiting');
            reloadWhenReady();
          } catch (_) {
            applying = false; saved(null); card.classList.remove('applying');
            heading.textContent = 'Güncellemeye ulaşılamadı';
            description.textContent = 'Biraz sonra tekrar dene.';
            button.disabled = false; button.textContent = 'Tekrar dene';
          }
        };
      }
      offerUpdate();
      function watch(worker) {
        worker?.addEventListener('statechange', () => {
          if (worker.state === 'installed') offerUpdate();
        });
      }
      watch(reg.installing);
      reg.addEventListener('updatefound', () => watch(reg.installing));
      document.addEventListener('visibilitychange', () => {
        if (!document.hidden && !applying) reg.update().catch(() => {});
      });
    } catch (error) { console.warn('[PWA]', error); }
  }, {once: true});
})();
