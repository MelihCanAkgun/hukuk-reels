export 'update_bridge_stub.dart'
    if (dart.library.js_interop) 'update_bridge_web.dart';

/// [checkForUpdate] sonucunun kullanıcıya gösterilecek metni.
String updateResultText(String result) => switch (result) {
      'latest' => 'En güncel sürümü kullanıyorsun.',
      'updating' => 'Yeni sürüm indirildi, uygulama yeniden açılıyor…',
      'offline' => 'Güncellemeye ulaşılamadı. Bağlantını kontrol edip '
          'tekrar dene.',
      _ => 'Güncelleme denetimi ana ekran/web uygulamasında çalışır.',
    };
