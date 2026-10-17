import 'summary_notes.dart';

/// Yerel derlemede not modu yok; özetler web uygulamasında açılır.
bool get notesSupported => false;

/// Özeti not modunda açar; kapanınca 'closed', hata olursa `error:<mesaj>`.
Future<String> openSummary(String id) async =>
    'error:Özetler ve not alma yalnız web uygulamasında çalışır.';

/// Kaydedilmiş notlar (yoksa boş).
Future<SummaryNotes> summaryNotes(String id) async => const SummaryNotes();
