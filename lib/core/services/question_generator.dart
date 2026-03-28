import 'dart:math';

/// ─────────────────────────────────────────────────────────────
/// Kural Tabanlı Soru Üretme Motoru (Regex-Based NLP)
///
/// LLM veya API kullanmadan, hukuk metinlerindeki kalıpları
/// Regex ile tespit edip otomatik soru üreten Dart sınıfı.
///
/// Desteklenen kalıplar:
///   • Sayısal süreler   → "30 gün", "6 ay", "1 yıl"
///   • Madde referansları → "madde 141", "m.53"
///   • Ceza türleri       → "ağır hapis", "adli para cezası"
///   • Hukuki terimler    → "ipotek", "müdahil", "temyiz"
///   • Tanımlar           → "... denir/denir.", "... olarak tanımlanır"
/// ─────────────────────────────────────────────────────────────
class QuestionGenerator {
  static final _random = Random();

  // ───── REGEX KALIPLARI ─────

  /// Sayısal süreler: "30 gün", "6 ay", "2 yıl", "48 saat"
  static final _durationPattern = RegExp(
    r'(\d+)\s*(gün|ay|yıl|hafta|saat)',
    caseSensitive: false,
  );

  /// Madde referansları: "madde 141", "m.53", "md. 12/2"
  static final _articlePattern = RegExp(
    r'(?:madde|md\.?|m\.)\s*(\d+(?:[/\-]\d+)?)',
    caseSensitive: false,
  );

  /// Ceza türleri
  static final _penaltyPattern = RegExp(
    r'(ağır hapis|hapis cezası|adli para cezası|idari para cezası|'
    r'müebbet hapis|ağırlaştırılmış müebbet|disiplin cezası|'
    r'kınama cezası|aylıktan kesme|kademe ilerlemesinin durdurulması)',
    caseSensitive: false,
  );

  /// Hukuki anahtar terimler
  static final _legalTermPattern = RegExp(
    r'\b(ipotek|rehin|kefalet|temyiz|istinaf|itiraz|müdahil|'
    r'davacı|davalı|sanık|mağdur|tanık|bilirkişi|icra|iflas|'
    r'haciz|tedbir|tutuklama|gözaltı|beraat|mahkumiyet|'
    r'zamanaşımı|hak düşürücü süre|kesin hüküm|yargılamanın yenilenmesi|'
    r'tebligat|vekaletname|sulh|arabuluculuk|tahkim|feragat|kabul|'
    r'iddianame|mütalaa|esas|usul|tüzel kişi|gerçek kişi|ehliyet|'
    r'müteselsil|kusur|tazminat|nafaka|velayet|vesayet)\b',
    caseSensitive: false,
  );

  /// Tanım cümleleri: "... denir", "... olarak tanımlanır", "... demektir"
  static final _definitionPattern = RegExp(
    r'([^.;]+?)\s*(?:denir|denilir|olarak tanımlanır|demektir|ifade eder|'
    r'olarak adlandırılır|olarak kabul edilir|sayılır)[.\s]',
    caseSensitive: false,
  );

  /// Koşul cümleleri: "... halinde", "... durumunda", "... takdirde"
  static final _conditionPattern = RegExp(
    r'([^.;]{15,}?)\s*(halinde|durumunda|takdirde|hâlinde)\s*[,]?\s*([^.;]+)[.]',
    caseSensitive: false,
  );

  // ───── ANA ÜRETME METODU ─────

  /// Bir metin parçasından mümkün olan tüm soru tiplerini üretir.
  /// [text] → Kaynak metin (not içeriği)
  /// Dönen liste: [GeneratedQuestion] nesneleri
  List<GeneratedQuestion> generateFromText(String text) {
    final questions = <GeneratedQuestion>[];

    questions.addAll(_generateDurationQuestions(text));
    questions.addAll(_generateArticleQuestions(text));
    questions.addAll(_generatePenaltyQuestions(text));
    questions.addAll(_generateDefinitionQuestions(text));
    questions.addAll(_generateConditionQuestions(text));
    questions.addAll(_generateTermClozeQuestions(text));

    // Karıştır ve fazlasını kes
    questions.shuffle(_random);
    return questions;
  }

  // ───── SÜRE SORULARI ─────

