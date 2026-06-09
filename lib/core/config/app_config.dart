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
    'assets/audio/Wildflower.mp3',
    'assets/audio/Dolu_Kadehi_Ters_Tut.mp3',
    'assets/audio/Sad_Girl.mp3',
    'assets/audio/Takil_Yani_Takmiyo_Belli.mp3',
    'assets/audio/Bal.mp3',
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
    'assets/images/spider_cat.png', // sol üst
    'assets/images/dopdolu.jpg',    // sağ üst
    'assets/images/ani.jpg',        // sol alt
    'assets/images/cat_pink.png',   // sağ alt
  ];

  /// Köşe görsellerinin boyutu (px) ve saydamlığı (0.0 - 1.0).
  /// Görseller kartın içinde, yazıların ARKASINDA çizilir; bu yüzden hiçbir
  /// soruyu kapatmazlar ama köşelerin boş alanlarında net görünürler.
  /// Daha büyük/belirgin istersen boyutu ve opaklığı artır.
  static const double cornerImageSize = 116;
  static const double cornerImageOpacity = 0.6;

  /// Köşe görselleri gösterilsin mi?
  static const bool showCornerImages = true;

  /// ───── BEYZBOL SOPASI (Döv modu) ─────
  ///
  /// "Yanlış Soruları Döv" modundaki sopa görseli. Şeffaf arka planlı bir
  /// PNG'yi `assets/images/` klasörüne koyup yolunu buraya yaz.
  /// Boş bırakırsan ('') ya da dosya bulunamazsa 🏏 emojisi kullanılır.
  static const String batImage = 'assets/images/bat.png';

  /// Sopanın yüksekliği (px). Görsele göre büyüt/küçült.
  static const double batSize = 120;
}
