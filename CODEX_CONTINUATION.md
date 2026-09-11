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
4. Deployment — SIRADAKİ. Mevcut Worker bindings/migration, gh-pages build yayınlama ve uzak branch/live doğrulama. Kapı: mevcut leaderboard/health read-only smoke, iki test oturumu networking smoke (gerçek bildirim yok), 72+ build dosyası hash kontrolü.

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

## Sıradaki adım
Aşama 4: mevcut `npm run deploy` ile Worker/SQLite DO binding'ini uygula (Free planı değiştirme), ardından yeni web build'ini mevcut gh-pages checkout akışıyla yayınla. İzole test odasında iki mevcut oyuncu kimliğiyle WebSocket smoke yap; bildirim/solo score endpoint'ini tetikleme. Yeni build'in uzak branch ve live hash'lerini doğrula, bu kayda sürüm/commit sonuçlarını ekle.