  List<GeneratedQuestion> _generateDurationQuestions(String text) {
    final results = <GeneratedQuestion>[];
    final sentences = _splitSentences(text);

    for (final sentence in sentences) {
      for (final match in _durationPattern.allMatches(sentence)) {
        final fullMatch = match.group(0)!;          // "30 gün"
        final number = int.parse(match.group(1)!);  // 30
        final unit = match.group(2)!;                // "gün"

        // ── Boşluk Doldurma (Cloze) ──
        results.add(GeneratedQuestion(
          type: GenQuestionType.cloze,
          questionText: sentence.replaceFirst(fullMatch, '___'),
          correctAnswer: fullMatch,
          sourceSnippet: sentence,
        ));

        // ── 4 Şıklı ──
        final distractors = _generateNumberDistractors(number, unit);
        results.add(GeneratedQuestion(
          type: GenQuestionType.multipleChoice,
          questionText: sentence.replaceFirst(fullMatch, '___'),
          correctAnswer: fullMatch,
          options: _shuffleOptions(fullMatch, distractors),
          sourceSnippet: sentence,
        ));
      }
    }
    return results;
  }

  // ───── MADDE SORULARI ─────

  List<GeneratedQuestion> _generateArticleQuestions(String text) {
    final results = <GeneratedQuestion>[];
    final sentences = _splitSentences(text);

    for (final sentence in sentences) {
      for (final match in _articlePattern.allMatches(sentence)) {
        final fullMatch = match.group(0)!;
        final articleNum = match.group(1)!;

        results.add(GeneratedQuestion(
          type: GenQuestionType.cloze,
          questionText: sentence.replaceFirst(fullMatch, 'madde ___'),
          correctAnswer: articleNum,
          sourceSnippet: sentence,
        ));

        final numVal = int.tryParse(articleNum.split('/').first);
        if (numVal != null) {
          final distractors = _generateArticleDistractors(numVal);
          results.add(GeneratedQuestion(
            type: GenQuestionType.multipleChoice,
            questionText: sentence.replaceFirst(fullMatch, 'madde ___'),
            correctAnswer: 'madde $articleNum',
            options: _shuffleOptions(
              'madde $articleNum',
              distractors.map((d) => 'madde $d').toList(),
            ),
            sourceSnippet: sentence,
          ));
        }
      }
    }
    return results;
  }

  // ───── CEZA TİPİ SORULARI ─────

  List<GeneratedQuestion> _generatePenaltyQuestions(String text) {
    final results = <GeneratedQuestion>[];
    final sentences = _splitSentences(text);
    final allPenalties = [
      'ağır hapis', 'hapis cezası', 'adli para cezası',
      'idari para cezası', 'müebbet hapis',
      'ağırlaştırılmış müebbet', 'disiplin cezası',
    ];

    for (final sentence in sentences) {
      for (final match in _penaltyPattern.allMatches(sentence)) {
        final penalty = match.group(0)!.toLowerCase();

        final distractors = allPenalties
            .where((p) => p != penalty)
            .toList()
          ..shuffle(_random);

        results.add(GeneratedQuestion(
          type: GenQuestionType.multipleChoice,
          questionText: sentence.replaceFirst(
            RegExp(RegExp.escape(match.group(0)!), caseSensitive: false),
            '___',
          ),
          correctAnswer: match.group(0)!,
          options: _shuffleOptions(
            match.group(0)!,
            distractors.take(3).toList(),
          ),
          sourceSnippet: sentence,
        ));
      }
    }
    return results;
  }

  // ───── TANIM SORULARI ─────

  List<GeneratedQuestion> _generateDefinitionQuestions(String text) {
    final results = <GeneratedQuestion>[];

    for (final match in _definitionPattern.allMatches(text)) {
      final definition = match.group(1)!.trim();
      if (definition.length < 10) continue; // Çok kısa tanımları atla

      // Tanım içindeki anahtar terimi bul
      final termMatch = _legalTermPattern.firstMatch(definition);
      if (termMatch != null) {
        final term = termMatch.group(0)!;
        results.add(GeneratedQuestion(
          type: GenQuestionType.cloze,
          questionText: '${definition.replaceFirst(term, '___')} denir.',
          correctAnswer: term,
          sourceSnippet: '${definition.trim()} denir.',
        ));
      }
    }
    return results;
  }

  // ───── KOŞUL CÜMLESİ SORULARI ─────

  List<GeneratedQuestion> _generateConditionQuestions(String text) {
    final results = <GeneratedQuestion>[];

    for (final match in _conditionPattern.allMatches(text)) {
      final condition = match.group(1)!.trim();
      final connector = match.group(2)!;
      final consequence = match.group(3)!.trim();

      if (condition.length < 15 || consequence.length < 10) continue;

      // Koşul boşluk bırakılır, sonuç sorulur
      results.add(GeneratedQuestion(
        type: GenQuestionType.cloze,
        questionText: '$condition $connector, ___.',
        correctAnswer: consequence,
        sourceSnippet: '$condition $connector, $consequence.',
      ));
    }
    return results;
  }

