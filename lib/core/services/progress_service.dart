import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/questions_data.dart';
import '../models/quiz_question.dart';

/// Bir sorunun kümülatif doğru/yanlış sayıları (profil için).
class QuestionStat {
  final int correct;
  final int wrong;
  const QuestionStat({this.correct = 0, this.wrong = 0});
  int get total => correct + wrong;
}

/// Diske kaydedilmiş (veya yeni başlatılmış) bir test oturumu.
class SessionData {
  /// Şık sırası uygulanmış sorular (gösterim sırasıyla).
  final List<QuizQuestion> questions;

  /// Soru index'i -> seçilen şık index'i (yalnızca cevaplananlar).
  final Map<int, int> answers;

  /// Kalınan sayfa (questions.length == özet sayfası olabilir).
  final int page;

  const SessionData(this.questions, this.answers, this.page);
}

/// İlerleme kalıcılığı: istatistikler, çözülmüş soru havuzu ve aktif test
/// oturumu. Web'de localStorage, mobilde yerel depolama kullanır — uygulama
/// kapanıp açılınca her şey kaldığı yerden devam eder.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  /// Bir testte gösterilecek soru sayısı (havuzda daha azı kaldıysa kalan).
  static const int testSize = 50;

  static const _kStats = 'stats_v1';
  static const _kSolved = 'solved_v1';
  static const _kSession = 'session_v1';
  static const _kFlappyHigh = 'flappy_high_v1';
  static const _kTowerHigh = 'tower_high_v1';
  // v2: Block Blast sezon 2 — rekor ve yarım kalan oyun sıfırdan başlar
  // (sunucuda BLOCK_SEASON, web/social.js'te blockSeason ile aynı anda).
  static const _kBlockHigh = 'block_high_v2';
  static const _kBlockGame = 'block_game_v2';
  String? _blockMemory;
  bool _blockLoaded = false;
  Future<void> _blockWrites = Future.value();
  int _blockHighMemory = 0;
  static const _kSubwayHigh = 'subway_high_v1';
  // v2: bildirim öncesi sürpriz herkeste yeniden açılsın diye yenilendi.
  static const _kNick = 'profile_nick_v1';
  static const _kAvatar = 'profile_avatar_v1';
  static const _kAvatarVer = 'profile_avatar_ver_v1';
  static const _kAvatarPending = 'profile_avatar_pending_v1';
  static const kFlowerSurpriseSeenKey = 'flower_surprise_seen_v2';
  bool _flowerSeenMemory = false;

  SharedPreferences? _prefs;

  // Çözümlenmiş istatistik / çözülen soru önbelleği: her okumada JSON
  // çözmemek için. Yazan her yöntem önbelleği de günceller.
  Map<String, QuestionStat>? _statsCache;
  Set<String>? _solvedCache;

  /// Depolama hazır değilse (init başarısız/eklenti yok) uygulama yine de
  /// çalışır; ilerleme yalnızca o oturum için tutulur.
  bool get isReady => _prefs != null;

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      // Eklenti cevap vermezse uygulamayı kilitleme (web'de eksik kayıt vb.).
      _prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      _prefs = null;
    }
  }

  // ───────────────────────── İstatistikler ─────────────────────────

  /// Değiştirilebilir kopya döner (önbelleği korumak için).
  Map<String, QuestionStat> get stats => Map.of(_statsCache ??= _readStats());

  Map<String, QuestionStat> _readStats() {
    final raw = _prefs?.getString(_kStats);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(
            k,
            QuestionStat(
              correct: (v['c'] as num?)?.toInt() ?? 0,
              wrong: (v['w'] as num?)?.toInt() ?? 0,
            ),
          ));
    } catch (_) {
      return {};
    }
  }

  Set<String> get _solved =>
      _solvedCache ??= (_prefs?.getStringList(_kSolved) ?? const []).toSet();

  /// Değiştirilebilir kopya döner (önbelleği korumak için).
  Set<String> get solvedIds => Set.of(_solved);

  int get poolSize => kQuestions.length;

  /// Havuzda henüz hiç cevaplanmamış soru sayısı.
  int get unsolvedCount {
    final s = _solved;
    return kQuestions.where((q) => !s.contains(q.id)).length;
  }

  /// Bir cevabı kalıcı olarak işler: istatistik + çözülmüş işareti.
  Future<void> recordAnswer(String id, bool correct) async {
    final p = _prefs;
    if (p == null) return;
    final s = _statsCache ??= _readStats();
    final old = s[id] ?? const QuestionStat();
    s[id] = QuestionStat(
      correct: old.correct + (correct ? 1 : 0),
      wrong: old.wrong + (correct ? 0 : 1),
    );
    await p.setString(
      _kStats,
      jsonEncode(s.map((k, v) => MapEntry(k, {'c': v.correct, 'w': v.wrong}))),
    );
    final solved = _solved..add(id);
    await p.setStringList(_kSolved, solved.toList());
  }

  // ───────────────────────── Flappy Cat ─────────────────────────

  int get flappyHigh => _prefs?.getInt(_kFlappyHigh) ?? 0;

  /// Yeni skor rekoru ise kaydeder ve rekor mu olduğunu döndürür.
  Future<bool> submitFlappyScore(int score) async {
    if (score <= flappyHigh) return false;
    await _prefs?.setInt(_kFlappyHigh, score);
    return true;
  }

  // ───────────────────────── Adliye Kulesi ─────────────────────────

  int get towerHigh => _prefs?.getInt(_kTowerHigh) ?? 0;

  Future<bool> submitTowerScore(int score) async {
    if (score <= towerHigh) return false;
    await _prefs?.setInt(_kTowerHigh, score);
    return true;
  }

  int get blockHigh => max(_blockHighMemory, _prefs?.getInt(_kBlockHigh) ?? 0);

  Future<bool> submitBlockScore(int score) async {
    if (score <= blockHigh) return false;
    _blockHighMemory = score;
    try {
      await _prefs?.setInt(_kBlockHigh, score);
    } catch (_) {}
    return true;
  }

  Map<String, dynamic>? loadBlockGame() {
    try {
      if (!_blockLoaded) {
        _blockMemory = _prefs?.getString(_kBlockGame);
        _blockLoaded = true;
      }
      final raw = _blockMemory;
      return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBlockGame(Map<String, dynamic> game) {
    final raw = jsonEncode(game);
    _blockLoaded = true;
    _blockMemory = raw;
    // Serialize snapshots so an older asynchronous write cannot win.
    return _blockWrites = _blockWrites.then((_) async {
      try {
        await _prefs?.setString(_kBlockGame, raw);
      } catch (_) {}
    });
  }

  Future<void> clearBlockGame() {
    _blockLoaded = true;
    _blockMemory = null;
    return _blockWrites = _blockWrites.then((_) async {
      try {
        await _prefs?.remove(_kBlockGame);
      } catch (_) {}
    });
  }

  int get subwayHigh => _prefs?.getInt(_kSubwayHigh) ?? 0;

  Future<bool> submitSubwayScore(int score) async {
    if (score <= subwayHigh) return false;
    await _prefs?.setInt(_kSubwayHigh, score);
    return true;
  }

  // ───────────────────────── Profil ─────────────────────────
  // Takma ad sıralamadaki oyuncu adının çevrimdışı kopyasıdır; fotoğraf
  // yalnızca bu cihazda (localStorage) tutulur ve "Her şeyi sıfırla" ile
  // silinmez.

  /// Profil fotoğrafı/adı değişince artar (menüdeki küçük avatar dinler).
  final ValueNotifier<int> profileChanges = ValueNotifier(0);
  Uint8List? _avatar;
  bool _avatarLoaded = false;

  String? get nick {
    final v = _prefs?.getString(_kNick)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setNick(String? name) async {
    final v = name?.trim() ?? '';
    if (v == (nick ?? '')) return;
    try {
      if (v.isEmpty) {
        await _prefs?.remove(_kNick);
      } else {
        await _prefs?.setString(_kNick, v);
      }
    } catch (_) {}
    profileChanges.value++;
  }

  Uint8List? get avatar {
    if (!_avatarLoaded) {
      _avatarLoaded = true;
      try {
        final raw = _prefs?.getString(_kAvatar);
        _avatar = raw == null ? null : base64Decode(raw);
      } catch (_) {
        _avatar = null;
      }
    }
    return _avatar;
  }

  /// Sunucudaki kendi fotoğrafımızın sürümü (eşitlenmişse).
  String? get avatarVersion => _prefs?.getString(_kAvatarVer);

  /// Sunucuya gönderilmeyi bekleyen işlem: 'up' (yükle), 'del' (sil),
  /// 'rejected' (sunucu kabul etmedi; yeni seçime kadar tekrar denenmez)
  /// veya null. Eşitlenmemiş eski fotoğraf da 'up' sayılır.
  String? get avatarPending {
    final v = _prefs?.getString(_kAvatarPending);
    if (v != null) return v;
    return (avatar != null && avatarVersion == null) ? 'up' : null;
  }

  /// JPEG data URL (yükleme için) ya da null.
  String? get avatarDataUrl {
    final raw = _prefs?.getString(_kAvatar);
    return raw == null ? null : 'data:image/jpeg;base64,$raw';
  }

  Future<void> markAvatarSynced(String? version) async {
    try {
      if (version == null) {
        await _prefs?.remove(_kAvatarVer);
      } else {
        await _prefs?.setString(_kAvatarVer, version);
      }
      await _prefs?.remove(_kAvatarPending);
    } catch (_) {}
  }

  Future<void> markAvatarRejected() async {
    try {
      await _prefs?.setString(_kAvatarPending, 'rejected');
    } catch (_) {}
  }

  /// Başka cihazda seçilmiş kendi fotoğrafımızı sunucudan alır.
  Future<bool> setAvatarFromServer(String base64Jpeg, String version) async {
    final ok = await _storeAvatar('data:image/jpeg;base64,$base64Jpeg');
    if (ok) await markAvatarSynced(version);
    return ok;
  }

  /// Kendi fotoğrafımız başka cihazdan kaldırıldı.
  Future<void> setAvatarFromServerRemoved() async {
    await _storeAvatar(null);
    await markAvatarSynced(null);
  }

  /// Kullanıcı seçimi: fotoğrafı kaydeder ve sunucuya gönderilmek üzere
  /// işaretler. [dataUrl] bir `data:image/...;base64,` adresi olmalı; null
  /// kaldırır. Geçersiz veride false döner ve mevcut fotoğraf korunur.
  Future<bool> setAvatarDataUrl(String? dataUrl) async {
    final ok = await _storeAvatar(dataUrl);
    if (ok) {
      try {
        await _prefs?.setString(_kAvatarPending, dataUrl == null ? 'del' : 'up');
      } catch (_) {}
    }
    return ok;
  }

  Future<bool> _storeAvatar(String? dataUrl) async {
    Uint8List? bytes;
    String? b64;
    if (dataUrl != null) {
      final m = RegExp(r'^data:image/(jpeg|png|webp);base64,(.+)$')
          .firstMatch(dataUrl);
      if (m == null) return false;
      b64 = m.group(2)!;
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        return false;
      }
      if (bytes.isEmpty || bytes.length > 1024 * 1024) return false;
    }
    try {
      if (b64 == null) {
        await _prefs?.remove(_kAvatar);
      } else {
        await _prefs?.setString(_kAvatar, b64);
      }
    } catch (_) {
      return false;
    }
    _avatar = bytes;
    _avatarLoaded = true;
    profileChanges.value++;
    return true;
  }

  // ───────────────────────── Çiçek sürprizi ─────────────────────────

  /// Güncellemeyle gelen çiçek sürprizi açılışta bir kez gösterilir.
  bool get flowerSurpriseSeen =>
      _flowerSeenMemory || (_prefs?.getBool(kFlowerSurpriseSeenKey) ?? false);

  /// [seen] false ise sürpriz bir sonraki açılışta yeniden gösterilir
  /// (🌷 düğmesine uzun basarak test için).
  Future<void> setFlowerSurpriseSeen(bool seen) async {
    _flowerSeenMemory = seen;
    try {
      if (seen) {
        await _prefs?.setBool(kFlowerSurpriseSeenKey, true);
      } else {
        await _prefs?.remove(kFlowerSurpriseSeenKey);
      }
    } catch (_) {}
  }

  // ───────────────────────── Oturum ─────────────────────────

  /// Kayıtlı oturumu yükler. Soru havuzu değiştiyse (soru silindi/şıkları
  /// değişti) geçersiz girdileri ayıklar; hiç soru kalmazsa null döner.
  SessionData? loadSession() {
    final raw = _prefs?.getString(_kSession);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final byId = {for (final q in kQuestions) q.id: q};
      final ansById = (json['ans'] as Map<String, dynamic>?) ?? {};
      final questions = <QuizQuestion>[];
      final answers = <int, int>{};
      for (final e in (json['deck'] as List)) {
        final id = e['id'] as String;
        final q = byId[id];
        if (q == null) continue;
        final ord = (e['ord'] as List).cast<int>();
        if (ord.length != q.options.length) continue;
        final idx = questions.length;
        questions.add(q.withOptionOrder(ord));
        final sel = ansById[id];
        if (sel is int && sel >= 0 && sel < ord.length) answers[idx] = sel;
      }
      if (questions.isEmpty) return null;
      final page = (json['page'] as num?)?.toInt() ?? 0;
      return SessionData(questions, answers, page);
    } catch (_) {
      return null;
    }
  }

  /// Çözülmemiş sorulardan rastgele [testSize] soruluk yeni test başlatır
  /// ve diske yazar. Havuzda çözülmemiş soru kalmadıysa null döner.
  Future<SessionData?> startNewTest(Random rng) async {
    final s = _solved;
    final unsolved = kQuestions.where((q) => !s.contains(q.id)).toList()
      ..shuffle(rng);
    if (unsolved.isEmpty) return null;
    final pick = unsolved.take(testSize).toList();

    final deckJson = <Map<String, dynamic>>[];
    final questions = <QuizQuestion>[];
    for (final q in pick) {
      final ord = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
      deckJson.add({'id': q.id, 'ord': ord});
      questions.add(q.withOptionOrder(ord));
    }
    await _prefs?.setString(
      _kSession,
      jsonEncode({'deck': deckJson, 'ans': <String, int>{}, 'page': 0}),
    );
    return SessionData(questions, const {}, 0);
  }

  Future<void> saveAnswer(String questionId, int selected) async {
    final p = _prefs;
    final raw = p?.getString(_kSession);
    if (p == null || raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    (json['ans'] as Map<String, dynamic>)[questionId] = selected;
    await p.setString(_kSession, jsonEncode(json));
  }

  Future<void> savePage(int page) async {
    final p = _prefs;
    final raw = p?.getString(_kSession);
    if (p == null || raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    json['page'] = page;
    await p.setString(_kSession, jsonEncode(json));
  }

  Future<void> clearSession() async => _prefs?.remove(_kSession);

  /// Çözülmüşlük işaretlerini temizler (istatistikler kalır).
  Future<void> resetPool() async {
    _solvedCache = <String>{};
    await _prefs?.remove(_kSolved);
  }

  /// Her şeyi sıfırlar: istatistik + havuz + oturum.
  Future<void> resetAll() async {
    _blockHighMemory = 0;
    _statsCache = <String, QuestionStat>{};
    _solvedCache = <String>{};
    await clearBlockGame();
    await _prefs?.remove(_kStats);
    await _prefs?.remove(_kSolved);
    await _prefs?.remove(_kSession);
    await _prefs?.remove(_kFlappyHigh);
    await _prefs?.remove(_kBlockHigh);
    await _prefs?.remove(_kSubwayHigh);
    await _prefs?.remove(_kTowerHigh);
  }
}
