import 'dart:math' as math;

/// "Adliye Kulesi" kuralları: çizimden ve durumdan bağımsız saf hesaplar.
/// Ekran ([TowerScreen]) bunları kullanır; testler doğrudan çağırır.

/// Kayan katın hızı (dünya birimi/sn); skor arttıkça 235'e kadar hızlanır.
double towerSpeed(int score) => math.min(235, 80 + score * 2.4);

/// Mükemmel sayılan merkez sapması; skor arttıkça 1.7'ye kadar daralır.
double towerTolerance(int score) => math.max(1.7, 3.4 - score * 0.025);

enum TowerDropKind { miss, perfect, cut }

/// Bırakılan katın sonucu.
class TowerDrop {
  final TowerDropKind kind;

  /// Yerleşen katın sınırları (ıska ise anlamsız).
  final double x0, x1;

  /// Kesilip düşen parçanın sınırları; [hasChunk] yanlışsa boştur.
  final double chunk0, chunk1;

  /// Parça sağ tarafta mı kesildi (düşüş yönü).
  final bool rightSide;

  const TowerDrop._(this.kind, this.x0, this.x1,
      {this.chunk0 = 0, this.chunk1 = 0, this.rightSide = false});

  double get width => x1 - x0;

  /// Çok ince kırpıntılar (≤ 0.3 birim) parça olarak düşürülmez.
  bool get hasChunk => kind == TowerDropKind.cut && chunk1 - chunk0 > 0.3;
}

/// Ortası [moverCx], genişliği [moverW] olan kat, [topX0]..[topX1] üst
/// katının üstüne bırakılır. Örtüşme ≤ 0.5 ise ıska; merkez sapması
/// [tolerance] içindeyse kat alttakine tam oturur; değilse dışarıda kalan
/// kısım kesilir.
TowerDrop resolveTowerDrop({
  required double moverCx,
  required double moverW,
  required double topX0,
  required double topX1,
  required double tolerance,
}) {
  final m0 = moverCx - moverW / 2, m1 = moverCx + moverW / 2;
  final l = math.max(m0, topX0);
  final r = math.min(m1, topX1);
  if (r - l <= 0.5) return const TowerDrop._(TowerDropKind.miss, 0, 0);
  final delta = moverCx - (topX0 + topX1) / 2;
  if (delta.abs() <= tolerance) {
    return TowerDrop._(TowerDropKind.perfect, topX0, topX1);
  }
  final rightSide = delta > 0;
  return TowerDrop._(TowerDropKind.cut, l, r,
      chunk0: rightSide ? r : m0,
      chunk1: rightSide ? m1 : l,
      rightSide: rightSide);
}

/// Mükemmel serisinde kat genişler mi? Seri [every]'e ulaşınca ve seri
/// sürdükçe sonraki her mükemmel yerleşimde (tek seferlik değil).
bool towerStreakGrows(int streak, {int every = 5}) => streak >= every;

/// Seri ödülünde katın yeni genişliği: [by] kadar büyür, [maxW]'yi aşmaz.
double towerGrownWidth(double w, double maxW, double by) =>
    math.min(maxW, w + by);
