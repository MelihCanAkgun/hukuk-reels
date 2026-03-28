import 'dart:js_interop';

/// index.html'deki JS fonksiyonlarına erişim
@JS('startCamera')
external JSPromise<JSBoolean> _jsStartCamera(JSString viewId);

@JS('capturePhoto')
external JSString? _jsCapturePhoto();

@JS('stopCamera')
external void _jsStopCamera();

@JS('isRunningStandalone')
external JSBoolean _jsIsRunningStandalone();

@JS('triggerInstallPrompt')
external JSPromise<JSBoolean> _jsTriggerInstallPrompt();

/// Web kamera yardımcı sınıfı
class WebCameraInterop {
  /// Kamerayı başlat
  static Future<bool> startCamera(String viewId) async {
    try {
      final result = await _jsStartCamera(viewId.toJS).toDart;
      return result.toDart;
    } catch (e) {
      return false;
    }
  }

  /// Fotoğraf çek, base64 data URI döner
  static String? capturePhoto() {
    try {
      return _jsCapturePhoto()?.toDart;
    } catch (e) {
      return null;
    }
  }

  /// Kamerayı kapat
  static void stopCamera() {
    try {
      _jsStopCamera();
    } catch (_) {}
  }

  /// PWA standalone modunda mı?
  static bool isStandalone() {
    try {
      return _jsIsRunningStandalone().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Chrome native install prompt'u tetikle
  static Future<bool> triggerInstall() async {
    try {
      final result = await _jsTriggerInstallPrompt().toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }
}
