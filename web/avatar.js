'use strict';
// Profil fotoğrafı seçici: dosyayı seçtirir, ortadan kare kırpar, 320 px JPEG'e
// küçültür ve data URL döndürür. Vazgeçilirse '' döner. Fotoğraf cihazdan çıkmaz.
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
  async function toAvatar(file) {
    if (!file.type.startsWith('image/')) throw new Error('Lütfen bir fotoğraf seç.');
    const img = await load(file); // EXIF yönü tarayıcı tarafından uygulanır.
    const side = Math.min(img.naturalWidth, img.naturalHeight);
    if (!side) throw new Error('Bu fotoğraf açılamadı.');
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = SIZE;
    const ctx = canvas.getContext('2d');
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(img, (img.naturalWidth - side) / 2, (img.naturalHeight - side) / 2, side, side, 0, 0, SIZE, SIZE);
    return canvas.toDataURL('image/jpeg', 0.86);
  }
  // Safari dosya penceresini yalnız dokunuşun içinden açar: input.click() senkron çağrılır.
  window.hukukPickAvatar = () => new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.style.display = 'none';
    let done = false;
    const finish = (value) => { if (done) return; done = true; input.remove(); resolve(value); };
    input.addEventListener('change', async () => {
      const file = input.files && input.files[0];
      if (!file) return finish('');
      try { finish(await toAvatar(file)); }
      catch (e) { finish('error:' + (e.message || 'Fotoğraf okunamadı.')); }
    });
    input.addEventListener('cancel', () => finish(''));
    document.body.appendChild(input);
    input.click();
  });
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
        catch (e) { if (e && e.name === 'AbortError') return ''; }
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
  window.hukukAvatarTest = {toAvatar};
})();
