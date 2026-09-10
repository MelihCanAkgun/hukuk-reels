    // ── Ses altyapısı (WebAudio) ──
    // 1) SFX: WAV'lar belleğe alınır, her çağrıda yeni BufferSource ile
    //    çalınır → üst üste ve sınırsız tekrar çalabilir, gecikme çok düşük.
    // 2) Müzik sesi (iOS): Safari <audio>.volume'u yok sayar; müzik
    //    elemanları bir GainNode'a bağlanınca kaydırıcı iOS'ta da çalışır.
    var _ac = null, _musicGain = null, _sfxGain = null;
    var _sfxBuffers = {};
    var _wiredEls = new WeakSet();
    var _musicVolume = 0.35;
    var _isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent)
        || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

    function _audioCtx() {
      if (_ac) return _ac;
      var AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return null;
      _ac = new AC();
      _musicGain = _ac.createGain();
      _musicGain.connect(_ac.destination);
      _sfxGain = _ac.createGain();
      _sfxGain.connect(_ac.destination);
      return _ac;
    }
    function _resumeCtx() {
      var ctx = _audioCtx();
      if (ctx && (ctx.state === 'suspended' || ctx.state === 'interrupted')) {
        ctx.resume().catch(function () {});
      }
    }
    document.addEventListener('pointerdown', _resumeCtx, { passive: true });
    document.addEventListener('visibilitychange', function () {
      if (!document.hidden) _resumeCtx();
    });

    function sfxLoad(name, url) {
      var ctx = _audioCtx();
      if (!ctx) return;
      fetch(url)
        .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.arrayBuffer(); })
        .then(function (b) { return ctx.decodeAudioData(b); })
        .then(function (buf) { _sfxBuffers[name] = buf; })
        .catch(function (e) { console.warn('[SFX] yüklenemedi:', name, e); });
    }
    function sfxPlay(name, rate) {
      if (document.hidden) return;
      var ctx = _audioCtx(), buf = _sfxBuffers[name];
      if (!ctx || !buf) return;
      _resumeCtx();
      try {
        var s = ctx.createBufferSource();
        s.buffer = buf;
        s.playbackRate.value = Math.max(0.8, Math.min(1.5, rate || 1));
        s.onended = function () { s.disconnect(); };
        s.connect(_sfxGain);
        s.start(0);
      } catch (e) {}
    }
    function sfxSetVolume(v) {
      if (_audioCtx()) _sfxGain.gain.value = Math.max(0, Math.min(1, v));
    }

    function musicSetVolume(v) {
      _musicVolume = Math.max(0, Math.min(1, v));
      // iOS dışında element.volume zaten çalışıyor; dokunma.
      if (!_isIOS) return;
      var ctx = _audioCtx();
      if (!ctx) return;
      _resumeCtx();
      _musicGain.gain.value = _musicVolume;
    }


// just_audio creates detached audio elements: document queries and bubbling
// play events cannot see them. Intercept only audio playback on iOS and keep
// the native play promise/receiver intact; video and desktop are unaffected.
function _wireMusicElement(el) {
  if (!_isIOS || el.tagName !== 'AUDIO' || _wiredEls.has(el)) return;
  var ctx = _audioCtx();
  if (!ctx) return;
  try {
    var source = ctx.createMediaElementSource(el);
    source.connect(_musicGain);
    _wiredEls.add(el);
    _musicGain.gain.value = _musicVolume;
  } catch (error) {
    console.warn('[Audio] Ses kontrolü bağlanamadı:', error.name);
  }
}
if (_isIOS && window.HTMLMediaElement) {
  var _nativeMediaPlay = window.HTMLMediaElement.prototype.play;
  window.HTMLMediaElement.prototype.play = function () {
    _wireMusicElement(this);
    _resumeCtx();
    return _nativeMediaPlay.apply(this, arguments);
  };
}
