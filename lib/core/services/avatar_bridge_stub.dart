/// Yerel (iOS/macOS) derlemede fotoğraf seçici yok; web uygulamasında çalışır.
bool get avatarPickerSupported => false;

/// Seçilen fotoğrafı JPEG data URL olarak döndürür; vazgeçilirse ''.
Future<String> pickAvatarDataUrl() async => '';

/// Profil fotoğrafını cihaza kaydeder; yalnız web uygulamasında çalışır.
Future<String> saveAvatarJpeg(String base64Jpeg, String filename) async =>
    'error:Fotoğraf indirme yalnız web uygulamasında çalışır.';
