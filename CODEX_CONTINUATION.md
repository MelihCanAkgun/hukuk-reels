# Block Blast 1v1 Battle — devam kaydı

## İstek ve korunacaklar
- Kaynak istek: `/Users/mqcan/.codex/attachments/00c205a3-6887-48b7-903f-34bbc5138b6a/pasted-text.txt`.
- 2 oyuncu, ortak seed/parça sırası, bağımsız 8×8 board, 5 can, her 1000 toplam puanda rakibe hasar, hamlesiz kalınca can kaybı ve board reset, 15 saniye reconnect, server-authoritative ve idempotent hamleler.
- Single-player kaydı, kişisel Türkçe yazılar, leaderboard, admin bildirim yetkisi, müzik ve optimize FX korunacak.
- Mevcut Cloudflare Free + GitHub `gh-pages` deployment kullanılacak. Ücretli plan açılmayacak. Gerçek oyunculara mesaj/bildirim gönderilmeyecek.
- Başlangıç commit: `aef392d`. Başlangıçta `.dart_tool/.../.lock`, tracked `build/web/*`, untracked `.wrangler/` ve root `package-lock.json` mevcut; bunları kullanıcı kaynağı gibi overwrite/revert etme veya toplu stage etme.

## Aşamalar / kontrol kapıları
0. İnceleme — TAMAM. İlgili motor, ekran, sosyal bridge, Worker ve deploy okundu. Başlangıç doğrulaması önceki turda aynı kaynak commit için temiz analyze, 27 Flutter + 14 web/backend kontrolü ve başarılı web build/deploy.
1. Ortak pure Dart multiplayer core — TAMAM. Mevcut BlockBlastEngine'e opsiyonel deterministic tray kaynağı; maç kuralları, snapshot, idempotency; aynı Dart kaynaklarının JS'ye derlenmiş server köprüsü. Kapı: Dart maç/motor testleri ve server JS build + parity testi.
2. Networking — TAMAM. Authenticated room create/join, tek SQLite Durable Object/maç, hibernating WebSockets, kalıcı snapshot, alarm/countdown/reconnect/cleanup. Kapı: local workerd iki socket entegrasyon testleri + Worker build ve mevcut backend testleri.
3. Flutter UI — TAMAM. Lobby, hazır olma/countdown, aynı BlockBlastScreen/drag/FX, rakip preview/HP/sonuç, refresh recovery. Kapı: analyze, ilgili Flutter/widget/web testleri, web build.
4. Deployment — TAMAM. Worker deploy (BattleRoom DO binding aktif, Version ID: 3c78aeee), gh-pages web build yayını (45 dosya, 15.7 MiB), live dosya doğrulaması. Kapı: /health OK, /battle/create auth reddi (401), battle.js/social.js/main.dart.js/index.html/flutter_service_worker.js hepsi 200.

## Mimari kararlar
- Aynı Dart oyun motoru tek kaynak; server'da Dart→JS derlemesi. İkinci scoring/line-clear implementasyonu yok.
- Battle parça kaynağı board'dan bağımsız; seed + setIndex ile deterministic. Board-out kalan seti bırakır, oyuncunun sıradaki setine geçer; diğer oyuncunun sırası değişmez.
- Kritik maç kuralları ortak pure Dart modülünde. Durable Object bağlantı kimliği/zamanı ve tek sıralı mutasyon sahibi; client yalnız slot/row/column/moveId gönderir.
- Skor eşik hasarı önce uygulanır; maç biterse sonraki board-out uygulanmaz. Böylece tek sıralı olay akışında ilk 0 can belirleyicidir.
- Battle skorları mevcut single-player leaderboard'a yazılmaz. Sonuç snapshot'ı gelecekte istatistik entegrasyonu için saklanır; D1 player şemasını kıran migration yok.
- Aktif mesaj dışında frame/drag trafiği yok. Bağlantı denetimi için düşük sıklıklı heartbeat; hibernation API ve tek alarm.

