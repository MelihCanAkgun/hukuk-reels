import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';
import 'package:hukuk_reels/features/game/block_blast_engine.dart';

/// Joker seçimi açık 1v1 odası; iki oyuncu hazır (seçim başladı).
BattleMatch drafting({int seed = 12345}) {
  final m = BattleMatch('ABC234', seed, 0)..jokers = true;
  for (final id in [1, 2]) {
    m.join(id, 'Player $id', 0);
    m.connect(id, 0);
    m.ready(id, 0);
  }
  return m;
}

/// Seçim bitmiş, maç başlamış oda: [p1] birinci oyuncunun jokeri.
/// İkinci oyuncunun jokeri [p2]; kalan iki joker sırayla birer birer.
BattleMatch armed(String p1, [String? p2]) {
  p2 ??= p1 == 'freeze' ? 'expand' : 'freeze';
  final rest = jokerKinds.where((k) => k != p1 && k != p2).toList();
  final want = {
    1: [p1, rest[0]],
    2: [p2, rest[1]],
  };
  final m = drafting();
  for (var t = 100; m.turn != null; t += 10) {
    final id = m.turn!;
    expect(m.pick(id, want[id]!.removeAt(0), t)['ok'], true);
  }
  expect(m.player(1).jokers.toSet(), {p1, rest[0]});
  m.advance(100000);
  expect(m.status, 'playing');
  return m;
}

/// Boş hücre kalmayan dama tahtası: tepsideki 2'li parça sığmaz.
void noMoves(BattlePlayer p) {
  p.game.grid = List.generate(
      8, (r) => List<int?>.generate(8, (c) => (r + c).isEven ? 0 : null));
  p.game.tray = [const BlockPiece(0, 0), const BlockPiece(1, 1), null];
}

