import 'dart:js_interop';

@JS('hukukPickAvatar')
external JSPromise<JSString> _pick();

@JS('hukukSaveAvatar')
external JSPromise<JSString> _save(JSString base64Jpeg, JSString filename);

bool get avatarPickerSupported => true;

/// Dosya penceresini açar (dokunuşun içinden çağrılmalı). Seçilen fotoğraf
/// kırpılıp küçültülmüş JPEG data URL olarak döner; vazgeçilirse '',
/// hata olursa 'error:<mesaj>'.
Future<String> pickAvatarDataUrl() async {
  try {
    return (await _pick().toDart).toDart;
  } catch (_) {
    return 'error:Fotoğraf seçici açılamadı.';
  }
}

/// JPEG'i cihaza kaydeder (dokunuşun içinden çağrılmalı). 'shared' veya
/// 'downloaded' döner; vazgeçilirse '', hata olursa 'error:<mesaj>'.
Future<String> saveAvatarJpeg(String base64Jpeg, String filename) async {
  try {
    return (await _save(base64Jpeg.toJS, filename.toJS).toDart).toDart;
  } catch (_) {
    return 'error:Fotoğraf indirilemedi.';
  }
}
