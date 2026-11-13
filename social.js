'use strict';
(() => {
  const storageKey = 'hukuk_social_v1';
  // best: Block Blast; bests: the arcade games' personal bests (own leaderboards).
  const games = ['flappy', 'subway', 'tower'];
  let config = {url: '', token: '', best: 0, bests: {}};
  try { Object.assign(config, JSON.parse(localStorage.getItem(storageKey) || '{}')); } catch (_) {}
  if (!config.bests || typeof config.bests !== 'object') config.bests = {};
  let lastBoard = null;
  let sending = false;
  let verifiedSubscription = '';
  let scoreTimer;
  const persist = () => localStorage.setItem(storageKey, JSON.stringify(config));
  // Haftalık meydan okuma: turu yönetici başlatır, 7 gün sürer. Oynanan
  // skorlar zamanıyla saklanır (plays) ve sunucuya gönderilir; hangi tura
  // sayılacağına sunucu karar verir (tur başlamadan yapılan skor sayılmaz).
  // Bir oyunun listesinde skorlar zamanla azalır: yeni skor, kendinden düşük
  // eskileri siler. round: sunucunun son bildirdiği tur ({start, end} | null).
  const weekGames = ['block', 'flappy', 'subway', 'tower'];
  const nowSec = () => Math.floor(Date.now() / 1000);
  if (!config.plays || typeof config.plays !== 'object') config.plays = {};
  const roundActive = () => !!config.round && nowSec() < config.round.end;
  function addPlay(game, score) {
    // Tur olmadığı biliniyorsa (ve bilgi tazeyse) skor saklanmaz.
    if (!roundActive() && nowSec() - (config.roundChecked || 0) < 600) return false;
    const list = config.plays[game] || [];
    const start = roundActive() ? config.round.start : Infinity;
    if (list.some(p => p.t >= start && p.s >= score)) return false;
    config.plays[game] = [...list.filter(p => p.s > score), {s: score, t: nowSec()}].slice(-12);
    return true;
  }
  const weeklyDue = () => weekGames.flatMap(g => (config.plays[g] || []).filter(p => !p.sent).map(p => ({game: g, play: p})));
  const weeklyKey = 'hukuk_weekly_v1';
  // Her yanıt turu günceller; tur dışında kalan skorlar atılır.
  function saveWeekly(r) {
    config.round = r.round ? {start: r.round.start, end: r.round.end} : null;
    config.roundChecked = nowSec();
    const start = r.round ? r.round.start : Infinity;
    for (const g of weekGames) config.plays[g] = (config.plays[g] || []).filter(p => p.t >= start);
    try { persist(); } catch (_) {}
    return saveCache(weeklyKey, r);
  }
  // Block Blast season (matches the worker): a new season zeroes this device's
  // stored record, and scores carry the season so old ones are not accepted.
  const blockSeason = 2;
  if (config.blockSeason !== blockSeason) {
    // Sent once without a season: the worker keeps it only if it beats the
    // archived record (a new record made on the old version).
    if (config.best > 0) config.legacyBest = config.best;
    config.best = 0;
    config.blockSeason = blockSeason;
    try { persist(); } catch (_) {}
  }
  // Profile photos of the two players, keyed by server version. Only fetched
  // with this device's player code; removed when the player leaves.
  const avatarKey = 'hukuk_avatar_cache_v1';
  let avatars = {};
  try { avatars = JSON.parse(localStorage.getItem(avatarKey) || '{}') || {}; } catch (_) { avatars = {}; }
  const persistAvatars = () => { try { localStorage.setItem(avatarKey, JSON.stringify(avatars)); } catch (_) {} };
  // Home data (flights + cork-board notes): last copy kept for offline use.
  const tripsKey = 'hukuk_home_v1';
  try { localStorage.removeItem('hukuk_trips_v1'); } catch (_) {}
  const saveTrips = (r) => saveCache(tripsKey, r);
  const filmsKey = 'hukuk_films_v1';
  // Önce önbellek, sonra ağ: liste ekranları son kopyayla anında açılır
  // ({cached: true} isteği ağa gitmez), güncel veri arkadan gelir. Yanıt
  // Flutter'ın elindekiyle aynıysa {unchanged: true} döner; büyük liste
  // yeniden çözülmez ve ekran boşuna yeniden kurulmaz. `now` her yanıtta
  // değiştiği için karşılaştırmaya girmez.
  const delivered = {};
  const fingerprint = (r) => JSON.stringify({...r, now: 0});
  function readCache(key) {
    try { return JSON.parse(localStorage.getItem(key) || 'null'); } catch (_) { return null; }
  }
  function saveCache(key, r) {
    const print = fingerprint(r);
    // Aynı içerik yeniden yazılmaz (localStorage yazımı ana iş parçacığını tutar).
    if (saveCache.last[key] !== print) {
      saveCache.last[key] = print;
      try { localStorage.setItem(key, JSON.stringify(r)); } catch (_) {}
    }
    return r;
  }
  saveCache.last = {};
  // Flutter'a giden yanıt: `known` (Flutter'da veri var) ve içerik aynıysa kısa yanıt.
  function deliver(key, r, known) {
    const print = fingerprint(r);
    const same = known && delivered[key] === print;
    delivered[key] = print;
    return same ? {unchanged: true, connected: true} : {...r, connected: true};
  }
  const saveFilms = (r) => saveCache(filmsKey, r);
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
  // Full-quality photos (Player 1 only), kept in memory per version so a
  // second tap can save without downloading again.
  const fullCache = {};
  async function bigRequest(path, body) {
    if (!config.url || !config.token) throw new Error('Önce sıralamaya oyuncu kodunla katıl.');
    const response = await fetch(config.url + path, {
      method: body === undefined ? 'GET' : 'POST',
      headers: {Authorization: 'Bearer ' + config.token, ...(body === undefined ? {} : {'Content-Type': 'text/plain'})},
      ...(body === undefined ? {} : {body}),
      cache: 'no-store', signal: AbortSignal.timeout(180000),
    });
    if (!response.ok) {
      let message = 'Bağlantı kurulamadı.';
      try { message = (await response.json()).error || message; } catch (_) {}
      throw Object.assign(new Error(message), {status: response.status});
    }
    return response;
  }
  // Server copy of this player's best for a game (Block Blast lives in players).
  function serverBest(game) {
    if (!lastBoard) return null;
    if (game === 'block') return lastBoard.players?.find(p => p.id === lastBoard.me)?.best ?? null;
    return lastBoard.scores?.find(r => r.id === lastBoard.me && r.game === game)?.best ?? 0;
  }
  const localBest = game => game === 'block' ? config.best : (config.bests[game] || 0);
  const pendingGames = () => ['block', ...games].filter(g => localBest(g) > (serverBest(g) ?? 0));
  async function flush() {
    if (sending || !config.token || !config.url || document.hidden) return;
    const due = ['block', ...games].filter(g => localBest(g) > 0 && !(serverBest(g) !== null && localBest(g) <= serverBest(g)));
    if (!due.length && !(config.legacyBest > 0) && !weeklyDue().length) return;
    sending = true;
    const token = config.token;
    try {
      if (config.legacyBest > 0) {
        lastBoard = await api('/score', {score: config.legacyBest}, token);
        delete config.legacyBest;
        persist();
      }
      for (const game of due) {
        const next = await api('/score', game === 'block' ? {score: config.best, season: blockSeason} : {game, score: localBest(game)}, token);
        if (token !== config.token) break;
        lastBoard = next;
      }
      // Rekorlardan sonra: sunucu aynı anda iki bildirim göndermesin.
      for (const {game, play} of weeklyDue()) {
        const next = await api('/weekly/score', {game, score: play.s, at: play.t}, token);
        if (token !== config.token) break;
        play.sent = true;
        saveWeekly(next);
      }
    } catch (_) { /* The local maximum is retained for online/resume/timer retry. */ }
    finally { sending = false; }
  }
  // Son görülme: uygulama açılınca ya da öne gelince bir "giriş", ekrandayken
  // iki dakikada bir nabız, bölüm değişince ve uygulama arka plana geçerken
  // birer bildirim. Sunucu yakın girişleri tek oturumda birleştirir ve süreyi
  // önceki bildirimin bölümüne yazar; yalnız Oyuncu 1 GET /activity ile
  // görebilir. Hata sessizce yutulur.
  const device = (() => {
    const ua = navigator.userAgent || '';
    if (/iPad/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)) return 'ipad';
    if (/iPhone|iPod/.test(ua)) return 'iphone';
    if (/Android/.test(ua)) return 'android';
    if (/Macintosh/.test(ua)) return 'mac';
    if (/Windows/.test(ua)) return 'windows';
    return 'other';
  })();
  let seenAt = 0;
  let area = 'home';
  let areaTimer;
  async function seen(open, hiding = false) {
    if (!config.token || !config.url || (document.hidden && !hiding)) return;
    seenAt = Date.now();
    try {
      if (!hiding) { await api('/seen', {open, device, area}); return; }
      // Sayfa kapanırken de gitsin (keepalive); yanıt beklenmez.
      void fetch(config.url + '/seen', {method: 'POST', keepalive: true, cache: 'no-store',
        headers: {Authorization: 'Bearer ' + config.token, 'Content-Type': 'application/json'},
        body: JSON.stringify({open: false, device, area})}).catch(() => {});
    } catch (_) { /* çevrimdışı: bir sonraki nabız */ }
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
      ...(await pushState()), pending: pendingGames().length > 0, pendingGames: pendingGames(), error};
  }
  async function call(action, data) {
    if (action === 'init') {
      if (data.url && /^https:\/\//.test(data.url)) config.url = data.url.replace(/\/$/, '');
      if (!data.url) config.url = '';
      if (Date.now() - seenAt > 120000) void seen(true);
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
      config.bests = {};
      for (const game of games) {
        const value = Number(data.scores?.[game]);
        if (Number.isSafeInteger(value) && value > 0) config.bests[game] = value;
      }
      persist();
      lastBoard = result;
      await flush();
      void seen(true);
      return state(false);
    }
    if (action === 'score') {
      const game = data.game || 'block';
      if (game !== 'block' && !games.includes(game)) throw new Error('Geçersiz oyun.');
      // Oynanan oyunun skoru meydan okumaya da sayılır (sync: oyun açılırken
      // eşitlenen eski rekor sayılmaz). Block Blast her hamlede skor bildirir:
      // o, 30 saniyelik düzenli gönderimle gider; diğerleri oyun bitince hemen.
      if (config.token && !data.sync && Number.isSafeInteger(data.score) && data.score > 0 && addPlay(game, data.score)) {
        persist();
        if (game !== 'block') { clearTimeout(scoreTimer); scoreTimer = setTimeout(flush, 600); }
      }
      if (config.token && Number.isSafeInteger(data.score) && data.score > localBest(game)) {
        if (game === 'block') config.best = data.score; else config.bests[game] = data.score;
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
        config.token = ''; config.best = 0; config.bests = {}; config.plays = {}; delete config.round; delete config.roundChecked; verifiedSubscription = ''; lastBoard = null; persist();
        avatars = {}; persistAvatars();
        for (const k of Object.keys(fullCache)) delete fullCache[k];
        try { localStorage.removeItem(tripsKey); localStorage.removeItem(filmsKey); localStorage.removeItem(weeklyKey); } catch (_) {}
        for (const k of Object.keys(delivered)) delete delivered[k];
        saveCache.last = {};
      }
      return state(false);
    }
    if (action === 'rename') {
      if (!config.token) throw new Error('Önce sıralamaya oyuncu kodunla katıl.');
      lastBoard = await api('/profile', {name: String(data.name || '').trim()});
      return state(false);
    }
    if (action === 'avatarPut') {
      const m = /^data:image\/jpeg;base64,([A-Za-z0-9+/]+={0,2})$/.exec(String(data.data || ''));
      if (!m) throw new Error('Fotoğraf geçersiz. Lütfen başka bir fotoğraf seç.');
      lastBoard = await api('/avatar', {data: m[1]});
      return state(false);
    }
    if (action === 'avatarPutFull') {
      const m = /^data:image\/jpeg;base64,([A-Za-z0-9+/]+={0,2})$/.exec(String(data.data || ''));
      const full = window.hukukTakeAvatarFull ? window.hukukTakeAvatarFull() : '';
      if (!m || !full) throw new Error('Fotoğraf geçersiz. Lütfen başka bir fotoğraf seç.');
      lastBoard = await (await bigRequest('/avatar/full', m[1] + '\n' + full)).json();
      return state(false);
    }
    if (action === 'avatarSaveFull') {
      const id = Number(data.id);
      if (id !== 1 && id !== 2) throw new Error('Geçersiz oyuncu.');
      const filename = String(data.filename || 'profil.jpg');
      const cached = fullCache[id];
      // Önbellekteyse hiç beklemeden kaydet (dokunuş izni korunur).
      if (cached && cached.version === data.version) return {status: await window.hukukSaveAvatar(cached.data, filename)};
      const response = await bigRequest('/avatar/full?id=' + id);
      const b64 = await response.text();
      fullCache[id] = {version: response.headers.get('X-Avatar-Version'), data: b64};
      return {status: await window.hukukSaveAvatar(b64, filename)};
    }
    if (action === 'avatarDelete') {
      lastBoard = await api('/avatar/delete', {});
      return state(false);
    }
    if (action === 'avatarGet') {
      const id = Number(data.id);
      if (id !== 1 && id !== 2) throw new Error('Geçersiz oyuncu.');
      const cached = avatars[id];
      if (cached && cached.version === data.version) return {id, version: cached.version, data: cached.data};
      const result = await api('/avatar?id=' + id);
      avatars[id] = {version: result.version, data: result.data};
      persistAvatars();
      return result;
    }
    if (action === 'home' || action === 'trips') {
      if (!config.token) return {trips: [], notes: [], connected: false};
      if (data.cached) {
        const cached = readCache(tripsKey);
        if (cached) return {...deliver(tripsKey, cached, false), cached: true};
      }
      try { return deliver(tripsKey, saveTrips(await api('/home')), data.known); }
      catch (e) {
        const cached = readCache(tripsKey);
        if (cached) return {...cached, connected: true, offline: true, error: e.message};
        throw e;
      }
    }
    if (action === 'tripAdd') return deliver(tripsKey, saveTrips(await api('/trips', {destination: data.destination, arrival: data.arrival})), false);
    if (action === 'tripDelete') return deliver(tripsKey, saveTrips(await api('/trips/delete', {id: data.id})), false);
    if (action === 'noteAdd') return deliver(tripsKey, saveTrips(await api('/notes', {text: data.text})), false);
    if (action === 'noteDelete') return deliver(tripsKey, saveTrips(await api('/notes/delete', {id: data.id})), false);
    // Film listesi: son kopya çevrimdışı açılış için saklanır.
    if (action === 'films') {
      if (!config.token) return {films: [], ratings: [], players: [], connected: false};
      if (data.cached) {
        const cached = readCache(filmsKey);
        if (cached) return {...deliver(filmsKey, cached, false), cached: true};
      }
      try { return deliver(filmsKey, saveFilms(await api('/films')), data.known); }
      catch (e) {
        const cached = readCache(filmsKey);
        if (cached) return {...cached, connected: true, offline: true, error: e.message};
        throw e;
      }
    }
    if (action === 'filmSearch') return api('/films/search', {query: data.query});
    if (action === 'filmAdd') return deliver(filmsKey, saveFilms(await api('/films', {tmdbId: data.tmdbId})), false);
    if (action === 'filmShow') return api('/films/show', {tmdbId: data.tmdbId});
    if (action === 'filmSeason') return api('/films/season', {tmdbId: data.tmdbId, season: data.season});
    if (action === 'filmEpisodes') return deliver(filmsKey, saveFilms(await api('/films/episodes',
      {showId: data.showId, season: data.season, episodes: data.episodes})), false);
    if (action === 'filmWatched') return deliver(filmsKey, saveFilms(await api('/films/watched', {id: data.id, watched: data.watched})), false);
    if (action === 'filmRate') return deliver(filmsKey, saveFilms(await api('/films/rate', {id: data.id, halves: data.halves, comment: data.comment})), false);
    if (action === 'filmReply') return deliver(filmsKey, saveFilms(await api('/films/reply', {id: data.id, reviewBy: data.reviewBy, text: data.text})), false);
    if (action === 'filmReplyDelete') return deliver(filmsKey, saveFilms(await api('/films/reply/delete', {reply: data.reply})), false);
    if (action === 'filmLike') return deliver(filmsKey, saveFilms(await api('/films/like', {id: data.id, target: data.target, like: data.like})), false);
    if (action === 'filmDelete') return deliver(filmsKey, saveFilms(await api('/films/delete', {id: data.id})), false);
    // Ortak karar (film kaydırma): durum her çağrıda sunucudan gelir.
    if (action === 'swipe') return api('/films/swipe', {});
    if (action === 'swipeStart') return api('/films/swipe/start', {});
    if (action === 'swipeVote') return api('/films/swipe/vote', {session: data.session, pos: data.pos, vote: data.vote});
    if (action === 'swipeCancel') return api('/films/swipe/cancel', {session: data.session});
    // Haftalık meydan okuma: son kopya çevrimdışı açılış için saklanır; bu
    // cihazın henüz gönderilmemiş skorları da eklenir.
    if (['weekly', 'weeklySeen', 'weeklyStart', 'weeklyCancel'].includes(action)) {
      if (!config.token) return {connected: false};
      const local = () => {
        const start = roundActive() ? config.round.start : Infinity;
        return {localBests: Object.fromEntries(weekGames.map(g =>
          [g, Math.max(0, ...(config.plays[g] || []).filter(p => !p.sent && p.t >= start).map(p => p.s))]))};
      };
      if (action === 'weekly' && data.cached) {
        const cached = readCache(weeklyKey);
        if (cached) return {...cached, ...local(), connected: true, cached: true};
      }
      if (action === 'weeklyStart') return {...saveWeekly(await api('/weekly/start', {})), ...local(), connected: true};
      if (action === 'weeklyCancel') return {...saveWeekly(await api('/weekly/cancel', {})), ...local(), connected: true};
      try {
        await flush();
        const r = action === 'weekly' ? await api('/weekly') : await api('/weekly/seen', {round: data.round});
        return {...saveWeekly(r), ...local(), connected: true};
      } catch (e) {
        const cached = readCache(weeklyKey);
        if (cached) return {...cached, ...local(), connected: true, offline: true, error: e.message};
        throw e;
      }
    }
    if (action === 'message') return api('/message', {message: data.message});
    if (action === 'area') {
      // Flutter hangi bölümde olunduğunu bildirir; hızlı geçişler birleşir.
      const next = String(data.area || 'other');
      if (next !== area) {
        clearTimeout(areaTimer);
        areaTimer = setTimeout(() => { void seen(false); }, 2000);
      }
      area = next;
      return {};
    }
    if (action === 'activity') {
      if (!config.token) return {connected: false};
      return {...await api('/activity'), connected: true};
    }
    throw new Error('İşlem bulunamadı.');
  }
  // Film detayındaki IMDb / Letterboxd / TMDB bağlantıları: yalnız bu siteler,
  // yeni sekmede ve sayfaya erişimsiz (noopener) açılır.
  const linkHosts = ['www.imdb.com', 'letterboxd.com', 'www.themoviedb.org'];
  window.hukukOpenUrl = (raw) => {
    try {
      const url = new URL(String(raw));
      if (url.protocol !== 'https:' || !linkHosts.includes(url.hostname)) return false;
      window.open(url.href, '_blank', 'noopener,noreferrer');
      return true;
    } catch (_) { return false; }
  };
  window.hukukSocialCall = (action, raw) => call(action, JSON.parse(raw)).then(
    data=>JSON.stringify(data), e=>JSON.stringify({error:e.message || 'Bağlantı kurulamadı.', status:e.status}));
  window.addEventListener('online', () => void flush());
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) { void flush(); void seen(true); } else { clearTimeout(areaTimer); void seen(false, true); }
  });
  setInterval(flush, 30000);
  void seen(true);
  setInterval(() => { if (Date.now() - seenAt >= 110000) void seen(false); }, 30000);
})();
