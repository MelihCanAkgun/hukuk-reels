import 'dart:js_interop';

@JS('hukukPickAvatar')
external JSPromise<JSString> _pick();

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
