import 'dart:convert';
import 'dart:js_interop';

import 'summary_notes.dart';

@JS('hukukNotesOpen')
external JSPromise<JSString> _open(JSString id);

@JS('hukukNotesInfo')
external JSPromise<JSString> _info(JSString id);

bool get notesSupported => true;

/// Özeti Flutter'ın üstündeki not katmanında açar (web/notes/notes.js).
/// Kullanıcı kapatınca 'closed' döner; hata olursa `error:<mesaj>`.
Future<String> openSummary(String id) async {
  try {
    return (await _open(id.toJS).toDart).toDart;
  } catch (_) {
    return 'error:Özet açılamadı. Sayfayı yenileyip tekrar dene.';
  }
}

/// Bu özete cihazda kaydedilmiş notlar: sayı ve son düzenleme zamanı.
Future<SummaryNotes> summaryNotes(String id) async {
  try {
    final info = jsonDecode((await _info(id.toJS).toDart).toDart);
    final edited = (info['edited'] as num?)?.toInt() ?? 0;
    return SummaryNotes(
      count: (info['strokes'] as num?)?.toInt() ?? 0,
      edited: edited > 0 ? DateTime.fromMillisecondsSinceEpoch(edited) : null,
    );
  } catch (_) {
    return const SummaryNotes();
  }
}