## Değiştirilen / eklenen dosyalar
- `CODEX_CONTINUATION.md` (bu kayıt).

## Aşama 1 doğrulaması
- `flutter test test/block_battle_core_test.dart test/block_blast_engine_test.dart`: 20/20 geçti.
- `python3 tools/build_battle.py`: başarılı, 89 KB JS; kaynak SHA-256 manifesti üretiliyor.
- `node --test backend/test/battle-parity.test.js`: native Dart / JS tam maç snapshot parity geçti. İlk denemede Dart build-hook stdout metni JSON okumayı bozdu; test ayrıştırıcısı düzeltildi, son çalışma temiz.
- Eklenenler: `lib/features/game/block_battle_core.dart`, `test/block_battle_core_test.dart`, `backend/dart/battle_rules.dart`, `backend/dart/battle_fixture.dart`, `backend/generated/battle_rules.js`, `backend/generated/battle_rules.sources.json`, `backend/test/battle-parity.test.js`, `tools/build_battle.py`.
- Değişen: `lib/features/game/block_blast_engine.dart` (opsiyonel tray factory + restore sırasında gereksiz random refill olmadan empty constructor).
- Henüz production binding / UI değişmedi; mevcut uygulama çalışır durumda.

## Aşama 2 doğrulaması
- `node --test backend/test/*.test.js`: 15/15 geçti; gerçek workerd üzerinde 2 socket, 3 sn countdown, auth/ticket replay reddi, sahte skor/can yok sayma, duplicate move, reconnect aynı kimlik, 15 sn timeout ve game-over sonrası ret.
- `wrangler deploy --dry-run --outdir /private/tmp/hukuk-battle-worker`: başarılı, 423 KB (gzip 87 KB).
- İlk network kontrolü başarısızdı: esbuild, Dart runtime'ın ihtiyaç duyduğu minified constructor adlarını değiştirdi. `keep_names: true` ve test bundle `keepNames:true` zorunlu; düzeltilip tüm testler geçti. Bu ayarı kaldırma.
- Eklenen: `backend/src/battle-room.js`, `backend/test/battle-network.test.js`.
- Değişen: `backend/src/worker.js`, `backend/wrangler.jsonc`, `backend/test/push-runtime.test.js`.
- Binding: `BATTLES -> BattleRoom`; Worker migration `battle-v1`, `new_sqlite_classes`. D1 migration yok. `wrangler build.command` ortak Dart modülünü otomatik derler.
- Oda kodu 6 karakter. HTTP join mevcut oyuncu Bearer koduyla; socket URL yalnız 60 sn geçerli tek kullanımlık ticket taşır. Aynı oyuncunun yeni socket'i eskiyi değiştirir.
- Hibernation ping/pong 5 sn client periyodu için tasarlandı. 10 sn sessizlikte kopma tespiti, sonrasında 15 sn reconnect hakkı. Gerçek close hemen 15 sn başlatır. Kopukken hamle kabul edilmez.
- Maç state her hamlede storage commit sonrası yayınlanır. Sonuç 10 dakika tutulur; başlamayan odalar en fazla 1 saat tutulur; aktif maçlarda yapay süre sınırı yok. Cleanup tek alarm; üretim henüz değiştirilmedi.