  // ───── GENEL TERİM CLOZE ─────

  List<GeneratedQuestion> _generateTermClozeQuestions(String text) {
    final results = <GeneratedQuestion>[];
    final sentences = _splitSentences(text);

    // Her cümlede bulunan hukuki terimleri boşluğa çevir
    for (final sentence in sentences) {
      final termMatches = _legalTermPattern.allMatches(sentence).toList();
      if (termMatches.isEmpty) continue;

      // Cümle başına en fazla 1 soru üret (ilk eşleşme)
      final match = termMatches.first;
      final term = match.group(0)!;

      // Aynı kategoriden çeldiriciler
      final allTerms = _getLegalTermsPool();
      final distractors = allTerms
          .where((t) => t.toLowerCase() != term.toLowerCase())
          .toList()
        ..shuffle(_random);

      if (distractors.length >= 3) {
        results.add(GeneratedQuestion(
          type: GenQuestionType.multipleChoice,
          questionText: sentence.replaceFirst(
            RegExp(r'\b' + RegExp.escape(term) + r'\b', caseSensitive: false),
            '___',
          ),
          correctAnswer: term,
          options: _shuffleOptions(term, distractors.take(3).toList()),
          sourceSnippet: sentence,
        ));
      }
    }
    return results;
  }

  // ───── YARDIMCI METOTLAR ─────

  /// Metni cümlelere ayırır
  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?]\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15)
        .toList();
  }

  /// Sayısal çeldirici üretir: orijinal sayıdan sapma
  List<String> _generateNumberDistractors(int original, String unit) {
    final distractors = <String>{};
    final variations = [
      original ~/ 2,
      original * 2,
      original + _randomOffset(original),
      original - _randomOffset(original),
    ]..removeWhere((v) => v <= 0 || v == original);

    for (final v in variations) {
      distractors.add('$v $unit');
      if (distractors.length >= 3) break;
    }

    // Yeterli çeldirici yoksa ek üret
    var counter = 1;
    while (distractors.length < 3) {
      final v = original + counter * 5;
      if (v != original) distractors.add('$v $unit');
      counter++;
    }

    return distractors.take(3).toList();
  }

  /// Madde numarası çeldiricileri
  List<String> _generateArticleDistractors(int original) {
    final distractors = <int>{};
    for (var i = 1; distractors.length < 3; i++) {
      final candidate = original + (_random.nextBool() ? i : -i);
      if (candidate > 0 && candidate != original) {
        distractors.add(candidate);
      }
    }
    return distractors.map((d) => d.toString()).toList();
  }

  int _randomOffset(int base) {
    if (base <= 5) return _random.nextInt(3) + 1;
    if (base <= 30) return _random.nextInt(10) + 1;
    return _random.nextInt(base ~/ 3) + 1;
  }

  /// Doğru cevap + çeldiricileri karıştırır
  List<String> _shuffleOptions(String correct, List<String> distractors) {
    final options = [correct, ...distractors.take(3)];
    options.shuffle(_random);
    return options;
  }

  /// Tüm hukuki terim havuzu
  List<String> _getLegalTermsPool() {
    return [
      'ipotek', 'rehin', 'kefalet', 'temyiz', 'istinaf', 'itiraz',
      'müdahil', 'davacı', 'davalı', 'sanık', 'mağdur', 'tanık',
      'bilirkişi', 'icra', 'iflas', 'haciz', 'tedbir', 'tutuklama',
      'gözaltı', 'beraat', 'mahkumiyet', 'zamanaşımı', 'hak düşürücü süre',
      'kesin hüküm', 'tebligat', 'vekaletname', 'sulh', 'arabuluculuk',
      'tahkim', 'feragat', 'kabul', 'iddianame', 'mütalaa', 'tazminat',
      'nafaka', 'velayet', 'vesayet', 'ehliyet', 'kusur',
    ];
  }
}

// ───── ÜRETİLEN SORU MODELİ ─────

enum GenQuestionType { cloze, multipleChoice }

class GeneratedQuestion {
  final GenQuestionType type;
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final String sourceSnippet;

  const GeneratedQuestion({
    required this.type,
    required this.questionText,
    required this.correctAnswer,
    this.options = const [],
    this.sourceSnippet = '',
  });

  @override
  String toString() =>
      '[${type.name}] Q: $questionText | A: $correctAnswer'
      '${options.isNotEmpty ? ' | Opts: $options' : ''}';
}
