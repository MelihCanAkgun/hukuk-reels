/// Yerel (iOS/macOS) derlemede fotoğraf seçici yok; web uygulamasında çalışır.
bool get avatarPickerSupported => false;

/// Fotoğraf seçer; JSON `{w, h, preview}` (önizleme data URL) döner.
Future<String> pickAvatarSource() async => '';

/// Kare görüntü kopyası + orijinal boyutlu tam JPEG hazırlar;
/// JSON `{thumb, width, height, bytes}`.
Future<String> renderAvatar(String specJson) async =>
    'error:Fotoğraf düzenleme yalnız web uygulamasında çalışır.';

/// Seçilen fotoğrafı bellekten bırakır.
void forgetAvatarSource() {}

/// Profil fotoğrafını cihaza kaydeder; yalnız web uygulamasında çalışır.
Future<String> saveAvatarJpeg(String base64Jpeg, String filename) async =>
    'error:Fotoğraf indirme yalnız web uygulamasında çalışır.';
