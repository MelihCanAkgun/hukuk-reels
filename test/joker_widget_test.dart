import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/block_battle_core.dart';
import 'package:hukuk_reels/features/game/block_battle_jokers.dart';
import 'package:hukuk_reels/features/game/block_battle_session.dart';
import 'package:hukuk_reels/features/game/block_blast_screen.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> frame(BattleMatch m, int me, {List events = const []}) => {
      'me': me,
      'state': jsonDecode(jsonEncode(m.toJson())),
      'connected': true,
      'pending': false,
      'events': events,
    };

/// Seçimi süren 1v1 odası (şimdi başladı).
BattleMatch drafting(int now) {
  final m = BattleMatch('ABC234', 42, now)..jokers = true;
  for (final id in [1, 2]) {
    m.join(id, 'Oyuncu $id', now);
    m.connect(id, now);
    m.ready(id, now);
  }
  return m;
}

/// Oynanan 1v1: birinci oyuncunun jokeri [mine], rakibinki [theirs].
BattleMatch armed(String mine, [String? theirs]) {
  theirs ??= mine == 'freeze' ? 'expand' : 'freeze';
  final now = DateTime.now().millisecondsSinceEpoch;
  final m = drafting(now - 20000);
  final rest = jokerKinds.where((k) => k != mine && k != theirs).toList();
  final want = {
    1: [mine, rest[0]],
    2: [theirs, rest[1]],
  };
  for (var t = now - 19000; m.turn != null; t += 10) {
    final id = m.turn!;
    m.pick(id, want[id]!.removeAt(0), t);
  }
  m.advance(now);
  expect(m.status, 'playing');
  expect(m.player(1).jokers, contains(mine));
  return m;
}

