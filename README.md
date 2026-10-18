# Hukuk Reels · Oyunlar

Flutter ile mini oyunlar (Block Blast, Flappy Silly Cat, Subway Silly, Adliye Kulesi), ders özetleri ve hukuk soru bankası. Uygulama dört sekmeden oluşur (`lib/features/shell/home_shell.dart`): **Ana sayfa** (selam, kavuşma sayacı, mantar pano, kaldığın yerden), **Oyunlar**, **Çalış** (özetler ve soru pratiği) ve **Profil**. Sekme çubuğu telefonda ve dikey iPad'de altta, geniş yatay ekranda soldadır; etkin sekmeye yeniden dokunmak başa kaydırır. Flutter web iOS'un güvenli alanını bilmediği için `web/pwa.js` alt boşluğu (ana ekran çizgisi) CSS `env(safe-area-inset-*)` ile ölçer, `WebSafeArea` bunu MediaQuery'ye ekler; ana ekrandan açılan uygulamada değer gelmezse Face ID'li iPhone'larda 34 (yatayda 21) piksel varsayılır.

Sağ üstteki müzik düğmesi **Ses** panelini açar: çalan parça, ilerleme ve sarma, çal/durdur, önceki/sonraki, parça listesi; müzik ve oyun efektleri için ayrı ses düzeyi ve sessize alma.

## Çalıştırma

Flutter 3.41.6 / Dart 3.11.4 ile doğrulandı. Apple hedefleri proje düzeyinde Swift Package Manager kullanır.

```sh
flutter pub get
flutter test
flutter analyze
node test/web_runtime_test.cjs
node test/notes_ink_test.cjs
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter run -d macos
```

Web/PWA yayın paketi için **aşağıdaki betiği kullanın**. Sadece `flutter build web`, özel çevrimdışı worker'ı hazırlamaz.