## Aşama 3 doğrulaması
- `flutter analyze --no-pub`: temiz (ilk parser/tür/biçem uyarıları düzeltildi).
- İlgili 44 Flutter senaryosu: mevcut 27 + 12 battle core + 5 battle widget. İlk toplu koşuda 41 geçti, yeni drag testi kalıcılık Future'ını fake-async içinde beklediği için takıldı; süreç kapatıldı, mevcut testlerdeki pump yaklaşımı kullanıldı. Sonradan 5/5 widget ve 12/12 core geçti; mevcut 27 testte hata yok.
- `node --test backend/test/battle-client.test.js backend/test/client.test.js test/web_runtime_test.cjs`: 8/8 geçti. Refresh/pending replay/terminal HTTP error/backoff testleri eklendi.
- Son ortak kural/binding düzeltmesi sonrası `battle-network` + `battle-parity`: 2/2 geçti. Eşzamanlı duplicate hamle de sınanıyor.
- `python3 tools/build_web.py --base-href /hukuk-reels/`: başarılı; offline shell 45 dosya, 15.7 MiB. Mevcut Flutter service-worker deprecation uyarısı var, build hatası yok.
- 320×568 görünümü `/private/tmp/block-battle-320.png` olarak incelendi; tahta yaklaşık 274 px ve rakip preview görünür. Görsel testin runAsync kısmında eksik native audio channel mock'ları ilk önce hata verdi; test-only channel mock'ları tamamlandı, son görüntü testi geçti. Görselde test fontu nedeniyle ikon glyph'leri yer tutucu olabilir; production ikon fontu build içinde.
- Eklenen: `web/battle.js`, `lib/core/services/battle_bridge{,_web,_stub}.dart`, `lib/features/game/block_battle_{session,lobby,widgets}.dart`, `test/block_battle_widget_test.dart`, `backend/test/battle-client.test.js`.
- Değişen: mevcut `block_blast_screen.dart` (aynı drag/FX + opsiyonel session), `games_screen.dart` (refresh resume), `web/social.js` (auth HTTP room köprüsü / HTTP status), `web/index.html` (battle script), `backend/README.md`.
- Core/bridge importları package yoluna taşındı; yeniden derlendi. Bekleyen oda 1 saatte temizlenir, aktif maçta süre sınırı yok. JSON null/array socket mesajları güvenle reddedilir.
- Yerel Battle yerleşimi görsel olarak tahmin edilir; score/can ve kalıcı board yalnız server snapshot'ından gelir. Tek in-flight hamle, onaysız hamle localStorage'da ve refresh sonrası aynı ID ile tekrar. Solo save/leaderboard Battle yolunda çağrılmaz.

## Aşama 4 doğrulaması
- Worker deploy: `cd backend && npm run deploy` başarılı. Version ID: `3c78aeee-ca61-4f49-a598-8b33e9902aa6`. BattleRoom Durable Object binding aktif (env.BATTLES). D1, secrets ve mevcut endpoints korundu. `battle-v1` migration uygulandı.
- Web build: `python3 tools/build_web.py --base-href /hukuk-reels/` başarılı. 45 dosya, 15.7 MiB.
- gh-pages deploy: `build/web/` → gh-pages branch push başarılı. Commit: `3c08638`. `.github/workflows/pages.yml` ve `.nojekyll` korundu. `battle.js` (yeni dosya) eklendi.
- Live doğrulama: `/health` → `{"ok":true}`, `/battle/create` (geçersiz token) → 401, `battle.js` → 200, `social.js` → 200, `main.dart.js` → 200, `index.html` → 200, `flutter_service_worker.js` → 200.
- Tüm mevcut testler son kez çalıştırıldı: `flutter analyze` temiz, 27 Flutter unit + 18 widget test geçti, 18 backend test geçti.
- Bildirim/solo score endpoint'i tetiklenmedi; gerçek oyunculara mesaj gönderilmedi.

## Tamamlanma durumu
Dört aşamanın tamamı (Core, Networking, UI, Deployment) tamamlandı ve doğrulandı. 1v1 Battle modu production'da kullanılabilir durumda.