void main() {
  test('büyük L dört dönüşüyle var; çapraz ikili yalnız kurtarmada', () {
    final big = [
      for (var id = 0; id < blockShapes.length; id++)
        if (blockShapes[id].length == 5 &&
            BlockPiece(id, 0).rows == 3 &&
            BlockPiece(id, 0).cols == 3)
          {for (final c in blockShapes[id]) c[0] * 3 + c[1]}
    ];
    expect(big.length, 4);
    expect(big.toSet().length, 4);
    expect(rescueShapes.length, 2);
    expect(regularShapes.any(rescueShapes.contains), false);
    // Normal dağıtım çapraz ikiliyi hiç vermez.
    final engine = BlockBlastEngine(random: Random(1));
    for (var i = 0; i < 300; i++) {
      engine.grid = List.generate(8, (_) => List.filled(8, null));
      engine.refill();
      expect(engine.tray.any((p) => rescueShapes.contains(p!.shape)), false);
    }
  });

  test('çapraz iki boşluk: kurtarma parçası çapraz ikili', () {
    final grid = List.generate(8, (_) => List<int?>.filled(8, 0));
    grid[3][3] = null;
    grid[4][4] = null;
    final move = rescueMove(grid)!;
    expect(rescueShapes.contains(move.$1), true);
    expect((move.$2, move.$3), (3, 3));
  });

  test('kurtarma seyrek: yalnız sıkışık tahtada ve en az 6 sette bir', () {
    var rescues = 0, sets = 0, lastAt = -100;
    for (var seed = 0; seed < 40; seed++) {
      final engine = BlockBlastEngine.empty(random: Random(seed));
      for (var i = 0; i < 30; i++) {
        // Sıkışık tahta: yalnız iki satırın ve sütunun birer hücresi boş.
        engine.grid = List.generate(8, (_) => List<int?>.filled(8, 0));
        engine.grid[2][2] = null;
        engine.grid[5][6] = null;
        final before = engine.sinceRescue;
        engine.refill();
        sets++;
        if (engine.sinceRescue == 0) {
          rescues++;
          expect(before + 1, greaterThanOrEqualTo(BlockBlastEngine.rescueGap));
          if (lastAt >= 0) expect(i - lastAt, greaterThanOrEqualTo(6));
          lastAt = i;
        }
      }
      lastAt = -100;
    }
    expect(rescues, greaterThan(0));
    // Sürekli sıkışık tahtada bile setlerin ancak küçük bir kısmı.
    expect(rescues / sets, lessThan(.2));
    // Boş tahtada hiç kurtarma yok.
    final open = BlockBlastEngine(random: Random(3));
    for (var i = 0; i < 100; i++) {
      open.grid = List.generate(8, (_) => List.filled(8, null));
      open.refill();
      expect(open.sinceRescue, isNot(0));
    }
  });

  test('genişletme: köşeye göre kayar, 9×9 kaydedilir ve geri yüklenir', () {
    for (final (corner, dr, dc) in const [
      ('tl', 1, 1),
      ('tr', 1, 0),
      ('bl', 0, 1),
      ('br', 0, 0)
    ]) {
      final e = BlockBlastEngine(random: Random(2));
      e.grid[0][0] = 3;
      e.grid[7][7] = 4;
      expect(e.expand(corner), true);
      expect(e.size, 9);
      expect(e.grid[dr][dc], 3);
      expect(e.grid[7 + dr][7 + dc], 4);
      expect(e.expand(corner), false); // bir kez
      final restored = BlockBlastEngine.restore(
          jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>)!;
      expect(restored.size, 9);
      expect(restored.grid, e.grid);
    }
    // 9×9'da satır 9 hücreyle temizlenir.
    final e = BlockBlastEngine.empty()..expand('br');
    for (var c = 0; c < 8; c++) {
      e.grid[8][c] = 1;
    }
    e.tray = [const BlockPiece(0, 0), null, null];
    final move = e.place(0, 8, 8)!;
    expect(move.lines, 1);
    expect(
        move.clearedCells.keys.toSet(), {for (var c = 0; c < 9; c++) 72 + c});
  });

  test('ortak set 8×8 ve 9×9 tahtalara birlikte sığar', () {
    final a = BlockBlastEngine.empty(),
        b = BlockBlastEngine.empty()..expand('tl');
    final rng = Random(5);
    for (final e in [a, b]) {
      for (var i = 0; i < e.size * e.size * .45; i++) {
        e.grid[rng.nextInt(e.size)][rng.nextInt(e.size)] = 1;
      }
      e.tray = [null, null, null];
    }
    for (var i = 0; i < 20; i++) {
      final tray = fairBattleTray(77, i, [a, b]);
      expect(tray.length, 3);
    }
  });

  test('1v1 öncesi yazı-tura: iki oyuncu da yarı yarıya ilk seçer', () {
    var first = 0;
    for (var seed = 1; seed <= 400; seed++) {
      final m = drafting(seed: seed * 7919);
      expect(m.status, 'draft');
      expect(m.draftEnd, draftMs);
      if (m.picker == 1) first++;
    }
    expect(first, inInclusiveRange(160, 240));
    // Üçlüde joker yok.
    final t = BattleMatch('ABC234', 1, 0)
      ..mode = 'trio'
      ..jokers = true;
    for (final id in [1, 2, 3]) {
      t.join(id, 'P$id', 0);
      t.connect(id, 0);
      t.ready(id, 0);
    }
    expect(t.status, 'countdown');
  });

  test('seçim: sıra kontrolü, alınan seçilemez, sonra geri sayım', () {
    final m = drafting();
    final first = m.picker!, second = first == 1 ? 2 : 1;
    expect(m.pick(second, 'freeze', 10)['error'], 'Seçim sırası sende değil.');
    expect(m.pick(first, 'freeze', 1000)['ok'], true);
    expect(m.player(first).jokers, ['freeze']);
    expect(m.turn, second);
    expect(m.pick(second, 'freeze', 1500)['error'], 'Bu joker alınmış.');
    expect(m.pick(second, 'salt', 2000)['ok'], true);
    // Yılan sırası: ikinci oyuncu iki kez seçer, kalan ilk seçene verilir.
    expect(m.turn, second);
    expect(m.pick(first, 'expand', 2200)['error'], 'Seçim sırası sende değil.');
    expect(m.pick(second, 'expand', 2500)['ok'], true);
    expect(m.player(first).jokers, ['freeze', 'reflect']);
    expect(m.turn, isNull);
    // Sonuç kısa bir süre görünür, sonra 3 saniyelik geri sayım.
    expect(m.draftEnd, 5000);
    m.advance(5000);
    expect(m.status, 'countdown');
    expect(m.startAt, 8000);
    m.advance(8000);
    expect(m.status, 'playing');
    final restored = BattleMatch.restore(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(restored.player(second).jokers, ['salt', 'expand']);
    expect(restored.jokers, true);
  });

  test('15 saniyede seçilmezse jokerler rastgele dağıtılır', () {
    final m = drafting();
    m.advance(draftMs - 1);
    expect(m.status, 'draft');
    m.advance(draftMs);
    expect(m.status, 'countdown');
    expect(m.player(1).jokers.length, jokersEach);
    expect(m.player(2).jokers.length, jokersEach);
    expect({...m.player(1).jokers, ...m.player(2).jokers}, jokerKinds.toSet());
  });

  test('seçimde kopan bağlantı odayı beklemeye döndürür', () {
    final m = drafting();
    m.pick(m.picker!, 'expand', 10);
    m.disconnect(1, 20);
    expect(m.status, 'waiting');
    expect(m.players.every((p) => p.jokers.isEmpty), true);
    m.connect(1, 30);
    expect(m.status, 'draft');
  });

  test('dondurma: rakip 8 saniye parça koyamaz, joker bir kez', () {
    final m = armed('freeze');
    final victim = m.player(2);
    victim.game.grid = List.generate(8, (_) => List.filled(8, null));
    expect(m.useJoker(1, 'freeze', 5000)['ok'], true);
    expect(victim.frozenUntil, 5000 + freezeMs);
    expect(m.place(2, 1, 0, 0, 0, 6000)['error'], 'Tahtan donuk.');
    expect(m.useJoker(2, 'expand', 6000)['error'], 'Tahtan donuk.');
    expect(m.place(2, 1, 0, 0, 0, 12999)['error'], 'Tahtan donuk.');
    expect(m.place(2, 1, 0, 0, 0, 13000)['ok'], true);
    expect(m.useJoker(1, 'freeze', 13500)['error'], 'Bu joker sende yok.');
    expect(m.useJoker(2, 'freeze', 13500)['error'], 'Bu joker sende yok.');
  });

  test('genişletme maçta: tahta 9×9, board-out sonrası yine 8×8', () {
    final m = armed('expand');
    expect(m.useJoker(1, 'expand', 5000, corner: 'xx')['error'],
        'Tahta genişletilemez.');
    expect(m.useJoker(1, 'expand', 5000, corner: 'tr')['ok'], true);
    final p = m.player(1);
    expect(p.game.size, 9);
    expect(m.events.single['type'], 'EXPAND');
    // 9. satıra hamle geçerli.
    final slot = p.game.tray.indexWhere((x) => x != null);
    final piece = p.game.tray[slot]!;
    final spot =
        p.game.placements(piece).firstWhere((s) => s.$1 + piece.rows - 1 == 8);
    expect(m.place(1, 1, slot, spot.$1, spot.$2, 6000)['ok'], true);
    // Hamle kalmayınca (joker kullanıldı) can gider, tahta 8×8'e döner.
    p.game.grid = List.generate(
        9, (r) => List<int?>.generate(9, (c) => (r + c).isEven ? 0 : null));
    p.game.tray = [const BlockPiece(0, 0), null, null];
    p.game.grid[0][0] = null;
    final result = m.place(1, 2, 0, 0, 0, 7000);
    expect(result['ok'], true);
    expect(p.lives, 4);
    expect(p.game.size, 8);
  });

  test('hamle kalmayınca genişletme jokeri için 5 saniye beklenir', () {
    final m = armed('expand');
    final p = m.player(1);
    noMoves(p);
    p.game.grid[0][0] = null;
    p.game.tray = [const BlockPiece(0, 0), const BlockPiece(1, 1), null];
    // Tek hücreyi koyar; kalan ikili hiçbir yere sığmaz.
    p.game.grid[0][1] = null;
    p.game.grid[0][0] = 0;
    p.game.grid[1][1] = 0;
    expect(p.game.fits(const BlockPiece(1, 1), 0, 0), false);
    final slot = 0;
    final at = [
      for (var r = 0; r < 8; r++)
        for (var c = 0; c < 8; c++)
          if (p.game.grid[r][c] == null) (r, c)
    ].first;
    expect(m.place(1, 1, slot, at.$1, at.$2, 1000)['ok'], true);
    expect(p.stuckAt, 1000 + stuckMs);
    expect(p.lives, 5);
    expect(m.events.any((e) => e['type'] == 'STUCK'), true);
    // Süre dolarsa board-out.
    final late = BattleMatch.restore(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    late.advance(1000 + stuckMs);
    expect(late.player(1).lives, 4);
    expect(late.player(1).stuckAt, isNull);
    // Süre içinde genişletirse ve yer açılırsa devam eder.
    expect(m.useJoker(1, 'expand', 2000, corner: 'br')['ok'], true);
    expect(p.stuckAt, isNull);
    expect(p.lives, 5);
    expect(p.game.hasMove, true);
  });

  test('köşe seçilirken süre durur, duraklatmanın üst sınırı var', () {
    final m = armed('expand');
    final p = m.player(1);
    p.stuckAt = 1000 + stuckMs;
    // Çark açıldı: kalan 4 sn saklanır, süre işlemez.
    expect(m.aim(1, true, 2000)['ok'], true);
    expect(p.stuckAt, isNull);
    expect(p.stuckLeft, 4000);
    m.advance(9000);
    expect(p.lives, 5);
    // Çark kapandı: kaldığı yerden sürer.
    m.aim(1, false, 9000);
    expect(p.stuckAt, 13000);
    expect(p.stuckLeft, isNull);
    // Yeniden açınca yine durur ama ilk açılıştan 10 sn sonra tahta gider.
    m.aim(1, true, 10000);
    expect(p.stuckLeft, 3000);
    final copy = BattleMatch.restore(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(copy.player(1).stuckLeft, 3000);
    m.advance(2000 + aimMaxMs - 1);
    expect(p.lives, 5);
    m.advance(2000 + aimMaxMs);
    expect(p.lives, 4);
    expect([p.stuckAt, p.stuckLeft, p.aimUntil], [null, null, null]);
    // Sınır dolduktan sonra duraklatma işe yaramaz.
    p.stuckAt = 20000;
    p.aimUntil = 15000;
    m.aim(1, true, 16000);
    expect(p.stuckAt, 20000);
    // Duraklatılmışken genişletmek takılmayı bitirir.
    p.aimUntil = null;
    m.aim(1, true, 16000);
    expect(m.useJoker(1, 'expand', 17000, corner: 'tl')['ok'], true);
    expect([p.stuckAt, p.stuckLeft, p.aimUntil], [null, null, null]);
  });

  test('genişletme 15 saniye sürer, sonra eklenen satır ve sütun gider', () {
    final m = armed('expand');
    final p = m.player(1);
    p.game.grid = List.generate(8, (_) => List<int?>.filled(8, null));
    p.game.grid[0][0] = 3;
    expect(m.useJoker(1, 'expand', 5000, corner: 'tl')['ok'], true);
    expect([p.expandUntil, p.expandCorner], [5000 + expandMs, 'tl']);
    expect(p.game.grid[1][1], 3);
    // Eklenen sol üst sütuna konan blok küçülünce gider.
    p.game.grid[0][4] = 2;
    final copy = BattleMatch.restore(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(copy.player(1).expandUntil, 5000 + expandMs);
    m.advance(5000 + expandMs - 1);
    expect(p.game.size, 9);
    m.advance(5000 + expandMs);
    expect(p.game.size, 8);
    expect(
        m.events.any((e) => e['type'] == 'SHRINK' && e['player'] == 1), true);
    expect(p.game.grid[0][0], 3);
    expect(p.game.grid.expand((r) => r).where((v) => v != null).length, 1);
    expect([p.expandUntil, p.expandCorner], [null, null]);
    expect(p.lives, 5);
  });

  test('küçülünce hamle kalmazsa board-out', () {
    final m = armed('expand');
    final p = m.player(1);
    expect(m.useJoker(1, 'expand', 5000, corner: 'br')['ok'], true);
    // Sığan tek yer eklenen satırda: küçülünce hamle kalmaz.
    p.game.grid = List.generate(
        9, (r) => List<int?>.generate(9, (c) => (r + c).isEven ? 0 : null));
    p.game.grid[8][1] = null;
    p.game.grid[8][2] = null;
    p.game.tray = [const BlockPiece(1, 1), null, null];
    m.advance(5000 + expandMs);
    expect(p.lives, 4);
    expect(p.game.size, 8);
  });

  test('billur tuz: rakibin ortasına 1×3, silinmez, 20 sn sonra gider', () {
    final m = armed('salt');
    final v = m.player(2);
    v.game.grid = List.generate(8, (_) => List<int?>.filled(8, null));
    v.game.grid[4][4] = 5; // tuzun altında kalan blok gider
    expect(m.useJoker(1, 'salt', 5000)['ok'], true);
    const salt = BlockBlastEngine.saltCell;
    expect([for (var r = 0; r < 8; r++) v.game.grid[r][4]],
        [null, null, null, salt, salt, salt, null, null]);
    expect(v.saltUntil, 5000 + saltMs);
    expect(m.events.single['type'], 'SALT');
    expect(m.player(1).usedJokers, ['salt']);
    // Tuz engeldir: üstüne konamaz, içinden geçen satır tamamlanamaz.
    v.game.tray = [const BlockPiece(0, 2), null, null];
    expect(m.place(2, 1, 0, 4, 4, 5500)['error'], 'Geçersiz yerleştirme.');
    for (var c = 0; c < 8; c++) {
      if (c != 4 && c != 0) v.game.grid[4][c] = 1;
    }
    final res = m.place(2, 1, 0, 4, 0, 6000);
    expect(res['ok'], true);
    expect((res['move'] as Map)['lines'], 0);
    expect(v.game.grid[4], [2, 1, 1, 1, salt, 1, 1, 1]);
    // Tuz gidince o satır boşlukla kalır (tam dolu değil).
    v.game.grid[4][0] = 2;
    // Kayıt ve geri yükleme tuzu korur.
    final copy = BattleMatch.restore(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(copy.player(2).game.grid[3][4], salt);
    m.advance(5000 + saltMs);
    expect(v.game.grid.expand((r) => r).contains(salt), false);
    expect(v.saltUntil, isNull);
    expect(m.events.any((e) => e['type'] == 'SALT_GONE'), true);
  });

  test('tuz 9×9 tahtada tam ortada; hamle bırakmazsa board-out', () {
    final engine = BlockBlastEngine.empty()..expand('br');
    engine.placeSalt();
    expect([for (var r = 0; r < 9; r++) engine.grid[r][4] != null],
        [false, false, false, true, true, true, false, false, false]);
    final m = armed('salt');
    final v = m.player(2);
    // Dama tahtası; dikey ikili yalnız orta sütuna sığar, tuz orayı kapatır.
    v.game.grid = List.generate(
        8, (r) => List<int?>.generate(8, (c) => (r + c).isEven ? 0 : null));
    v.game.grid[4][4] = null;
    v.game.tray = [const BlockPiece(2, 1), null, null];
    expect(v.game.hasMove, true);
    expect(m.useJoker(1, 'salt', 5000)['ok'], true);
    expect(v.lives, 4);
    expect(v.saltUntil, isNull);
  });

  test('yansıt: 30 sn içinde gelen dondurma atana döner, gizli', () {
    final m = armed('reflect');
    final p1 = m.player(1), p2 = m.player(2);
    expect(m.useJoker(1, 'reflect', 5000)['ok'], true);
    expect(m.events, isEmpty);
    expect(p1.usedJokers, ['reflect']);
    expect(p1.reflectUntil, 5000 + reflectMs);
    expect(m.useJoker(2, 'freeze', 6000)['ok'], true);
    expect(p2.frozenUntil, 6000 + freezeMs);
    expect(p1.frozenUntil, isNull);
    expect(p1.reflected, true);
    expect(m.events.single['reflected'], true);
    expect(m.events.single['player'], 2);
  });

  test('yansıt süresi dolunca joker normal işler; tuz da yansır', () {
    var m = armed('reflect');
    m.useJoker(1, 'reflect', 5000);
    m.useJoker(2, 'freeze', 5000 + reflectMs);
    expect(m.player(1).frozenUntil, 5000 + reflectMs + freezeMs);
    expect(m.player(1).reflected, false);

    m = armed('salt', 'reflect');
    m.useJoker(2, 'reflect', 5000);
    m.player(1).game.grid = List.generate(8, (_) => List<int?>.filled(8, null));
    expect(m.useJoker(1, 'salt', 7000)['ok'], true);
    expect(m.player(1).game.grid[4][4], BlockBlastEngine.saltCell);
    expect(m.player(1).saltUntil, 7000 + saltMs);
    expect(m.player(2).saltUntil, isNull);
  });
}
