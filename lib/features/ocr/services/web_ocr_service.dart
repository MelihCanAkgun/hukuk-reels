/// ─────────────────────────────────────────────────
/// Web OCR Servisi — Tesseract.js Entegrasyonu
///
/// Çevrimdışı OCR için Tesseract.js WASM kullanır.
///
/// Kurulum:
/// 1. tesseract.js CDN'den indir ve web/ altına koy:
///    - tesseract.min.js
///    - tesseract-core-simd.wasm.js
///    - tur.traineddata.gz (Türkçe dil verisi)
///
/// 2. index.html'e script ekle:
///    <script src="tesseract.min.js"></script>
///
/// 3. Bu sınıfın recognize metodunu JS interop ile bağla.
///
/// Not: WASM dosyaları Service Worker tarafından
/// otomatik önbelleğe alınır (sw.js).
/// ─────────────────────────────────────────────────
class WebOcrService {
  static WebOcrService? _instance;
  WebOcrService._();

  static WebOcrService get instance {
    _instance ??= WebOcrService._();
    return _instance!;
  }

  /// OCR'ı hazır hale getir
  /// Tesseract worker oluşturur, Türkçe dil verisini yükler
  Future<void> init() async {
    // JS interop ile Tesseract.createWorker('tur') çağrılacak
  }

  /// Base64 görüntüden metin tanı
  /// [imageDataUri] → "data:image/png;base64,..." formatı
  Future<String> recognize(String imageDataUri) async {
    // JS interop ile:
    // const result = await worker.recognize(imageDataUri);
    // return result.data.text;
    return '';
  }

  void dispose() {}
}
