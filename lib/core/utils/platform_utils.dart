import 'package:flutter/foundation.dart';

/// Platform, PWA ve kurulum durumu tespiti
class PlatformUtils {
  PlatformUtils._();

  static bool get isWeb => kIsWeb;

  /// iOS Safari'de mi? (henüz standalone değil)
  static bool get isIosSafari {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Android Chrome'da mı?
  static bool get isAndroidChrome {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// iOS Safari banner gösterilmeli mi?
  static bool get shouldShowIosBanner => isIosSafari;

  /// Android Chrome banner gösterilmeli mi?
  /// (Chrome'un kendi install prompt'u varsa onu kullanırız,
  /// yoksa manuel talimat gösteririz)
  static bool get shouldShowAndroidBanner => isAndroidChrome;
}
