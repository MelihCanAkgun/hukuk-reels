import 'dart:convert';
import 'dart:js_interop';

@JS('hukukSocialCall')
external JSPromise<JSString> _call(JSString action, JSString data);

Future<Map<String, dynamic>> socialCall(String action,
    [Map<String, dynamic> data = const {}]) async {
  try {
    return jsonDecode(
            (await _call(action.toJS, jsonEncode(data).toJS).toDart).toDart)
        as Map<String, dynamic>;
  } catch (_) {
    return {'error': 'Bağlantı kurulamadı. Biraz sonra tekrar dene.'};
  }
}
