import 'dart:js_interop';

@JS('hukukListenInvites')
external void _listen(JSFunction fn);

/// Bildirimdeki 1v1 davetine dokunulunca oda kodu gelir (web/pwa.js).
void listenInvites(void Function(String room) handler) {
  _listen(((JSString room) => handler(room.toDart)).toJS);
}
