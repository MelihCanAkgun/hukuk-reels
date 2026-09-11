'use strict';
(() => {
  const storageKey = 'hukuk_social_v1';
  let config = {url: '', token: '', best: 0};
  try { Object.assign(config, JSON.parse(localStorage.getItem(storageKey) || '{}')); } catch (_) {}
  let lastBoard = null;
  let sending = false;
  let verifiedSubscription = '';
  let scoreTimer;
  const persist = () => localStorage.setItem(storageKey, JSON.stringify(config));
  async function api(path, data, token = config.token) {
    if (!config.url) throw new Error('İki kişilik servis henüz etkinleştirilmedi.');
    const response = await fetch(config.url + path, {
      method: data === undefined ? 'GET' : 'POST',
      headers: {Authorization: 'Bearer ' + token, ...(data === undefined ? {} : {'Content-Type': 'application/json'})},
      ...(data === undefined ? {} : {body: JSON.stringify(data)}),
      cache: 'no-store', signal: AbortSignal.timeout(12000),
    });
    const result = await response.json();
    if (!response.ok) throw Object.assign(new Error(result.error || 'Bağlantı kurulamadı.'), {status:response.status});
    return result;
  }
  async function flush() {
    if (sending || !config.token || !config.url || document.hidden) return;
    const mine = lastBoard?.players?.find(p => p.id === lastBoard.me);
    if (mine && config.best <= mine.best) return;
    sending = true;
    const token = config.token;
    try {
      const next = await api('/score', {score: config.best}, token);
      if (token === config.token) lastBoard = next;
    } catch (_) { /* The local maximum is retained for online/resume/timer retry. */ }
    finally { sending = false; }
  }
  async function pushState() {
    const supported = 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
    const reg = supported ? await navigator.serviceWorker.getRegistration() : null;
    const sub = reg ? await reg.pushManager.getSubscription() : null;
    const permission = supported ? Notification.permission : 'unsupported';
    let pushError;
    const key = sub && config.token ? config.token + ':' + sub.endpoint : '';
    // Recover an interrupted server registration without asking for permission again.
    if (sub && permission === 'granted' && config.token && config.url && verifiedSubscription !== key) {
      try {
        await api('/subscribe', sub.toJSON());
        config.endpoint = sub.endpoint;
        persist();
        verifiedSubscription = key;
      } catch (e) { pushError = 'Bildirim izni açık, ancak cihaz kaydedilemedi: ' + e.message; }
    }
    return {supported, subscribed: !!key && verifiedSubscription === key && permission === 'granted', permission, pushError};
  }
  async function state(refresh = true) {
    let error;
    if (config.token && config.url && refresh) {
      try { lastBoard = await api('/board'); void flush(); }
      catch (e) { error = e.message; }
    }
    return {configured: !!config.url, connected: !!config.token, ...lastBoard,
      ...(await pushState()), pending: config.best > (lastBoard?.players?.find(p=>p.id===lastBoard.me)?.best || 0), error};
  }
  async function call(action, data) {
    if (action === 'init') {
      if (data.url && /^https:\/\//.test(data.url)) config.url = data.url.replace(/\/$/, '');
      if (!data.url) config.url = '';
      return state(false);
    }
    if (action === 'state') return state();
    if (action === 'battleCreate' || action === 'battleJoin') {
      return {...await api(action === 'battleCreate' ? '/battle/create' : '/battle/join', data), url:config.url};
    }
    if (action === 'join') {
      const token = data.token.trim();
      if (!/^[A-Za-z0-9_-]{43}$/.test(token)) throw new Error('Sana ait oyuncu kodunu eksiksiz yapıştır.');
      const result = await api('/profile', {name: data.name}, token);
      config.token = token;
      config.best = Math.max(0, Number(data.score) || 0);
      persist();
      lastBoard = result;
      await flush();
      return state(false);
    }
    if (action === 'score') {
      if (config.token && Number.isSafeInteger(data.score) && data.score > config.best) {
        config.best = data.score;
        persist();
        clearTimeout(scoreTimer);
        scoreTimer = setTimeout(flush, 600);
      }
      return {};
    }
    if (action === 'subscribe') {
      // Invoke permission before any await to preserve Safari's user activation.
      if (!('Notification' in window) || !('PushManager' in window)) {
        throw new Error('iPhone’da uygulamayı Ana Ekrana Ekle ile yükleyip oradan aç (iOS 16.4+).');
      }
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') throw new Error('Bildirim izni verilmedi. Telefonun bildirim ayarlarından izin verebilirsin.');
      let timer;
      const reg = await Promise.race([
        navigator.serviceWorker.ready,
        new Promise((_, reject) => { timer = setTimeout(() => reject(new Error('Uygulama güncellemesini tamamlayıp tekrar dene.')), 12000); }),
      ]).finally(() => clearTimeout(timer));
      let sub = await reg.pushManager.getSubscription();
      if (!sub) {
        const key = lastBoard?.publicKey;
        if (!key) throw new Error('Bildirim servisi henüz hazır değil.');
        const decoded = atob(key.replace(/-/g, '+').replace(/_/g, '/'));
        sub = await reg.pushManager.subscribe({userVisibleOnly: true, applicationServerKey: Uint8Array.from(decoded, c=>c.charCodeAt(0))});
      }
      await api('/subscribe', sub.toJSON());
      config.endpoint = sub.endpoint; persist();
      verifiedSubscription = config.token + ':' + sub.endpoint;
      return state(false);
    }
    if (action === 'unsubscribe' || action === 'leave') {
      const reg = await navigator.serviceWorker?.getRegistration();
      const sub = reg ? await reg.pushManager.getSubscription() : null;
      if (sub) {
        await api('/unsubscribe', {endpoint: sub.endpoint});
        await sub.unsubscribe();
        config.endpoint = ''; verifiedSubscription = ''; persist();
      }
      if (action === 'leave') {
        config.token = ''; config.best = 0; verifiedSubscription = ''; lastBoard = null; persist();
      }
      return state(false);
    }
    if (action === 'message') return api('/message', {message: data.message});
    throw new Error('İşlem bulunamadı.');
  }
  window.hukukSocialCall = (action, raw) => call(action, JSON.parse(raw)).then(
    data=>JSON.stringify(data), e=>JSON.stringify({error:e.message || 'Bağlantı kurulamadı.', status:e.status}));
  window.addEventListener('online', () => void flush());
  document.addEventListener('visibilitychange', () => { if (!document.hidden) void flush(); });
  setInterval(flush, 30000);
})();
