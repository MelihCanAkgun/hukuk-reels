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
2. Networking — SIRADAKİ. Authenticated room create/join, tek SQLite Durable Object/maç, hibernating WebSockets, kalıcı snapshot, alarm/countdown/reconnect/cleanup. Kapı: local workerd iki socket entegrasyon testleri + Worker build ve mevcut backend testleri.
3. Flutter UI — BEKLİYOR. Lobby, hazır olma/countdown, aynı BlockBlastScreen/drag/FX, rakip preview/HP/sonuç, refresh recovery. Kapı: analyze, ilgili Flutter/widget/web testleri, web build.
4. Deployment — BEKLİYOR. Mevcut Worker bindings/migration, gh-pages build yayınlama ve uzak branch/live doğrulama. Kapı: mevcut leaderboard/health read-only smoke, iki test oturumu networking smoke (gerçek bildirim yok), 72+ build dosyası hash kontrolü.

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

## Sıradaki adım
Aşama 2: authenticated oda ve Durable Object networking, WebSocket hibernation/kalıcı state/alarmlar/entegrasyon testleri. Önceki Aşama 1 notu: opsiyonel tray factory, pure Dart battle state ve kritik senaryo testlerini uygula. Her aşama sonunda bu dosyaya gerçek komut/sonuçları ve değişen dosyaları yaz; geçmeyen kontrolü gizleme. Yeni aşamaya geçmeden mevcut kapıdan geç.
