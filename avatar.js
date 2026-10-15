'use strict';
// Profil fotoğrafı: seçici, tam çözünürlükte düzenleme çizimi (kırpma +
// piksel çıkartmalar), 320 px görüntü kopyası ve yönetici için kaydetme.
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
  const FULL_MAX_SIDE = 4096;          // iOS Safari canvas sınırı (16.7 MP)
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

  function drawSticker(ctx, st, S) {
    const rows = st.rows, cols = rows[0].length, n = rows.length;
    const box = st.size * S, px = box / Math.max(cols, n);
    const ox = st.x * S + (box - cols * px) / 2, oy = st.y * S + (box - n * px) / 2;
    for (let y = 0; y < n; y++) {
      const y0 = Math.round(oy + y * px), y1 = Math.round(oy + (y + 1) * px);
      for (let x = 0; x < cols; x++) {
        const ch = rows[y][x];
        if (ch === '.') continue;
        const x0 = Math.round(ox + x * px), x1 = Math.round(ox + (x + 1) * px);
        ctx.fillStyle = st.palette[ch];
        ctx.fillRect(x0, y0, Math.max(1, x1 - x0), Math.max(1, y1 - y0));
      }
    }
  }

  /**
   * spec: {out, bg, img:{x,y,w,h}, stickers:[{rows, palette, x, y, size}]}
   * — konumlar kare çerçevenin kenarına (1.0) göre. Tam JPEG'i saklar,
   * 320 px görüntü kopyasını döndürür.
   */
  window.hukukRenderAvatar = async (raw) => {
    let full;
    try {
      if (!source) throw new Error('Önce bir fotoğraf seç.');
      const spec = JSON.parse(raw);
      const S = Math.max(320, Math.min(FULL_MAX_SIDE, Math.round(spec.out) || 320));
      full = canvasOf(S, S);
      const ctx = full.getContext('2d');
      ctx.fillStyle = spec.bg || '#170B12';
      ctx.fillRect(0, 0, S, S);
      ctx.imageSmoothingQuality = 'high';
      const r = spec.img;
      ctx.drawImage(source.img, r.x * S, r.y * S, r.w * S, r.h * S);
      ctx.imageSmoothingEnabled = false;
      for (const st of spec.stickers || []) drawSticker(ctx, st, S);
      let blob;
      for (const q of [0.95, 0.9, 0.85]) {
        blob = await blobOf(full, q);
        if (blob.size <= FULL_MAX_BYTES) break;
      }
      if (blob.size > FULL_MAX_BYTES) throw new Error('Fotoğraf çok büyük.');
      pendingFull = await base64Of(blob);
      const small = downscale(full, SIZE);
      const thumb = small.toDataURL('image/jpeg', 0.86);
      free(small);
      return JSON.stringify({thumb, side: S, bytes: blob.size});
    } catch (e) {
      pendingFull = '';
      return 'error:' + ((e && e.message) || 'Fotoğraf hazırlanamadı.');
    } finally {
      if (full) free(full);
    }
  };
  // social.js yüklerken bir kez alır (bellekte megabaytlarca metin kalmasın).
  window.hukukTakeAvatarFull = () => { const v = pendingFull; pendingFull = ''; return v; };
  window.hukukForgetAvatarSource = () => { source = null; pendingFull = ''; };
})();