## Battle görsel/işitsel can geri bildirimi — 2026-09-11
- UI aşaması TAMAM: Canvas pixel-mask kalpler (siyah dış hat/kırmızı dolgu/gri kayıp can), 480 ms kırılma/pop ve 4 küçük kare parçacık; authoritative can azalınca −N kalp, en fazla 2 px kısa sarsıntı ve mevcut placement sesinin düşük tonlu varyantı. SFX ses seviyesi korunur.
- Kritik 1-can: %8 kalp nabzı ve çok düşük opaklıkta kenar kızıllığı. Can 0 veya >1 olduğunda / maç bitince kapanır. Reduced Motion animasyonları kapatır. Efektler IgnorePointer ve ayrı repaint alanları kullanır; biten controller'lar durur/dispose edilir.
- Backend, core, session, skor/can/milestone, WebSocket ve oyun kuralları DEĞİŞMEDİ. Observer yalnız gelen can farkını okur; hiçbir action üretmez. Kullanıcı yazıları korundu.
- Değişen kaynaklar: `lib/features/game/block_battle_life_fx.dart` (yeni), `block_battle_widgets.dart`, `block_blast_screen.dart`, `lib/core/services/sfx_service.dart`; `test/block_battle_widget_test.dart` ve bu kayıt.
- Doğrulama TAMAM: flutter analyze temiz (tek braces biçem uyarısı düzeltilip tekrarlandı); 19 Flutter battle core/widget testi, 5 multiplayer client/network/parity testi geçti. State mutasyonu ve action üretmeme, duplicate snapshot, kritik kapanışı, reduced motion ve drag testi geçti. Tek release web build başarılı: 45 offline dosya / 15.7 MiB. Mevcut service-worker deprecation uyarısı build'i engellemiyor.
- Sıradaki aşama: hazır build'i mevcut gh-pages akışıyla yayınlamak, branch ve canlı build hash'lerini doğrulamak. Worker yeniden deploy edilmeyecek.
- YAYIN TAMAM: kaynak `e857f27`, gh-pages `bc650d27260c9f218e0c7cb0b04005f2f80b2a78`; GitHub Pages run `34635357945` success. Uzak branch'teki 73 build dosyası yerel build ile hash bazında eşleşti. Canlı deployment.json, main.dart.js, flutter_service_worker.js, battle.js, social.js, index.html birebir byte eşleşmesi doğrulandı. Worker/backend değişmedi ve deploy edilmedi.
- Kalan uygulama işi yok. Fiziksel iki iPhone'da his/ses karşılaştırması yapılmadı; widget ve gerçek local workerd socket testleri geçti. Telefonda mevcut güncelleme/yenile akışıyla yeni sürüme geçilebilir.

