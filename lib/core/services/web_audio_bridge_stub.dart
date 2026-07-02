/// Web dışı platformlar için no-op köprü (koşullu import'un yedeği).
/// Gerçek uygulama `web_audio_bridge_web.dart` içindedir.
library;

void sfxLoad(String name, String url) {}
void sfxPlay(String name) {}
void sfxSetVolume(double v) {}
void musicSetVolume(double v) {}
