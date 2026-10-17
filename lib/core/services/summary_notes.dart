/// Bir özete cihazda kaydedilmiş notların özeti.
class SummaryNotes {
  const SummaryNotes({this.count = 0, this.edited});

  /// Kaydedilmiş not (çizgi) sayısı.
  final int count;

  /// Notların kullanıcı tarafından son değiştirildiği an; bilinmiyorsa null.
  final DateTime? edited;
}