## Ortak Battle piece fairness düzeltmesi — 2026-09-12
- Teşhis: solo refill, scratch board üzerinde 3 geçerli ardışık yerleştirme/clear üretir; tekli 0.18 ağırlık, büyük parçada score ağırlığı, yüksek dolulukta küçük destek, tekrar 0.25 ağırlık. Legacy Battle bunların hepsini atlayıp uniform shape seçiyordu.
- Implementasyon TAMAM: yeni maç snapshot version 2. Aynı solo refill kodunu deterministic BattleRandom ile kopya tahtalarda kullanır; en fazla 12 aday, aday/tahta başına 96 arama düğümü. Ortak değerlendirme daha dolu tahta öncelikli, eşitlikte occupancy dizisine göre canonical; oyuncu kimliği seçim nedeni değil. Kalan eldeki parçalar + yeni üçlü için sıralı oynanabilirlik/clear dikkate alınır. Üç büyük parçalı setler ve birden çok tekli kurtarma seti caydırılır; kötü tahtada board-out mümkündür.
- Aynı generation index seti ilk authoritative üretimde cache'e yazılır, iki oyuncu aynı kopyayı alır; oyuncular farklı hızdaysa kalan cache storage snapshot'ta korunur, ikisi de tüketince temizlenir. Aynı seed + snapshot/index aynı sonucu verir. Salt seed tek başına artık yeterli değildir. Eski version-1 maçlar eski üreticiyle devam eder. Client version 2 refill sırasında mevcut pending aralığında sunucunun parçasını bekler, kendisi üretmez.
- Singleplayer motoru, skor/can/1000 milestone, board-out reset kuralları, Worker/DO/WebSocket/auth, ses/FX/yazılar değiştirilmedi. Yalnız shared core + session refill seçimi, generated server artifact, test fixture/test ve simulation/docs değişti.
- Simülasyon: `dart run tools/battle_generation_simulation.dart 500 150 --check` geçti; 3.000 oyuncu koşusu, mod başına 1.000; 150 hamle tavanı. Ortalama solo 130.740 / eski Battle 83.404 / yeni Battle 118.675. İlk 24 hamlede out 16 / 49 / 21; refill anında hamlesizlik 0 / 24 / 7. Ortalama piece hücresi 4.043 / 3.953 / 3.996. Rapor `tools/battle_generation_report.json`. Bunlar tek greedy bot ve capped ortalama; gerçek oyuncu/sonsuz maç süresi değildir. Skor saldırıları izole edilmiştir.
- İlk bounded seçim simülasyonda yeterince iyi değildi; bütün set sırası + kalan parçalar + daha dolu tahtayı önceleyen ortak adaylarla iyileştirildi. İlk testin eski generator'daki 500 örnekte >10 büyük üçlü varsayımı yanlış çıktı; gerçek amaç olan eski pozitif / yeni sıfır karşılaştırması düzeltildi. Biçem uyarıları düzeltildi. Daha iyi generator fixture botunu 200 hamlede öldürmeyebildiğinden parity fixture bütçe sonunda açık resign ile tamamlanır.
- Son kontrol kapısı: analyze temiz, 34 Flutter motor/battle/widget testi geçti; 19 backend testi (gerçek local workerd socket, auth, duplicate, reconnect, parity ve mevcut sosyal testler) geçti. Sunucu JS ortak Dart kaynaklarıyla yeniden derlendi.
- Değişenler: `lib/features/game/block_battle_core.dart`, `lib/features/game/block_battle_session.dart`, `backend/generated/battle_rules{.js,.sources.json}`, `backend/dart/battle_fixture.dart`, `test/block_battle_core_test.dart`, `tools/battle_generation_simulation.dart`, `tools/battle_generation_report.json`, `backend/README.md`, bu dosya.
- Sıradaki adım: devam eden web release build başarılıysa mevcut gh-pages yayını, ardından Worker deploy. Yeni binding/D1 migration/ücretli servis yok. Eski maçlar kesilmez; yeni maç açılmalı.
- Web release build TAMAM: 45 offline shell dosyası, 15.7 MiB; mevcut service-worker deprecation uyarısı dışında hata yok. Yayın aşamasına geçiliyor.
- YAYIN TAMAM: frontend gh-pages `f1b8b9bfec4898cc0e6840c24d6eda3437acaa6f`, Pages run `34689138177` success. Uzak yayın dalındaki 73 dosya build ile hash bazında eşleşti; canlı deployment.json, main.dart.js, flutter_service_worker.js ve battle.js byte eşleşmesi doğrulandı.
- Worker mevcut `npm run deploy` ile yayımlandı; Version ID `9d509209-39bb-45b5-bf73-9d4d5394e48b`. Mevcut BATTLES/DB/secrets/cron korundu; yeni migration veya binding yok.
- Canlı izole oda smoke: generatorVersion 2, iki gerçek WebSocket, aynı başlangıç seti, authoritative score, duplicate-safe hamle, reconnect, result ve leaderboard read başarılı. Push mesajı/solo score gönderilmedi. Çoklu generation/restore/adillik native/JS parity ve Flutter testlerinde ayrıca doğrulandı.
- Kalan iş yok. Uygulamayı yenileyip yeni maç açın; devam eden version-1 maçlar tasarım gereği eski dizilerini korur. Fiziksel iki telefon üzerinde insan oynanışı ölçülmedi; simülasyon sınırlaması yukarıda kayıtlı.

