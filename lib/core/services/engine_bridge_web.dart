import 'dart:js_interop';

@JS('hukukSetEngine')
external JSBoolean? _set(JSString mode);

@JS('hukukSetEngine')
external JSAny? get _setter;

/// web/flutter_bootstrap.js motor seçimini destekliyorsa true.
bool get engineSwitchAvailable {
  try {
    return _setter != null;
  } catch (_) {
    return false;
  }
}

/// Seçimi saklar ve uygulamayı yeniden yükler (web/flutter_bootstrap.js).
bool setWasmEngine(bool wasm) {
  try {
    return _set((wasm ? 'wasm' : 'js').toJS)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
