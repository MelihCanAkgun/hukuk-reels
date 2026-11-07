import 'dart:js_interop';

@JS('hukukOpenUrl')
external JSBoolean? _open(JSString url);

/// IMDb / Letterboxd / TMDB sayfasını yeni sekmede açar (web/social.js izin
/// verdiği sitelerle sınırlar). Açılamazsa false.
bool openExternal(String url) {
  try {
    return _open(url.toJS)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
