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
  /// 2) Dosya adını aşağıdaki listeye ekle: 'assets/audio/dosya_adi.m4a'
  /// 3) Uygulamayı yeniden başlat (web için: flutter build web).
  ///
  /// Birden fazla parça eklersen hepsi sırayla, kesintisiz döngüyle çalar.
  static const List<String> musicTracks = [
    'assets/audio/Wildflower.m4a',
    'assets/audio/Dolu_Kadehi_Ters_Tut.m4a',
    'assets/audio/Sad_Girl.m4a',
    'assets/audio/Takil_Yani_Takmiyo_Belli.m4a',
    'assets/audio/Aramizda_Dinozor.m4a',
    'assets/audio/Bari_Ruyalarima_Gel_Be.m4a',
    'assets/audio/Bekledigim_Gibiyim.m4a',
    'assets/audio/Degistim.m4a',
    'assets/audio/Far_From_Any_Road.m4a',
    'assets/audio/Gunduz_Yuzlu_Kiz.m4a',
    'assets/audio/O_Ben_Olurum.m4a',
    'assets/audio/Sadece_Senin_Olmak.m4a',
    'assets/audio/Sahte_Dualar.m4a',
    'assets/audio/Zaman_Yok.m4a',
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
  static const double batSize = 150;
}
