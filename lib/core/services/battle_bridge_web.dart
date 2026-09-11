import 'dart:convert';
import 'dart:js_interop';

@JS('hukukBattleListen')
external void _listen(JSFunction fn);
@JS('hukukBattleCall')
external JSPromise<JSString> _call(JSString action, JSString data);
void listenBattle(void Function(Map<String, dynamic>) listener) {
  _listen(((JSString data) {
    listener(jsonDecode(data.toDart) as Map<String, dynamic>);
  }).toJS);
}

Future<Map<String, dynamic>> battleCall(String action,
    [Map<String, dynamic> data = const {}]) async {
  try {
    return jsonDecode(
            (await _call(action.toJS, jsonEncode(data).toJS).toDart).toDart)
        as Map<String, dynamic>;
  } catch (_) {
    return {'error': 'Battle bağlantısı kurulamadı.'};
  }
}