```sh
python3 tools/build_web.py
# GitHub Pages alt dizini örneği:
python3 tools/build_web.py --base-href /hukuk-reels/
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Çıktı `build/web` içindedir. Oyunlar ilk başarılı önbelleklemeden sonra çevrimdışı açılır. Müzik internet ister. Yeni sürüm açık oyunu otomatik yenilemez; oyuncuya yenileme düğmesi gösterilir. Betik sürüm kimliğini içeriklerden üretir. CanvasKit aynı sunucudan yüklenir; CDN gerekmez.

## Özetler ve not modu

**Çalış** sekmesindeki **Özetler** bölümü ders özetlerini listeler (şimdilik İcra Hukuku). Özet, Flutter'ın üstünde açılan ayrı bir DOM katmanında gösterilir (`web/notes/notes.js`, `notes.css`). Kalem gecikmesi Flutter'ın kare zamanlamasına bağlı olmasın diye bu katman Flutter'ın dışındadır. Not modu iPad ve Apple Pencil için tasarlanmıştır.

- **Girdi:** Apple Pencil (`pointerType: pen`) yazar, parmak kaydırır, iki parmak yakınlaştırır. İki parmakla dokunma geri alır, üç parmakla dokunma yineler, tek parmakla çift dokunma 2 kat yakınlaştırır ya da sayfaya sığdırır. Kalem değerken ve büyük temas alanlı dokunuşlarda kaydırma yapılmaz (avuç içi). Yakınlaştırma oranı ekran döndürülünce korunur. Masaüstünde fare de yazar.
- **Araçlar:** basınca duyarlı kalem, fosforlu kalem, çizgi ve hassas silgi (istenirse yalnız fosforluyu siler), kement. Kement seçimi taşınır, köşesindeki tutamaçla büyütülür, çoğaltılır, silinir ya da renklendirilir (kalem ve fosforlu kendi paletinden renk alır). Çizerken kalemi bekletmek çizgiyi düzeltir. Fosforlu çizgi düzleşir ve altındaki satırın ortasına oturur; daire ve karalamalar korunur (menüden kapatılabilir).
- **Gezinme ve arama:** İçindekiler bulunulan bölümü ve bölüm başına not sayısını gösterir; başlıkta o anki bölüm yazar. Arama Türkçe harf, şapka ve büyük/küçük harf farkı gözetmez.
- **Klavye:** ⌘Z / ⇧⌘Z geri al / yinele, ⌘F ara (Enter sonraki, ⇧Enter önceki), ⌘P yazdır, ⌘A tümünü seç, ⌘0 sığdır, ⌘+ / ⌘− yakınlaştır, 1–4 araç seçer, Sil seçimi siler. Esc sırayla aramayı, seçimi, menüyü ve en son özeti kapatır.
- **Araç çubuğu:** Genişlik ölçülerek adım adım sıkışır (başlık, etiket, arama, renkler menüye iner); telefon genişliğinde de taşmaz.
- **Yazdırma / PDF:** Sayfa A4'lere bölünür. Satırlar, kutular ve notlar ortadan kesilmez; başlık, altındaki metinle aynı sayfada kalır. Kenarda not yoksa sayfa metin sütununa kırpılır. Altbilgide özet, bölüm, tarih ve sayfa numarası yazar. Notlar gizliyse temiz özet basılır.
- **Saklama:** Notlar 1180 birimlik sabit sayfa koordinatlarında vektör olarak cihazda (IndexedDB `hukuk-notes`) tutulur; hesaba bağlı değildir. IndexedDB açılamaz ya da geç yanıt verirse notlar `localStorage`'a yazılır ve IndexedDB'ye ulaşılınca onunla birleştirilir. Menüden JSON yedek alınabilir ve geri yüklenebilir.
- **Özet güncellenince:** Her kayıt sayfanın temelini de saklar: her bloğun anahtarı (bölüm, etiket, metin özeti) ve kutusu. Açılışta kayıtlı temel güncel sayfayla karşılaştırılır. Bloklar bölüm bölüm en uzun ortak alt dizi ile eşlenir ve her not ait olduğu bloğun yeni yerine kaydırılır; şekli bozulmaz. Metni değişen blokta komşu blokların kaymasından aradeğer alınır, sayfa sonundaki not alanı içeriğin sonuyla birlikte kayar. Temeli olmayan eski kayıtlarda, kaydın alındığı sürümün dondurulmuş metni (`summaries/<id>.v<sürüm>.js`, ör. `icra.v1.js`) görünmez bir sayfada ölçülür; bu dosyalar değiştirilmemelidir.
- **Performans:** Notlar 1200 birimlik karolara (ayrı SVG'ler) bölünür; ekrandan uzak karolar gizlenir ve yolları ekrana yaklaşınca üretilir. Yollar 10x ölçekte tam sayılarla yazılır, noktalar Float32Array olarak saklanır.
- **Yedek hatırlatması:** Not sayısı 40'ı geçince, ana ekrana eklenmemiş Safari'de 7 günde bir, uygulama olarak kullanılırken 21 günde bir yedek almayı hatırlatır (Safari ziyaret edilmeyen sitelerin verisini silebilir).
- **Yeni özet:** `web/notes/summaries/<id>.js` içinde `window.hukukNotesRegister({id, title, version, html})` çağrılır, ardından `lib/features/summaries/summaries_screen.dart` içindeki `kSummaries` listesine eklenir. Metin değişince `version` artırılır. Kayıtlar ve yedekler temeli içerdiği için yeni sürümlerde dondurulmuş kopya gerekmez; yalnız temelsiz kayıtların sürümü (İcra için 1) dondurulur.

## Apple uygulamaları

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build macos --release
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter build ios --simulator --no-codesign
```

Bu makinede macOS release derlemesi başarılıdır. iOS simülatörü için Xcode'un istediği iOS 26.5 bileşeni eksiktir; Xcode > Settings > Components üzerinden kurulmalıdır. Cihaz/imzalı dağıtım için kendi bundle identifier ve Apple geliştirici takımınızı seçin. Üretilmiş native uygulama ikonları Flutter şablonudur; mağaza yayını öncesi kişiselleştirilmelidir.

## Oyun kuralları

Block Blast motoru `lib/features/game/block_blast_engine.dart` içindedir. 8×8 tahta, mevcut 33 şekil yönelimi ve üçlü tepsi kullanılır. Üretici, sanal tahtada üç hamlenin tamamının oynanabildiği bir sıra oluşturup parçaları karıştırır. Oyuncunun her tercihinde çözüm garantisi verilmez.

- Yerleştirme: hücre sayısı kadar puan.
- Temizleme: `10 × çizgi sayısı² × kombo`.
- Tahtanın tamamen temizlenmesi: ilave 300 puan.
- Temizleme kombo sayısını bir artırır; arka arkaya üç temizlemesiz hamle komboyu sıfırlar. Süre sınırı yoktur.
- Tahta, tepsi, puan, kombo ve devam hakkı her hamlede kaydedilir. Kural işlemi animasyondan önce tamamlanır.

Bu formül, Hungry Studio'nun yayımlanmamış algoritmasının birebir kopyası olduğu iddiasını taşımaz. Mevcut görseller ve WAV sesleri kullanılır; kombo arttıkça efekt hızı yükselir.

[İnceleme, değişiklikler ve kalan işler](docs/APPLE_GAME_REVIEW.md)
