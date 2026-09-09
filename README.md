# Hukuk Reels · Oyunlar

Flutter ile mini oyunlar (Block Blast, Flappy Silly Cat, Subway Silly) ve hukuk soru bankası. Açılışta oyun menüsü gösterilir; testler, profil ve mevcut rekorlar korunur.

## Çalıştırma

Flutter 3.41.6 / Dart 3.11.4 ile doğrulandı. Apple hedefleri proje düzeyinde Swift Package Manager kullanır.

```sh
flutter pub get
flutter test
flutter analyze
node test/web_runtime_test.cjs
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer flutter run -d macos
```

Web/PWA yayın paketi için **aşağıdaki betiği kullanın**. Sadece `flutter build web`, özel çevrimdışı worker'ı hazırlamaz.

```sh
python3 tools/build_web.py
# GitHub Pages alt dizini örneği:
python3 tools/build_web.py --base-href /hukuk_reels/
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Çıktı `build/web` içindedir. Oyunlar ilk başarılı önbelleklemeden sonra çevrimdışı açılır. Müzik internet ister. Yeni sürüm açık oyunu otomatik yenilemez; oyuncuya yenileme düğmesi gösterilir. Betik sürüm kimliğini içeriklerden üretir. CanvasKit aynı sunucudan yüklenir; CDN gerekmez.

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