void main() {
  final calls = <(String, Map<String, dynamic>)>[];
  BlockBattleSession session(BattleMatch m, int me) => BlockBattleSession(
      listen: false,
      transport: (action, data) async {
        calls.add((action, data));
        return {};
      })
    ..receive(frame(m, me));

  setUp(() async {
    calls.clear();
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
  });

  Future<void> show(WidgetTester tester, BlockBattleSession s) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: BlockBlastScreen(battle: s)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('seçim ekranı: yazı-tura, sırası gelen jokerini seçer',
      (tester) async {
    final m = drafting(DateTime.now().millisecondsSinceEpoch);
    final picker = m.picker!, other = picker == 1 ? 2 : 1;
    final s = session(m, picker);
    await show(tester, s);
    expect(find.byKey(const ValueKey('joker-draft')), findsOneWidget);
    expect(find.byKey(const ValueKey('block-board')), findsNothing);
    for (final kind in jokerKinds) {
      expect(find.byKey(ValueKey('joker-card-$kind')), findsOneWidget);
    }
    // Jeton dönerken seçilemez.
    await tester.tap(find.byKey(const ValueKey('joker-card-freeze')));
    expect(calls.where((c) => c.$1 == 'pick'), isEmpty);
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('SIRA SENDE · 1. JOKERİNİ SEÇ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('joker-card-freeze')));
    await tester.pump();
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'pick',
      {'joker': 'freeze'}
    ]);
    // Sunucu onaylayınca sıra diğerine geçer; o da seçince maç başlar.
    m.pick(picker, 'freeze', DateTime.now().millisecondsSinceEpoch);
    s.receive(frame(m, picker));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SENİN'), findsOneWidget);
    expect(find.text('Oyuncu $other SEÇİYOR'), findsOneWidget);
    // Diğeri iki kez seçer; kalan joker ilk seçene verilir.
    m.pick(other, 'salt', DateTime.now().millisecondsSinceEpoch);
    s.receive(frame(m, picker));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Oyuncu $other SEÇİYOR'), findsOneWidget);
    m.pick(other, 'expand', DateTime.now().millisecondsSinceEpoch);
    s.receive(frame(m, picker));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SENİN'), findsNWidgets(2));
    expect(find.text('Oyuncu $other'), findsWidgets);
    expect(find.text('MAÇ BAŞLIYOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('rakip seçerken kartlar kilitli', (tester) async {
    final m = drafting(DateTime.now().millisecondsSinceEpoch);
    final other = m.picker == 1 ? 2 : 1;
    final s = session(m, other);
    await show(tester, s);
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('Oyuncu ${m.picker} SEÇİYOR'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('joker-card-expand')));
    expect(calls.where((c) => c.$1 == 'pick'), isEmpty);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('dondurma: dokununca atılır, rakipte buz ve sayaç',
      (tester) async {
    final m = armed('freeze');
    final s = session(m, 1);
    await show(tester, s);
    expect(find.byKey(const ValueKey('battle-joker-freeze')), findsOneWidget);
    expect(find.byKey(const ValueKey('battle-opponent-joker-2-expand')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('battle-joker-freeze')));
    await tester.pump(const Duration(milliseconds: 50));
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'joker',
      {'joker': 'freeze'}
    ]);
    expect(find.byType(IceProjectile), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(IceProjectile), findsNothing);

    // Sunucu: rakip dondu. Kendi ekranında rakip kartı buzlu.
    final now = DateTime.now().millisecondsSinceEpoch;
    m.useJoker(1, 'freeze', now);
    s.receive(frame(m, 1, events: m.events));
    await tester.pump(const Duration(milliseconds: 50));
    expect(
        find.byKey(const ValueKey('battle-opponent-frozen-2')), findsOneWidget);
    expect(find.text('KULLANILDI'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    s.dispose();

    // Rakibin ekranı: tahta donuk, parça sürüklenemez.
    final victim = session(m, 2);
    expect(victim.canPlay, false);
    await show(tester, victim);
    expect(find.byType(FreezeOverlay), findsOneWidget);
    expect(find.byKey(const ValueKey('freeze-left')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    victim.dispose();
  });

  testWidgets('genişletme: basılı tut, köşeye kaydır, tahta 9×9',
      (tester) async {
    final m = armed('expand');
    final s = session(m, 1);
    await show(tester, s);
    final button =
        tester.getCenter(find.byKey(const ValueKey('battle-joker-expand')));
    final gesture = await tester.startGesture(button);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('expand-wheel')), findsOneWidget);
    expect(find.text('KÖŞE SEÇ'), findsOneWidget);
    // Parmağın olduğu yer seçer: tahtanın sol alt bölümü.
    final board = tester.getRect(find.byKey(const ValueKey('block-board')));
    // Ortadaki boşlukta seçim yok.
    await gesture.moveTo(board.center + const Offset(-10, 10));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('BIRAK'), findsNothing);
    await gesture.moveTo(board.bottomLeft + const Offset(20, -20));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('BIRAK'), findsOneWidget);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('expand-wheel')), findsNothing);
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'joker',
      {'joker': 'expand', 'corner': 'bl'}
    ]);

    m.useJoker(1, 'expand', DateTime.now().millisecondsSinceEpoch,
        corner: 'bl');
    s.receive(frame(m, 1, events: m.events));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('9 × 9 oyun tahtası'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('dokunarak açılan çarkta köşeye dokunmak da seçer',
      (tester) async {
    final m = armed('expand');
    final s = session(m, 1);
    await show(tester, s);
    await tester.tap(find.byKey(const ValueKey('battle-joker-expand')));
    await tester.pump(const Duration(milliseconds: 200));
    final wheel = tester.getRect(find.byKey(const ValueKey('expand-wheel')));
    await tester
        .tapAt(wheel.center + Offset(wheel.width * .3, -wheel.width * .3));
    await tester.pump(const Duration(milliseconds: 50));
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'joker',
      {'joker': 'expand', 'corner': 'tr'}
    ]);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('hamle kalmadıysa genişletme uyarısı ve süre', (tester) async {
    final m = armed('expand');
    m.player(1).stuckAt = DateTime.now().millisecondsSinceEpoch + 4000;
    final s = session(m, 1);
    expect(s.canPlay, false);
    expect(s.jokerReady('expand'), true);
    await show(tester, s);
    expect(find.byKey(const ValueKey('battle-stuck')), findsOneWidget);
    expect(find.text('HAMLE YOK!'), findsOneWidget);
    // Uyarı tahtanın ortasında.
    final board = tester.getRect(find.byKey(const ValueKey('block-board')));
    final banner = tester.getCenter(find.byKey(const ValueKey('battle-stuck')));
    expect((banner - board.center).distance, lessThan(30));
    // Çark açılınca süre durdurulur, kapanınca sürer.
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('battle-joker-expand'))));
    await tester.pump(const Duration(milliseconds: 100));
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'aim',
      {'on': true}
    ]);
    // Sunucu süreyi durdurdu: çarkta seçim için kalan süre görünür.
    final now = DateTime.now().millisecondsSinceEpoch;
    m.aim(1, true, now);
    s.receive(frame(m, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('wheel-seconds')), findsOneWidget);
    expect(find.text('${aimMaxMs ~/ 1000}'), findsOneWidget);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('expand-wheel')), findsNothing);
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'aim',
      {'on': false}
    ]);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('buz çözülünce tepsi ve joker yeniden açılır', (tester) async {
    final m = armed('expand');
    m.player(1).frozenUntil = DateTime.now().millisecondsSinceEpoch + 300;
    final s = session(m, 1);
    await show(tester, s);
    expect(s.jokerReady('expand'), false);
    expect(find.byType(FreezeOverlay), findsOneWidget);
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FreezeOverlay), findsNothing);
    expect(find.text('GENİŞLET'), findsOneWidget);
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('battle-joker-expand'))));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('expand-wheel')), findsOneWidget);
    await gesture.up();
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('yansıt: sessiz kullanılır, atış yok, kendi ekranında süre',
      (tester) async {
    final m = armed('reflect');
    final s = session(m, 1);
    await show(tester, s);
    expect(find.text('YANSIT'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('battle-joker-reflect')));
    await tester.pump(const Duration(milliseconds: 50));
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'joker',
      {'joker': 'reflect'}
    ]);
    expect(find.byType(IceProjectile), findsNothing);
    m.useJoker(1, 'reflect', DateTime.now().millisecondsSinceEpoch);
    s.receive(frame(m, 1, events: m.events));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('AKTİF · 30'), findsOneWidget);
    // Rakip dondurmayı atınca yansır: rakip donar.
    m.useJoker(2, 'freeze', DateTime.now().millisecondsSinceEpoch);
    s.receive(frame(m, 1, events: m.events));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('YANSITTIN! RAKİP DONDU'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('battle-opponent-frozen-2')), findsOneWidget);
    expect(find.byType(FreezeOverlay), findsNothing);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });

  testWidgets('billur tuz: atılır, rakipte tahtanın ortasında çizilir',
      (tester) async {
    final m = armed('salt');
    final s = session(m, 1);
    await show(tester, s);
    await tester.tap(find.byKey(const ValueKey('battle-joker-salt')));
    await tester.pump(const Duration(milliseconds: 50));
    expect([
      calls.last.$1,
      calls.last.$2
    ], [
      'joker',
      {'joker': 'salt'}
    ]);
    expect(find.byType(IceProjectile), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    m.player(2).game.grid = List.generate(8, (_) => List<int?>.filled(8, null));
    m.useJoker(1, 'salt', DateTime.now().millisecondsSinceEpoch);
    s.receive(frame(m, 1, events: m.events));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('RAKİBE TUZ · 20 SN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    s.dispose();

    // Rakibin ekranı: tuzlu hücreler dolu, oraya parça konamaz.
    final victim = session(m, 2);
    await show(tester, victim);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    victim.dispose();
  });

  testWidgets('genişletme süresi düğmede görünür', (tester) async {
    final m = armed('expand');
    m.useJoker(1, 'expand', DateTime.now().millisecondsSinceEpoch,
        corner: 'br');
    final s = session(m, 1);
    await show(tester, s);
    expect(find.text('9×9 · 15'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
}
