# Hukuk Reels · Oyunlar

Flutter ile mini oyunlar (Block Blast, Flappy Silly Cat, Subway Silly) ve hukuk soru bankası. Açılışta oyun menüsü gösterilir; testler, profil ve mevcut rekorlar korunur.

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

Oyunlar sekmesindeki **Özetler** girişi ders özetlerini listeler (şimdilik İcra Hukuku). Özet, Flutter'ın üstünde açılan ayrı bir DOM katmanında gösterilir (`web/notes/notes.js`, `notes.css`). Kalem gecikmesi Flutter'ın kare zamanlamasına bağlı olmasın diye bu katman Flutter'ın dışındadır.

- **Girdi:** Apple Pencil (`pointerType: pen`) yazar, parmak kaydırır, iki parmak yakınlaştırır. İki parmakla dokunma geri alır, üç parmakla dokunma yineler. Kalem değerken ve büyük temas alanlı dokunuşlarda kaydırma yapılmaz (avuç içi). Masaüstünde fare de yazar.
- **Araçlar:** basınca duyarlı kalem, fosforlu kalem, çizgi ve hassas silgi, kement (taşı, çoğalt, sil, renklendir). Çizerken kalemi bekletmek çizgiyi düzeltir.
- **Saklama:** Notlar 1180 birimlik sabit sayfa koordinatlarında vektör olarak cihazda (IndexedDB `hukuk-notes`) tutulur; hesaba bağlı değildir. Menüden JSON yedek alınabilir ve geri yüklenebilir. Yazdır/PDF de menüdedir.
- **Yeni özet:** `web/notes/summaries/<id>.js` içinde `window.hukukNotesRegister({id, title, version, html})` çağrılır, ardından `lib/features/summaries/summaries_screen.dart` içindeki `kSummaries` listesine eklenir. Var olan bir özetin metnini değiştirmek sayfa yüksekliğini değiştirir ve alınmış notları kaydırabilir. Bu nedenle büyük değişikliklerde `version` artırılmalı ya da yeni bir özet kimliği kullanılmalıdır.

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
