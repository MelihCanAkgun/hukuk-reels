'use strict';
// Profil fotoğrafı: seçici, kare kırpılmış + çıkartmalı 320 px görüntü
// kopyası, yönetici için orijinal boyutlu tam kalite kopya ve kaydetme.
(() => {
  const SIZE = 320;
  function load(file) {
    return new Promise((resolve, reject) => {
      const url = URL.createObjectURL(file);
      const img = new Image();
      img.onload = () => { URL.revokeObjectURL(url); resolve(img); };
      img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('Bu fotoğraf açılamadı.')); };
      img.src = url;
    });
  }
  // Yönetici için: sunucudaki profil fotoğrafını cihaza kaydeder. Dokunmatik
  // cihazlarda paylaşım sayfası açılır ("Resmi Kaydet" → Fotoğraflar);
  // diğerlerinde dosya olarak iner. Dosya dokunuşun içinde hazırlanır ki
  // tarayıcı paylaşım iznini düşürmesin.
  window.hukukSaveAvatar = async (b64, filename) => {
    try {
      const raw = atob(b64);
      const bytes = new Uint8Array(raw.length);
      for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
      const file = new File([bytes], filename, {type: 'image/jpeg'});
      if (navigator.canShare && matchMedia('(pointer: coarse)').matches && navigator.canShare({files: [file]})) {
        try { await navigator.share({files: [file]}); return 'shared'; }
        catch (e) {
          if (e && e.name === 'AbortError') return '';
          // İndirme sürünce dokunuş izni düşer: kullanıcı tekrar dokunsun.
          if (e && e.name === 'NotAllowedError') return 'retry';
        }
      }
      const url = URL.createObjectURL(file);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.style.display = 'none';
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 30000);
      return 'downloaded';
    } catch (e) {
      return 'error:' + ((e && e.message) || 'Fotoğraf indirilemedi.');
    }
  };
  // ── Tam kalite + düzenleyici ──
  // Seçilen fotoğraf (çözülmüş, tam çözünürlük) yalnız bu kapanışta tutulur;
  // Flutter düzenleyiciye küçük bir önizleme gider, son çizim burada tam
  // çözünürlükte yapılır. EXIF/konum canvas'tan geçince zaten düşer.
  const FULL_MAX_BYTES = 12 * 1024 * 1024;
  const PREVIEW_SIDE = 1280;
  let source = null;                    // {img, w, h}
  let pendingFull = '';                 // son çizilen tam JPEG (base64)

  function canvasOf(w, h) {
    const c = document.createElement('canvas');
    c.width = w; c.height = h;
    return c;
  }
  const free = c => { c.width = c.height = 0; };
  const blobOf = (canvas, q) => new Promise((res, rej) =>
    canvas.toBlob(b => b ? res(b) : rej(new Error('Fotoğraf kaydedilemedi (bellek yetersiz olabilir).')), 'image/jpeg', q));
  const base64Of = blob => new Promise((res, rej) => {
    const r = new FileReader();
    r.onload = () => res(String(r.result).replace(/^data:[^,]*,/, ''));
    r.onerror = () => rej(new Error('Fotoğraf okunamadı.'));
    r.readAsDataURL(blob);
  });
  // Büyük küçültmelerde yarıya yarıya inerek kenar tırtıklarını önler.
  function downscale(src, side) {
    let cur = src, w = src.width;
    while (w / 2 > side) {
      w = Math.round(w / 2);
      const next = canvasOf(w, w);
      const ctx = next.getContext('2d');
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImage(cur, 0, 0, w, w);
      if (cur !== src) free(cur);
      cur = next;
    }
    const out = canvasOf(side, side);
    const ctx = out.getContext('2d');
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(cur, 0, 0, side, side);
    if (cur !== src) free(cur);
    return out;
  }

  window.hukukPickAvatarSource = () => new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.style.display = 'none';
    let done = false;
    const finish = (value) => { if (done) return; done = true; input.remove(); resolve(value); };
    input.addEventListener('change', async () => {
      const file = input.files && input.files[0];
      if (!file) return finish('');
      try {
        if (!file.type.startsWith('image/')) throw new Error('Lütfen bir fotoğraf seç.');
        const img = await load(file);
        const w = img.naturalWidth, h = img.naturalHeight;
        if (!w || !h) throw new Error('Bu fotoğraf açılamadı.');
        source = {img, w, h};
        const k = Math.min(1, PREVIEW_SIDE / Math.max(w, h));
        const pc = canvasOf(Math.round(w * k), Math.round(h * k));
        const ctx = pc.getContext('2d');
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(img, 0, 0, pc.width, pc.height);
        const preview = pc.toDataURL('image/jpeg', 0.85);
        free(pc);
        finish(JSON.stringify({w, h, preview}));
      } catch (e) { finish('error:' + (e.message || 'Fotoğraf okunamadı.')); }
    });
    input.addEventListener('cancel', () => finish(''));
    document.body.appendChild(input);
    input.click();
  });

  function drawPixels(ctx, rows, palette, ox, oy, px) {
    for (let y = 0; y < rows.length; y++) {
      const y0 = Math.round(oy + y * px), y1 = Math.round(oy + (y + 1) * px);
      for (let x = 0; x < rows[y].length; x++) {
        const ch = rows[y][x];
        if (ch === '.') continue;
        const x0 = Math.round(ox + x * px), x1 = Math.round(ox + (x + 1) * px);
        ctx.fillStyle = palette[ch];
        ctx.fillRect(x0, y0, Math.max(1, x1 - x0), Math.max(1, y1 - y0));
      }
    }
  }

  function drawSticker(ctx, st, S) {
    const rows = st.rows, cols = rows[0].length, n = rows.length;
    const box = st.size * S, px = box / Math.max(cols, n);
    const w = cols * px, h = n * px;
    const cx = st.x * S + box / 2, cy = st.y * S + box / 2;
    const rot = Number(st.rot) || 0;
    if (!rot) {
      drawPixels(ctx, rows, st.palette, cx - w / 2, cy - h / 2, px);
      return;
    }
    // Döndürülmüş: önce düz hâlini ayrı tuvale tam piksellerle çiz, sonra bütün
    // olarak döndür (kareler arasında ince dikiş çizgisi kalmaz).
    const ip = Math.max(1, Math.ceil(px));
    const off = canvasOf(cols * ip, n * ip);
    drawPixels(off.getContext('2d'), rows, st.palette, 0, 0, ip);
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(rot);
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(off, -w / 2, -h / 2, w, h);
    ctx.restore();
    free(off);
  }

  // Orijinalin sığabileceği en büyük boyut: iOS Safari tuvali ~16.7 MP ile
  // sınırlı, sunucu kenar başına 8192 px kabul ediyor. Normal telefon
  // fotoğrafları (12 MP) olduğu gibi, küçültülmeden geçer.
  const FULL_MAX_AREA = 16_777_216;
  const SERVER_MAX_SIDE = 8192;
  function fullSize(w, h) {
    const k = Math.min(1, Math.sqrt(FULL_MAX_AREA / (w * h)), SERVER_MAX_SIDE / Math.max(w, h));
    return [Math.max(1, Math.floor(w * k)), Math.max(1, Math.floor(h * k))];
  }

  /**
   * spec: {out, bg, img:{x,y,w,h}, stickers:[{rows, palette, x, y, size}]}
   * — konumlar kare çerçevenin kenarına (1.0) göre. Kare kırpma + çıkartmalar
   * yalnız uygulamada görünen 320 px kopya içindir. Yönetici için saklanan tam
   * kalite kopya, galerideki ORİJİNAL fotoğraftır: kırpılmamış, çıkartmasız,
   * kendi en-boy oranı ve çözünürlüğünde (yalnız EXIF/konum düşer).
   */
  window.hukukRenderAvatar = async (raw) => {
    let full, square;
    try {
      if (!source) throw new Error('Önce bir fotoğraf seç.');
      const spec = JSON.parse(raw);
      // 1) Uygulama görüntüsü: kare kırpma + çıkartmalar.
      const S = Math.max(SIZE, Math.min(1280, Math.round(spec.out) || SIZE));
      square = canvasOf(S, S);
      const sctx = square.getContext('2d');
      sctx.fillStyle = spec.bg || '#170B12';
      sctx.fillRect(0, 0, S, S);
      sctx.imageSmoothingQuality = 'high';
      const r = spec.img;
      sctx.drawImage(source.img, r.x * S, r.y * S, r.w * S, r.h * S);
      sctx.imageSmoothingEnabled = false;
      for (const st of spec.stickers || []) drawSticker(sctx, st, S);
      const small = downscale(square, SIZE);
      const thumb = small.toDataURL('image/jpeg', 0.86);
      free(small);
      free(square); square = null;
      // 2) Tam kalite: orijinal fotoğraf, olduğu gibi.
      const [W, H] = fullSize(source.w, source.h);
      full = canvasOf(W, H);
      const ctx = full.getContext('2d');
      ctx.fillStyle = '#FFFFFF'; // şeffaf PNG'ler siyaha dönmesin
      ctx.fillRect(0, 0, W, H);
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImage(source.img, 0, 0, W, H);
      let blob;
      for (const q of [0.95, 0.92, 0.88, 0.82]) {
        blob = await blobOf(full, q);
        if (blob.size <= FULL_MAX_BYTES) break;
      }
      if (blob.size > FULL_MAX_BYTES) throw new Error('Fotoğraf çok büyük.');
      pendingFull = await base64Of(blob);
      return JSON.stringify({thumb, width: W, height: H, bytes: blob.size});
    } catch (e) {
      pendingFull = '';
      return 'error:' + ((e && e.message) || 'Fotoğraf hazırlanamadı.');
    } finally {
      if (full) free(full);
      if (square) free(square);
    }
  };
  // social.js yüklerken bir kez alır (bellekte megabaytlarca metin kalmasın).
  window.hukukTakeAvatarFull = () => { const v = pendingFull; pendingFull = ''; return v; };
  window.hukukForgetAvatarSource = () => { source = null; pendingFull = ''; };
})();
