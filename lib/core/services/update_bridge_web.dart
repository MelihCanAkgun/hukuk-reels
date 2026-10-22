import 'dart:js_interop';

@JS('hukukCheckUpdate')
external JSPromise<JSString> _check();

/// Yeni sürümü arar (web/update.js): 'latest', 'updating' (indirildi,
/// uygulanıyor), 'offline' ya da 'unavailable'.
Future<String> checkForUpdate() async {
  try {
    return (await _check().toDart).toDart;
  } catch (_) {
    return 'unavailable';
  }
}
