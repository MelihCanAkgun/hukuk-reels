/// ─────────────────────────────────────────────────────────────
/// UYGULAMA AYARLARI  (Kişiselleştirme burada)
///
/// Müzik ve köşe görsellerini kod bilmeden buradan değiştirebilirsin.
/// ─────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  /// ───── ARKA PLAN MÜZİKLERİ ─────
  ///
  /// 1) Müzik dosyanı (.mp3 / .m4a / .wav) `assets/audio/` klasörüne at.
  /// 2) Dosya adını aşağıdaki listeye ekle: 'assets/audio/dosya_adi.mp3'
  /// 3) Uygulamayı yeniden başlat (web için: flutter build web).
  ///
  /// Birden fazla parça eklersen hepsi sırayla, kesintisiz döngüyle çalar.
  static const List<String> musicTracks = [
    'assets/audio/sillycat_1.mp3',
    'assets/audio/sillycat_2.mp3',
  ];

  /// Müzik açılışta otomatik başlasın mı? (Web'de tarayıcı ilk dokunuşu
  /// bekleyebilir; uygulama ilk dokunuşta sesi başlatır.)
  static const bool autoPlayMusic = true;

  /// Başlangıç ses seviyesi (0.0 - 1.0)
  static const double musicVolume = 0.35;

  /// ───── KÖŞE GÖRSELLERİ ─────
  ///
  /// Ekranın dört köşesine yerleştirilir; soru kartının arkasında ve
  /// kenarlarda durur, metni KAPATMAZ.
  ///
  /// Görselini `assets/images/` klasörüne at ve yolunu buraya ekle.
  /// Liste sırası: [sol-üst, sağ-üst, sol-alt, sağ-alt]
  /// Boş bırakırsan ([]) o köşede görsel olmaz.
  static const List<String> cornerImages = [
    'assets/images/cat_pink.png',     // sol üst
    'assets/images/cat_white.png',    // sağ üst
    'assets/images/cat_peach.png',    // sol alt
    'assets/images/cat_lavender.png', // sağ alt
  ];

  /// Köşe görsellerinin boyutu (px) ve saydamlığı (0.0 - 1.0).
  /// Soruyu rahatsız etmesin diye küçük ve hafif saydam önerilir.
  static const double cornerImageSize = 92;
  static const double cornerImageOpacity = 0.22;

  /// Köşe görselleri gösterilsin mi?
  static const bool showCornerImages = true;
}
