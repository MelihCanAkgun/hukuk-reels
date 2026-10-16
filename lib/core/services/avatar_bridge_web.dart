import 'dart:js_interop';

@JS('hukukPickAvatarSource')
external JSPromise<JSString> _pickSource();

@JS('hukukRenderAvatar')
external JSPromise<JSString> _render(JSString spec);

@JS('hukukForgetAvatarSource')
external void _forget();

@JS('hukukSaveAvatar')
external JSPromise<JSString> _save(JSString base64Jpeg, JSString filename);

bool get avatarPickerSupported => true;

/// JPEG'i cihaza kaydeder (dokunuşun içinden çağrılmalı). 'shared' veya
/// 'downloaded' döner; vazgeçilirse '', hata olursa `error:<mesaj>`.
Future<String> saveAvatarJpeg(String base64Jpeg, String filename) async {
  try {
    return (await _save(base64Jpeg.toJS, filename.toJS).toDart).toDart;
  } catch (_) {
    return 'error:Fotoğraf indirilemedi.';
  }
}

/// Dosya penceresini açar (dokunuşun içinden çağrılmalı). Fotoğraf tam
/// çözünürlükte JS tarafında tutulur; JSON `{w, h, preview}` döner.
/// Vazgeçilirse '', hata olursa `error:<mesaj>`.
Future<String> pickAvatarSource() async {
  try {
    return (await _pickSource().toDart).toDart;
  } catch (_) {
    return 'error:Fotoğraf seçici açılamadı.';
  }
}

/// Kare görüntü kopyası + orijinal boyutlu tam JPEG hazırlar.
/// JSON `{thumb, width, height, bytes}`
/// ya da `error:<mesaj>`. Tam JPEG yükleme için JS tarafında bekler.
Future<String> renderAvatar(String specJson) async {
  try {
    return (await _render(specJson.toJS).toDart).toDart;
  } catch (_) {
    return 'error:Fotoğraf hazırlanamadı.';
  }
}

void forgetAvatarSource() {
  try {
    _forget();
  } catch (_) {}
}
