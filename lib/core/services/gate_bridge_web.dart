import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _getItem(JSString key);

const bool gateNative = false;

/// web/social.js'in saklı ayarı ('hukuk_social_v1'). Ağ beklemeden, eşzamanlı
/// okunur; böylece kodu olan cihaz ilk karede uygulamayı açar.
String? storedSocialConfig() {
  try {
    return _getItem('hukuk_social_v1'.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}
