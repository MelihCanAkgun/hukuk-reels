# Hukuk Reels · Oyunlar

**Flutter ile yazılmış, çevrimdışı çalışan bir web uygulaması (PWA): piksel-arcade mini oyunlar, gerçek zamanlı 1v1 mod, reels tarzı hukuk soru pratiği ve kalemle not alınabilen ders özetleri. Sosyal özellikler Cloudflare Workers + D1 üzerinde çalışır.**

[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.27-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.6-0175C2?logo=dart)](https://dart.dev)
![PWA](https://img.shields.io/badge/PWA-çevrimdışı-5A0FC8)
[![Cloudflare Workers](https://img.shields.io/badge/backend-Cloudflare%20Workers%20%2B%20D1-F38020?logo=cloudflare)](backend/)

Bu uygulama kişisel kullanım içindir; herkese açık bir demo bulunmuyor.

Uygulama küçük, kapalı bir kullanıcı grubu için geliştirildi. Sosyal özellikler (sıralama, 1v1, bildirimler, izleme listesi) bu nedenle kendi backend'inize bağlanmadan çalışmaz. Tek kişilik oyunlar ve çalışma araçları backend olmadan da kullanılabilir.

---

## Öne çıkanlar

- **Tek kod tabanı, üç hedef:** Web/PWA birincil hedef. Aynı kod macOS ve iOS için native olarak da derlenir. Tarayıcıya özgü yetenekler koşullu import'lu köprülerle ayrılmıştır.
- **İstemci ve sunucuda aynı oyun kuralları:** 1v1 kural motoru Dart'ta yazılır, `dart compile js` ile Worker'a derlenir. Hamleleri sunucu, istemcinin kullandığı kodun aynısıyla doğrular.
- **Gerçek zamanlı çok oyunculu mod:** Cloudflare Durable Objects üzerinde WebSocket tabanlı maç odaları.
- **Çevrimdışı öncelikli PWA:** Özel service worker, içerikten türetilen sürüm kimliği ve kullanıcı onaylı güncelleme akışı.
- **Performans odaklı web çıktısı:** Varsayılan motor WebAssembly (skwasm), CanvasKit yedekte. Motor dosyaları CDN'siz, aynı sunucudan gelir.

---

## Özellikler

### Oyunlar
- **Block Blast:** 8×8 tahta, sürükle-bırak, kombo/puan sistemi ve "tahta temiz" bonusu. Her tepsideki üç parça, en az bir oynanabilir yerleştirme sırası olacak şekilde üretilir. İlerleme her hamlede kaydedilir.
- **1v1 Battle:** İki oyuncu aynı parça sırasıyla Block Blast'ta gerçek zamanlı yarışır. Can sistemi, puan eşiklerinde rakibe hasar ve dört joker (dondur, genişlet, yansıt, tuz) var. Bağlantısı kopan oyuncunun yeniden bağlanmak için 15 saniyesi olur.
- **Flappy Silly Cat**, **Subway Silly** ve **Adliye Kulesi** (kat dizme) mini oyunları. Çizimler `CustomPainter` ile yapılır, sprite'lar Python betikleriyle üretilir.
- Her oyun için **sıralama tablosu** ve 7 günlük turlarla **haftalık meydan okuma** (tur başına piksel kupa).

### Çalışma araçları
- **Reels tarzı soru pratiği:** Dikey kaydırmalı kartlarla 4 şıklı sorular. Her test havuzdan rastgele en fazla 50 soru çeker. Çözülen sorular sonraki testlerde gelmez, yarıda kalan test kaldığı yerden sürer. Her sorunun cevaptan sonra gösterilen bir açıklaması var.
- **Soru bankası:** Medeni Usul Hukuku konuları (İspat ve Deliller, Geçici Hukuki Korumalar, Kanun Yolları, Davaya Son Veren Taraf İşlemleri, Alternatif Uyuşmazlık Çözümleri, Hüküm ve Kesin Hüküm).
- **Yanlışları tekrar:** Yanlış yapılan sorular en çok yanlıştan başlayarak listelenir ve kayıt tutmayan ayrı bir turda yeniden çözülebilir. Ayrıca yanlış sorulara "vurulan" oyunlaştırılmış bir tekrar modu var.
- **Ders özetleri ve not modu:** 19 konuluk İcra Hukuku şema özeti. Özet, iPad ve Apple Pencil için Flutter dışında, saf DOM/SVG ile yazılmış bir katmanda açılır. Basınca duyarlı kalem, fosforlu kalem, silgi ve kement aracı; bölüm içi arama, A4 yazdırma/PDF ve JSON yedek desteği var. Notlar cihazda IndexedDB'de vektör olarak saklanır. Özet metni güncellendiğinde eski notlar yeni konumlarına taşınır.

> Not: Soru bölümü şu an bakım modundadır (`AppConfig.reelsMaintenance = true`), girişte "Bakımda" ekranı görünür. Kayıtlı ilerleme korunur.

### Sosyal ve diğer
- **İzleme listesi:** Paylaşımlı film/dizi listesi (TMDB araması, puan, yorum, bölüm takibi). Kartları sağa/sola kaydırarak ortak beğenileri bulan bir "ortak karar" modu var.
- **Profil:** Piksel avatar düzenleyici, istatistikler ve ayarlar (görüntü motoru seçimi, "güncellemeyi denetle" dahil).
- **Web Push bildirimleri:** Sıralamada geçilme, 1v1 daveti ve haftalık tur olayları için.

### Platform
- **Çevrimdışı PWA:** Service worker uygulama kabuğunu ve oyunları önbelleğe alır. Yeni sürüm geldiğinde sayfa kendiliğinden yenilenmez, kullanıcıya yenileme düğmesi gösterilir.
- **Uyarlanır düzen:** Sekme çubuğu telefonda ve dikey iPad'de altta, geniş yatay ekranda soldadır. iOS güvenli alanı web'de de hesaba katılır.
- **macOS ve iOS** native derlemeleri (Swift Package Manager ile).

---

## Teknoloji

| Katman | Kullanılan |
|---|---|
| Uygulama | Flutter (≥ 3.27), Dart (≥ 3.6), Material 3, `CustomPainter` tabanlı oyun çizimi |
| Paketler | `just_audio` (ses), `shared_preferences` (ilerleme kaydı), `flutter_localizations` (Türkçe) |
| Web katmanı | Vanilla JS köprüleri (`web/*.js`), özel service worker (`web/sw.js`), IndexedDB, Web Push |
| Backend | Cloudflare Workers, D1 (SQLite), Durable Objects (1v1 maç odaları, WebSocket), `web-push` |
| Paylaşılan kurallar | Dart → JS derlenen 1v1 kural motoru (`tools/build_battle.py`) |
| Dağıtım | GitHub Pages, `tools/build_web.py` |
| Araçlar | Python (sprite, logo ve ses efekti üretimi), Node `node:test`, Wrangler |

---

## Mimari

```
┌─────────────────────────── Flutter (lib/) ───────────────────────────┐
│  HomeShell (sekmeli iskelet)                                         │
│   ├─ home/      Ana sayfa                                            │
│   ├─ games/     Oyun ızgarası → game/ (Block Blast, Battle, Flappy,  │
│   │             Subway, Tower) + weekly/ (haftalık meydan okuma)     │
│   ├─ study/     reels/ (soru kartları), beat/, summaries/            │
│   ├─ films/     İzleme listesi + kaydırmalı ortak karar              │
│   └─ profile/   Avatar, istatistik, ayarlar                          │
│                                                                      │
│  core/services/  *_bridge.dart  ── koşullu import ──┐                │
│                  (_web.dart / _stub.dart)           │                │
└─────────────────────────────────────────────────────┼────────────────┘
                                                      ▼
        web/  social.js · battle.js · notes/ · audio.js · sw.js · update.js
                                                      │ HTTPS / WebSocket
                                                      ▼
        backend/  Cloudflare Worker ── D1 (skorlar, filmler, haftalık tur …)
                                  └── Durable Object BattleRoom (1v1 maç)
```

- **Özellik odaklı klasörleme:** Her ekran ailesi `lib/features/<özellik>/` altında. Ortak servisler, widget'lar ve modeller `lib/core/` altında.
- **Platform köprüleri:** Tarayıcıya özgü her yetenek (ses, bildirim, not katmanı, güncelleme, güvenli alan…) bir `*_bridge.dart` arayüzünün arkasındadır. Web'de `*_bridge_web.dart` JS'ye bağlanır, native'de `*_bridge_stub.dart` devre dışı kalır. Böylece aynı kod macOS/iOS'ta da derlenir.
- **Saf oyun motorları:** `block_blast_engine.dart`, `block_battle_core.dart` ve `tower_rules.dart` UI'dan bağımsız saf Dart kodudur ve doğrudan birim testlerle sınanır. 1v1 çekirdeği aynı zamanda Worker'a derlenir.
- **Önce önbellek:** Ana sayfa, izleme listesi ve meydan okuma ekranları cihazdaki son kopyayla hemen açılır, güncel veri arka planda gelir.
- **Flutter dışı not katmanı:** Kalem gecikmesi Flutter'ın kare zamanlamasına bağlı kalmasın diye özet ve not modu `web/notes/` altında DOM/SVG ile yazıldı.
- **Backend güvenliği:** Uç noktalar Bearer kimlik doğrulaması ve origin denetimiyle korunur. Şema `backend/migrations/` altında sıralı D1 migration'larıyla yönetilir; sırlar depoya girmez.

---

## Başlarken

### Gereksinimler
- Flutter SDK ≥ 3.27 (Dart ≥ 3.6). Proje Flutter 3.41.6 / Dart 3.11.4 ile doğrulanmıştır.
- Web yayın paketi için Python 3, web ve backend testleri için Node.js
- macOS/iOS derlemesi için Xcode

### Geliştirme

```sh
flutter pub get
flutter run -d chrome          # web
flutter run -d macos           # native macOS
```

### Web/PWA yayın paketi

Tek başına `flutter build web` yeterli değildir, çünkü çevrimdışı service worker'ı hazırlamaz. Yayın paketi için betik kullanılır:

```sh
python3 tools/build_web.py --base-href /hukuk-reels/
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Betik `flutter build web --release --wasm --no-web-resources-cdn` çalıştırır (ek argümanlar Flutter'a aktarılır), kullanılmayan motor dosyalarını ayıklar, içerikten sürüm kimliği üretir ve çevrimdışı service worker'ı yazar. Çıktı `build/web` klasörüne düşer.

1v1 kural motoru değiştiğinde Worker için yeniden derlenir:

```sh
python3 tools/build_battle.py
```

### Apple derlemeleri

```sh
flutter build macos --release
flutter build ios --simulator --no-codesign
```

İmzalı cihaz dağıtımı için kendi bundle identifier'ınızı ve Apple geliştirici takımınızı seçmeniz gerekir.

### Backend (isteğe bağlı)

Sosyal özellikler kendi Cloudflare hesabınızda bir Worker, D1 veritabanı ve Durable Object ister. Yapılandırma `backend/wrangler.jsonc`, şema `backend/schema.sql` ve `backend/migrations/` altındadır.

```sh
cd backend
npm install
npm run dev        # wrangler dev
npm run deploy     # wrangler deploy
```

---

## Testler

```sh
flutter analyze
flutter test                        # test/*.dart: oyun motorları, widget'lar, servisler
node test/web_runtime_test.cjs      # web köprüleri
node test/notes_ink_test.cjs        # not katmanı
node test/web_update_test.cjs       # güncelleme akışı

cd backend && npm install && npm test   # Worker, 1v1 oda/ağ, kural eşliği, güvenlik (node --test)
```

Backend testleri arasında istemci ile Worker'daki 1v1 kurallarının aynı sonucu ürettiğini denetleyen bir eşlik testi (`battle-parity.test.js`) bulunur.

---

## Proje yapısı

```
hukuk-reels/
├── lib/
│   ├── main.dart              # Uygulama girişi, tema
│   ├── app/                   # Tema
│   ├── core/
│   │   ├── config/            # AppConfig (uygulama ayarları, bakım anahtarı)
│   │   ├── data/              # Soru bankası
│   │   ├── models/            # Soru ve kategori modelleri
│   │   ├── services/          # İlerleme, ses, platform köprüleri (web/stub)
│   │   ├── utils/             # Yazı tipi ön yükleme
│   │   └── widgets/           # Piksel yazı/logo, Pressable, güvenli alan
│   └── features/              # shell, home, games, game, weekly, study,
│                              # reels, beat, summaries, films, profile …
├── web/                       # index.html, manifest, service worker, JS köprüleri
│   └── notes/                 # Özet + Apple Pencil not katmanı
├── backend/                   # Cloudflare Worker, D1 şeması/migration'lar, testler
├── test/                      # Flutter (.dart) ve web (.cjs) testleri
├── tools/                     # build_web.py, build_battle.py, sprite/logo/sfx üreticileri
├── assets/                    # Görseller, ses efektleri, yazı tipleri (Inter, Pixelify Sans)
├── docs/                      # Teknik inceleme notları
├── deploy/                    # GitHub Pages workflow şablonu
├── ios/  macos/               # Native Apple hedefleri
└── pubspec.yaml
```

---

Lisans: henüz belirtilmedi.

<sub>Geliştiren: [Melih Can Akgün](https://github.com/MelihCanAkgun)</sub>
