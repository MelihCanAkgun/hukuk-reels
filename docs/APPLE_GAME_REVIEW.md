# Apple cihazlar ve oyun odaklı proje incelemesi

9 Eylül 2026. İnceleme kapsamı: uygulama girişi, üç oyun, ortak canlandırma katmanı, ses köprüleri, kalıcı ilerleme, soru/tekrar/profil akışları, asset yapısı ve PWA dağıtımı. Soru bankasındaki hukuk metinlerinin içerik doğruluğu bu teknik incelemenin kapsamında değildir.

## Teknoloji kararı

Flutter'ı korumak bu proje için uygun. Block Blast seyrek durum değişiklikleri olan bir 2D bulmaca; mevcut CustomPainter yaklaşımı yeterli. Subway zaten tek tuval ve repaint bildiricisi kullanıyor. Bir SwiftUI/SpriteKit yeniden yazımı öncesinde temel sorunlar kurallar, yaşam döngüsü ve dağıtım altyapısındaydı. Native Flutter iOS, Impeller kullanabilir; Safari web sürümü ise CanvasKit kullanır. Web sonucunu native iOS performans ölçümü saymamak gerekir.

Dayanaklar: [Flutter Impeller](https://docs.flutter.dev/perf/impeller), [fiziksel cihazda performans ölçümü](https://docs.flutter.dev/perf/ui-performance), [Apple hedeflerinin kurulumu](https://docs.flutter.dev/platform-integration/ios/setup), [Swift Package Manager](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers).

Orijinal oyunun [resmî App Store açıklaması](https://apps.apple.com/us/app/block-blast/id1617391485), 8×8 tahta, sürükleyerek yerleştirme ve kombo odaklı yüksek skor akışını doğrular. Tam puan formülü, blok dağılım olasılıkları ve zorluk algoritması yayımlanmış değildir. Bu değişikliklerde kuralları açıkça tanımlanan bir yaklaşım kullanıldı; orijinal görsel/ses varlıkları indirilmedi.

## Bulgular ve yapılanlar

| Alan | Önce | Değişiklik |
| --- | --- | --- |
| Apple hedefleri | Sadece web klasörü vardı | iOS ve macOS runner'ları, Swift Package Manager entegrasyonu; macOS ağ istemcisi entitlement ve asgari pencere ölçüsü |
| Ana akış | Hukuk sorularıyla açılış | Oyun menüsüyle açılış; Block Blast ilk sırada; soru bankası ve profil menüde |
| Oyun motoru | Kurallar ve widget durumları aynı dosyadaydı | Saf Dart motoru; UI, ses ve depolamadan ayrıldı |
| Blok üretimi | Her parça yalnız mevcut tahtada değerlendiriliyordu; yoğun kurtarma küçük bloklara yığılıyordu | Sanal tahtada ardışık üç yerleştirme ve eşzamanlı çizgi temizliği; karıştırılmış çözülebilir tepsi, tekrar ağırlığı azaltma, skor/doluluk ağırlıkları |
| Puan | Hücre + küçük çizgi bonusu; gerçek zincir yok | Açık formül, çoklu çizgi çarpanı, üç hamlelik kombo toleransı, tüm tahtayı temizleme bonusu |
| Geri bildirim | Çizgiler anında kayboluyordu | Parçacık/parlama animasyonu, artan puan sayacı, kombo ve hamle göstergesi; azaltılmış hareket ayarına saygı |
| Kontrol | Sürükleme hareketi 2× büyütülüyordu | Dokunmada 1.8× hareket, basıldığı anda büyüyüp parmak üstüne kaldırma (farede 1:1), tek etkin sürükleme, geçersiz bırakmada geri dönüş, ekran değişiminde sürüklemeyi iptal etme |
| Görünüm | Uygulamanın genel pembe teması, genişliğe göre sabit tahta | Lacivert oyun alanı, renkli bloklar; yüksekliğe de uyan tahta, tepsiye sığan uzun bloklar, soluk oynanamaz parçalar |
| Kayıt | Yalnız oyun sonunda rekor; tahta kayboluyordu | Her hamlede tahta/tepsi/kombo/devam hakkı; sıralı disk yazımı, bozuk kayıt denetimi, anlık rekor; eski rekorlar korunur |
| Devam hakkı | Sorudan çıkıp tekrar girme suistimal edilebilirdi | Hak soru açılırken tüketilir ve kaydedilir; gecikmiş cevap zamanlayıcısı çıkış/reset sırasında iptal edilir |
| Diğer oyunlar | Arka plan ve müzik paneli sırasında güvenli duraklama yoktu | Arka plana/ölçü değişimine/panele geçişte duraklatma; dönüşte açık devam düğmesi; 1/120 sn sabit fizik adımları |
| Subway kaynakları | Görsel codec ve image serbest bırakılmıyordu; boşta repaint | Codec/image dispose; oynamıyorken tekrar tekrar tuval çizme kaldırıldı |
| Native efektler | Aynı AudioPlayer'a çakışan seek/play çağrıları | Efekt başına iki hazırlanmış kanal; dolu kanala yeniden seek gönderilmez; başarısız hazırlamada dispose |
| Safari ses | `await play()` bitişi beklediğinden ses seviyesi düzeltmesi gecikiyordu | Çalmayı başlatıp ses seviyesini hemen uygular; değişen audio elemanlarını yakalar; interrupted AudioContext toparlama; biten kaynakları ayırma |
| Açılış | Ses hazırlanması ilk ekranı bekletiyordu | Ses hazırlığı ilk ekranı engellemez |
| PWA | Kullanılmayan worker + Flutter'ın kaldırma worker'ı; açık oyunu yenileme riski | İçerik hash'li tek aktif offline worker, atomik oyun önbelleği, oyuncu kontrollü güncelleme, yalnız uygulamaya ait cache temizliği |
| Dağıtım | CDN/önbellek davranışı belirsizdi | Yerel CanvasKit; yaklaşık 15.2 MiB oyun paketi; yaklaşık 31 MiB müzik ilk kurulumda indirilmez |
| Kalite | Test klasörü boştu | Motor, depolama, widget/yaşam döngüsü testleri; WebAudio ve worker kontrolleri; lint yapılandırması |

## Doğrulama ve sınırlar

- Flutter 3.41.6 / Dart 3.11.4 üzerinde analiz ve otomatik testler.
- 90 farklı seed/doluluk için bağımsız üç hamle çözücüsü.
- Çapraz temizlemede kesişim tek hücre olarak temizlenir, iki çizgi puanı verilir.
- Kombo artışı/sıfırlanması, tüm tahta bonusu, geçersiz hamle, tepsi yenileme, bozuk kayıtlar, sıralı yazımlar ve revive testleri.
- Widget testleri: 320×568, 375×667, 393×852, 844×390, 1024×768, 507×768; 2× metin ve azaltılmış hareket; çizgi temizleyen sürükleme; animasyon sırasında çıkış ve geri yükleme.
- Yerel tarayıcıda 393×852 görünüm, sürükleme/puan, sayfayı yeniden yükleyip kayıtlı tahtayı açma kontrol edildi. Konsolda hata görülmedi. Bu, fiziksel iPhone testi değildir.
- Web release ve macOS release derlemeleri alındı.
- iOS derlemesi Xcode'un istediği iOS 26.5 platformu eksikliğinde durdu. CoreSimulator sürümü de Xcode ile uyumsuz görünüyor (1051.49.0 / 1051.55.0). Sistem bileşenleri değiştirilmedi.

## Sıradaki öncelikler

1. Fiziksel iPhone ve iPad'de profile modunda frame sürelerini, uzun oyun oturumlarında sıcaklığı/pili ve ses gecikmesini ölçmek. 60/120 Hz fizik tutarlılığı kodda iyileştirildi; ölçülmüş FPS iddiası yoktur.
2. Gerçek kullanıcı denemeleriyle puan/üçlü üretim zorluğunu ayarlamak. Şu an yeni tepsinin en az bir tam çözümü var; oyuncunun her yanlış tercihinden kurtulacağı garanti edilmez.
3. Apple cihazında çağrı, kulaklık/Bluetooth değişimi, sessiz anahtar, kilit ekranı ve PWA yeniden açılışı için ses testi. Native iki kanallı just_audio yeterli gecikmeyi sağlayamazsa AVAudioEngine tabanlı küçük bir efekt köprüsü değerlendirmek.
4. VoiceOver ile hücre/parça seçimi ve klavyeyle Block Blast oynanışı. Mevcut çalışma metin boyutu, hareket tercihi, buton dokunma alanı ve tahta etiketini iyileştirir; tam VoiceOver oynanabilirliği sağlamaz.
5. Uygulama kimliği, özel native ikonlar, geliştirici takım/imza ve TestFlight dağıtımı. Mevcut runner'lardaki `com.example.hukukReels` ve Flutter ikonları geliştirme şablonudur.
6. Repoda önceden takip edilen `build/`, `.dart_tool/`, `.DS_Store` dosyalarını ayrı bir depo temizliği değişikliğinde takipten çıkarmak. Yeni `.gitignore` gelecekteki dosyaları engeller; mevcut takipleri kendiliğinden kaldırmaz.

Test ve derleme komutları README'dedir. İnceleme sırasında mevcut kullanıcı `.DS_Store` değişiklikleri korunmuştur. Mağaza gönderimi yapılmamıştır. Web sürümü mevcut GitHub Pages kanalından yayımlanır.

10 Eylül sürükleme düzeltmesi: jest eşiği kaldırıldı; dokunur dokunmaz 110 ms büyüme, 64 px kaldırma ve 1.8× parmak hareketi. Parça alt kenarı aşağı düzeltmelerde de parmağın en az 32 px üstünde kalır. Sadece kayan parçanın konumu her pointer olayında güncellenir; ekran yalnız hedef hücre değiştiğinde yeniden kurulur. İkinci parmak ve yalnız dokunup bırakma yerleştirme yapmaz.
