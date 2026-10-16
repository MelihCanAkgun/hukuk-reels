/// Kavuşma sayacı metinleri: Türkçe ek uyumu, kalan süre ve tarih.
library;

const _vowels = 'aeıioöuü';

String _lower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Sondaki emoji, boşluk ve noktalama atılır ("mqcan 😎" → "mqcan").
String _base(String word) {
  final t =
      word.trim().replaceAll(RegExp(r'[^\p{L}\p{N}]+$', unicode: true), '');
  return t.isEmpty ? word.trim() : t;
}

String? _lastVowel(String word) {
  final w = _lower(word);
  for (var i = w.length - 1; i >= 0; i--) {
    if (_vowels.contains(w[i])) return w[i];
  }
  return null;
}

bool _endsWithVowel(String word) {
  final w = _lower(word);
  return w.isNotEmpty && _vowels.contains(w[w.length - 1]);
}

/// İlgi hâli: "ari" → "ari'nin", "mqcan 😎" → "mqcan'ın", "Doğu" → "Doğu'nun".
String genitive(String name) {
  final b = _base(name);
  final suffix = switch (_lastVowel(b) ?? 'e') {
    'a' || 'ı' => 'ın',
    'o' || 'u' => 'un',
    'ö' || 'ü' => 'ün',
    _ => 'in',
  };
  return "$b'${_endsWithVowel(b) ? 'n' : ''}$suffix";
}

/// Yönelme hâli: "İstanbul" → "İstanbul'a", "İzmir" → "İzmir'e",
/// "Ankara" → "Ankara'ya", "Berlin" → "Berlin'e".
String dative(String place) {
  final b = _base(place);
  final back = const ['a', 'ı', 'o', 'u'].contains(_lastVowel(b) ?? 'e');
  return "$b'${_endsWithVowel(b) ? 'y' : ''}${back ? 'a' : 'e'}";
}

/// "ari'nin İstanbul'a gelmesine"
String tripSentence(String name, String destination) =>
    '${genitive(name)} ${dative(destination)} gelmesine';

/// Gün ve saat (saniye yok). Süre dolduysa null.
String? remainingText(Duration d) {
  if (d <= Duration.zero) return null;
  final days = d.inDays, hours = d.inHours % 24;
  if (days > 0 && hours > 0) return '$days gün $hours saat';
  if (days > 0) return '$days gün';
  if (hours > 0) return '$hours saat';
  return '1 saatten az';
}

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];
const _days = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// "21 Kasım Cuma · 14:30" (cihazın saat diliminde).
String arrivalText(DateTime t) =>
    '${t.day} ${_months[t.month - 1]} ${_days[t.weekday - 1]} · '
    '${_two(t.hour)}:${_two(t.minute)}';

/// "21 Kasım 2026"
String dateText(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';