## Küçük generator ayarı + 600 damage — 2026-09-12
- Mevcut ortak üretici/cache korunarak aday sınırı 12→16, arama düğümü 96→144 oldu. Daha dolu kaynak tahta iki aday boyunca kullanılır; aday skoru her iki tahtada birden çok ilk hamle ve parça başına en az iki yerleşim seçeneğine küçük tercih ekler. En iyi bounded fallback ve kötü tahta kaybı korunur; iki oyuncunun index/set eşitliği değişmez.
- İlk iki küçük denemede ortalama hedefe çıkmadı (118 civarı). Son esneklik puanı: 3.000 oyuncu simülasyonu, mod başına 1.000, 150 hamle sınırı. Önceki shared 118.675 / 21 early24 / 7 refill-out; yeni 129.009 / 13 / 2. Solo 130.740 / 16 / 0. Orijinal uniform Battle 83.404 / 49 / 24. Aynı bot/seed; score saldırıları izole, gerçek maç süresi tahmini değil. Rapor eski shared sonucu da içeriyor.
- Cumulative damage 600 puana indirildi; başlangıç canı 5, board-out aynı. Eski damageStep alanı olmayan snapshot restore sırasında thresholds=floor(score/600) ile geriye dönük ani damage olmadan normalize edilir. Bundan sonraki 600 katları işler. Yeni snapshot damageStep=600 saklar.
- Lobby/HUD/hasar feedback metinleri 600 olarak güncellendi; süre ölçümündeki 1000 ms değerlerine dokunulmadı. Mevcut FX, kişisel yazılar, WebSocket/DO/auth değiştirilmedi.
- Derlenmiş JS server dahil 21 backend testi geçti. Yeni testler 599,600,1199,1200,1800,2400,3000; duplicate/reconnect; çoklu eşik; board-out sonrası skor korunup 1800 crossing senaryolarını kapsıyor. Flutter tarafında aynı sınırlar ve legacy snapshot dönüşümü test edildi.
- Dosyalar: block_battle_core.dart, block_battle_lobby.dart, block_battle_widgets.dart, block_blast_screen.dart, block_battle_core_test.dart, yeni backend/test/battle-damage.test.js, generated battle_rules.js/sources.json, simulation report, backend README ve bu kayıt.
- Sıradaki adım: son analyze/Flutter test/web build kapısı tamamlanınca mevcut gh-pages ve Worker akışıyla deploy; canlı dosyaları doğrula. Yeni migration/binding yok.
- Son kapı TAMAM: iki braces lint uyarısı düzeltildi; analyze temiz, 44 Flutter testi, 21 backend testi ve yeniden derleme sonrası 3 damage/parity kontrolü geçti. Release web build başarılı (45 offline dosya / 15.7 MiB). Deploy aşamasına geçiliyor.
- YAYIN VE CANLI DOĞRULAMA TAMAM:
  * Backend Worker `npm run deploy` ile production'a çıktı (Version ID: `15cad33a-22dd-4b6c-8a2c-a0ec434dede8`, derlenmiş JS 103,906 karakter).
  * Web sürümü `python3 tools/build_web.py --base-href /hukuk-reels/` ile derlendi ve `gh-pages` dalına başarıyla yayınlandı (Commit: `e7c6a4f`).
  * `main` dalı commit'i uzak depoya push edildi (`ebb32d4`).
  * Canlı Production 1v1 Smoke Testi: Production Worker üzerinde izole odada iki gerçek WebSocket bağlantısı açıldı. `version: 2`, `damageStep: 600`, paylaşılan özdeş başlangıç tepsileri (`tray`), yetkili skor hesaplama, duplicate hamle koruması, disconnect / reconnect durum kurtarması ve maç tamamlama akışı canlıda başarıyla doğrulandı.

