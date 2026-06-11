import 'dart:convert';
import 'dart:math';
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

  SharedPreferences? _prefs;

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

  Map<String, QuestionStat> get stats {
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

  Set<String> get solvedIds =>
      (_prefs?.getStringList(_kSolved) ?? const []).toSet();

  int get poolSize => kQuestions.length;

  /// Havuzda henüz hiç cevaplanmamış soru sayısı.
  int get unsolvedCount {
    final s = solvedIds;
    return kQuestions.where((q) => !s.contains(q.id)).length;
  }

  /// Bir cevabı kalıcı olarak işler: istatistik + çözülmüş işareti.
  Future<void> recordAnswer(String id, bool correct) async {
    final p = _prefs;
    if (p == null) return;
    final s = stats;
    final old = s[id] ?? const QuestionStat();
    s[id] = QuestionStat(
      correct: old.correct + (correct ? 1 : 0),
      wrong: old.wrong + (correct ? 0 : 1),
    );
    await p.setString(
      _kStats,
      jsonEncode(s.map((k, v) => MapEntry(k, {'c': v.correct, 'w': v.wrong}))),
    );
    final solved = solvedIds..add(id);
    await p.setStringList(_kSolved, solved.toList());
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
    final s = solvedIds;
    final unsolved = kQuestions.where((q) => !s.contains(q.id)).toList()
      ..shuffle(rng);
    if (unsolved.isEmpty) return null;
    final pick = unsolved.take(testSize).toList();

    final deckJson = <Map<String, dynamic>>[];
    final questions = <QuizQuestion>[];
    for (final q in pick) {
      final ord = List<int>.generate(q.options.length, (i) => i)
        ..shuffle(rng);
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
  Future<void> resetPool() async => _prefs?.remove(_kSolved);

  /// Her şeyi sıfırlar: istatistik + havuz + oturum.
  Future<void> resetAll() async {
    await _prefs?.remove(_kStats);
    await _prefs?.remove(_kSolved);
    await _prefs?.remove(_kSession);
  }
}
