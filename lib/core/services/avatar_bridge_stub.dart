/// Yerel (iOS/macOS) derlemede fotoğraf seçici yok; web uygulamasında çalışır.
bool get avatarPickerSupported => false;

/// Seçilen fotoğrafı JPEG data URL olarak döndürür; vazgeçilirse ''.
Future<String> pickAvatarDataUrl() async => '';
