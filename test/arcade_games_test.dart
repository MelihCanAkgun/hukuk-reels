import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/game/flappy_cat_screen.dart';
import 'package:hukuk_reels/features/game/subway_cat_screen.dart';
import 'package:hukuk_reels/features/game/tower_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _run(WidgetTester tester, Duration d,
    {void Function()? each}) async {
  final n = d.inMilliseconds * 60 ~/ 1000;
  for (var i = 0; i < n; i++) {
    each?.call();
    await tester.pump(const Duration(microseconds: 16667));
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    // Ses eklentisi testte yok: just_audio kanallarını sessizce yanıtla.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('com.ryanheise')) {
        return const StandardMethodCodec()
            .encodeSuccessEnvelope(<String, dynamic>{});
      }
      return handler?.call(message);
    };
  });

  Future<void> phone(WidgetTester tester, Widget game,
      {Size size = const Size(390, 844)}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: game));
  }

  testWidgets('Flappy: autopilot scores through pipes without errors',
      (tester) async {
    await phone(tester, const FlappyCatScreen());
    await _run(tester, const Duration(milliseconds: 300));
    expect(find.text('Hazır mısın?'), findsOneWidget);
    await tester.tapAt(const Offset(200, 400));
    final state = tester.state(find.byType(FlappyCatScreen)) as dynamic;
    await _run(tester, const Duration(seconds: 12),
        each: () => state.autopilot());
    expect(state.score as int, greaterThanOrEqualTo(5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Subway: never blocks all three lanes with trains',
      (tester) async {
    await phone(tester, const SubwayCatScreen());
    await _run(tester, const Duration(milliseconds: 200));
    final state = tester.state(find.byType(SubwayCatScreen)) as dynamic;
    state.debugStart(god: true);
    var trains = 0;
    await _run(tester, const Duration(seconds: 90), each: () {
      final obs = (state.obs as List).where((o) => o.isTrain as bool);
      trains += obs.length;
      // Oyuncunun önündeki her noktada en az bir şerit trensiz kalmalı.
      for (var z = 0.0; z < 70; z += 0.5) {
        final blocked = <double>{
          for (final o in obs)
            if ((o.vz as double) == 0 &&
                (o.z as double) - 1 <= z &&
                (o.z as double) + (o.len as double) >= z)
              o.x as double
        };
        expect(blocked.length, lessThan(3), reason: 'z=$z');
      }
    });
    expect(trains, greaterThan(0));
    expect(state.dist as double, greaterThan(1000));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tower: perfect drops climb through eras and grow the floor',
      (tester) async {
    await phone(tester, const TowerScreen());
    await _run(tester, const Duration(milliseconds: 200));
    final state = tester.state(find.byType(TowerScreen)) as dynamic;
    var frames = 0;
    while ((state.score as int) < 40 && frames < 60 * 120) {
      state.autopilot();
      await tester.pump(const Duration(microseconds: 16667));
      frames++;
    }
    expect(state.score as int, greaterThanOrEqualTo(40));
    // 40 kat → 5 dönem geçildi; mükemmel seriler katı tam genişlikte tutar.
    expect(state.perfects as int, greaterThan(20));
    expect((state.top.w as double), greaterThan(80));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Tower: second chance widens the last floor', (tester) async {
    await phone(tester, const TowerScreen());
    await _run(tester, const Duration(milliseconds: 200));
    final state = tester.state(find.byType(TowerScreen)) as dynamic;
    state.autopilot(); // başlat
    // Bilerek kaydırarak bırak: kat daralsın.
    var frames = 0;
    while ((state.score as int) < 2 && frames < 3000) {
      final d = (state.mx as double) - (state.top.cx as double);
      if ((d - 30).abs() < 3) await tester.tapAt(const Offset(200, 500));
      await tester.pump(const Duration(microseconds: 16667));
      frames++;
    }
    final narrow = state.top.w as double;
    expect(narrow, lessThan(80));
    frames = 0;
    while (find.text('Bir şansın daha!').evaluate().isEmpty && frames < 3000) {
      state.autopilot(miss: true);
      await tester.pump(const Duration(microseconds: 16667));
      frames++;
    }
    state.debugRevive();
    await _run(tester, const Duration(milliseconds: 600));
    expect(state.top.w as double, greaterThanOrEqualTo(narrow + 24 - 0.01));
    expect(state.mw as double, closeTo(state.top.w as double, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in const [Size(390, 844), Size(320, 568), Size(1280, 800)]) {
    testWidgets('Tower: miss ends with the lawyer on top at $size',
        (tester) async {
      await phone(tester, const TowerScreen(), size: size);
      await _run(tester, const Duration(milliseconds: 200));
      final state = tester.state(find.byType(TowerScreen)) as dynamic;
      var frames = 0;
      while ((state.score as int) < 6 && frames < 3000) {
        state.autopilot();
        await tester.pump(const Duration(microseconds: 16667));
        frames++;
      }
      frames = 0;
      while (
          find.text('Bir şansın daha!').evaluate().isEmpty && frames < 3000) {
        state.autopilot(miss: true);
        await tester.pump(const Duration(microseconds: 16667));
        frames++;
      }
      expect(find.text('Bir şansın daha!'), findsOneWidget);
      await tester.tap(find.text('Hayır, bitir'));
      await _run(tester, const Duration(seconds: 6));
      expect(state.landT as double, greaterThan(0));
      expect(find.text('Tekrar Oyna'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tekrar Oyna'));
      await _run(tester, const Duration(milliseconds: 300));
      expect(state.score as int, 0);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final size in const [Size(390, 844), Size(320, 568), Size(1280, 800)]) {
    testWidgets('Subway: a real run ends on the revive prompt at $size',
        (tester) async {
      await phone(tester, const SubwayCatScreen(), size: size);
      await _run(tester, const Duration(milliseconds: 200));
      final state = tester.state(find.byType(SubwayCatScreen)) as dynamic;
      state.debugStart(god: false);
      await _run(tester, const Duration(seconds: 30));
      expect(find.text('Bir şansın daha!'), findsOneWidget);
      await tester.tap(find.text('Hayır, bitir'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Tekrar Oyna'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Flappy: game over panel fits at $size', (tester) async {
      await phone(tester, const FlappyCatScreen(), size: size);
      await _run(tester, const Duration(milliseconds: 200));
      await tester.tapAt(const Offset(100, 100));
      await _run(tester, const Duration(seconds: 4));
      await tester.tap(find.text('Hayır, bitir'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Tekrar Oyna'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
