/// index.html'deki WebAudio fonksiyonlarına köprü (yalnızca web).
/// SFX buffer'ları ve iOS müzik ses seviyesi (GainNode) buradan sürülür.
library;

import 'dart:js_interop';

@JS('sfxLoad')
external void _sfxLoad(JSString name, JSString url);

@JS('sfxPlay')
external void _sfxPlay(JSString name);

@JS('sfxSetVolume')
external void _sfxSetVolume(JSNumber v);

@JS('musicSetVolume')
external void _musicSetVolume(JSNumber v);

void sfxLoad(String name, String url) {
  try {
    _sfxLoad(name.toJS, url.toJS);
  } catch (_) {}
}

void sfxPlay(String name) {
  try {
    _sfxPlay(name.toJS);
  } catch (_) {}
}

void sfxSetVolume(double v) {
  try {
    _sfxSetVolume(v.toJS);
  } catch (_) {}
}

void musicSetVolume(double v) {
  try {
    _musicSetVolume(v.toJS);
  } catch (_) {}
}
