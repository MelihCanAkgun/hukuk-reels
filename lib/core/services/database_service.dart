import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/question.dart';
import '../models/user_stats.dart';

/// ─────────────────────────────────────────────────────
/// Hive Veritabanı Servisi
///
/// Web (IndexedDB) ve mobilde (dosya sistemi) çalışır.
/// Tüm veri işlemlerini merkezi bir yerden yönetir.
/// ─────────────────────────────────────────────────────
class DatabaseService {
  static const _notesBox = 'notes';
  static const _questionsBox = 'questions';
  static const _statsBox = 'stats';
  static const _prefsBox = 'prefs';

  static DatabaseService? _instance;
  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  late Box<Note> _notes;
  late Box<Question> _questions;
  late Box<UserStats> _stats;
  late Box _prefs;

  bool _initialized = false;

  /// Uygulama başlangıcında çağrılır
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // TypeAdapter'ları kaydet
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(NoteAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(QuestionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserStatsAdapter());

    // Box'ları aç
    _notes = await Hive.openBox<Note>(_notesBox);
    _questions = await Hive.openBox<Question>(_questionsBox);
    _stats = await Hive.openBox<UserStats>(_statsBox);
    _prefs = await Hive.openBox(_prefsBox);

    // İlk kullanımda boş stats oluştur
    if (_stats.isEmpty) {
      await _stats.put('main', UserStats());
    }

    _initialized = true;
  }

  // ───── NOT İŞLEMLERİ ─────

  List<Note> getAllNotes() => _notes.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Note? getNote(String id) => _notes.get(id);

  Future<void> saveNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _notes.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    // İlişkili soruları da sil
    final relatedQuestions = _questions.values
        .where((q) => q.noteId == id)
        .toList();
    for (final q in relatedQuestions) {
      await _questions.delete(q.id);
    }
    await _notes.delete(id);
  }

  // ───── SORU İŞLEMLERİ ─────

  List<Question> getAllQuestions() => _questions.values.toList();

  List<Question> getQuestionsForNote(String noteId) =>
      _questions.values.where((q) => q.noteId == noteId).toList();

  /// Bugün tekrar edilmesi gereken sorular (Spaced Repetition kuyruğu)
  List<Question> getDueQuestions() {
    final now = DateTime.now();
    return _questions.values.where((q) {
      if (q.nextReviewDate == null) return true; // Yeni sorular hep gösterilir
      return q.nextReviewDate!.isBefore(now);
    }).toList()
      ..shuffle();
  }

  Future<void> saveQuestion(Question question) async {
    await _questions.put(question.id, question);
  }

  Future<void> saveQuestions(List<Question> questions) async {
    final map = {for (final q in questions) q.id: q};
    await _questions.putAll(map);
  }

  Future<void> deleteQuestion(String id) async {
    await _questions.delete(id);
  }

  // ───── SPACED REPETITION GÜNCELLEME ─────

  Future<void> markCorrect(String questionId) async {
    final q = _questions.get(questionId);
    if (q == null) return;

    q.correctCount++;
    q.repetitionLevel = (q.repetitionLevel + 1).clamp(0, 5);
    q.nextReviewDate = _nextReviewDate(q.repetitionLevel);
    await q.save();

    await _updateStats(correct: true);
  }

  Future<void> markWrong(String questionId) async {
    final q = _questions.get(questionId);
    if (q == null) return;

    q.wrongCount++;
    q.repetitionLevel = 0; // Sıfırdan başla
    q.nextReviewDate = _nextReviewDate(0);
    await q.save();

    await _updateStats(correct: false);
  }

  DateTime _nextReviewDate(int level) {
    final intervals = [
      const Duration(hours: 4),
      const Duration(days: 1),
      const Duration(days: 3),
      const Duration(days: 7),
      const Duration(days: 14),
      const Duration(days: 30),
    ];
    final interval = level < intervals.length
        ? intervals[level]
        : const Duration(days: 30);
    return DateTime.now().add(interval);
  }

  // ───── İSTATİSTİK İŞLEMLERİ ─────

  UserStats getStats() => _stats.get('main') ?? UserStats();

  Future<void> _updateStats({required bool correct}) async {
    final stats = getStats();
    stats.totalAnswered++;
    if (correct) {
      stats.totalCorrect++;
      stats.currentStreak++;
      if (stats.currentStreak > stats.longestStreak) {
        stats.longestStreak = stats.currentStreak;
      }
    } else {
      stats.totalWrong++;
      stats.currentStreak = 0;
    }

    // Günlük geçmiş
    final today = _dateKey(DateTime.now());
    stats.dailyHistory[today] = (stats.dailyHistory[today] ?? 0) + 1;
    stats.lastStudyDate = DateTime.now();

    await _stats.put('main', stats);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ───── PREFERENCES ─────

  /// iOS "Add to Home Screen" banner'ı gösterildi mi?
  bool get installBannerDismissed =>
      _prefs.get('installBannerDismissed', defaultValue: false) as bool;

  Future<void> dismissInstallBanner() async {
    await _prefs.put('installBannerDismissed', true);
  }

  /// Temizlik
  Future<void> clearAll() async {
    await _notes.clear();
    await _questions.clear();
    await _stats.clear();
    await _stats.put('main', UserStats());
  }
}
