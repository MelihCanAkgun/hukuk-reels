import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/gate/access_gate.dart';
import 'package:hukuk_reels/features/shell/home_shell.dart';
import 'package:hukuk_reels/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _token = 'A' * 43;
String _stored(String token) => jsonEncode({'url': '', 'token': token});

/// Web yolunu JS olmadan sürer: saklı ayar ve köprü taklit edilir.
List<String> _web({String? stored, Map<String, dynamic> Function(String)? on}) {
  final calls = <String>[];
  AccessGate.native = false;
  AccessGate.readStored = () => stored;
  AccessGate.call = (action, [data = const {}]) async {
    calls.add(action);
    return on?.call(action) ?? {'ok': false, 'reason': 'offline'};
  };
  return calls;
}

Widget _app() => const MaterialApp(home: AccessGate(child: Text('UYGULAMA')));

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('com.ryanheise')) {
        return const StandardMethodCodec()
            .encodeSuccessEnvelope(<String, dynamic>{});
      }
      return handler?.call(message);
    };
  });
  tearDown(AccessGate.debugReset);

  test('stored code format check', () {
    _web(stored: _stored(_token));
    expect(AccessGate.hasStoredCode(), isTrue);
    for (final bad in [null, '', '{', '{}', _stored(''), _stored('kisa')]) {
      AccessGate.readStored = () => bad;
      expect(AccessGate.hasStoredCode(), isFalse, reason: '$bad');
    }
  });

  testWidgets('stored token opens HomeShell on the first frame',
      (tester) async {
    final calls = _web(stored: _stored(_token));
    await tester.pumpWidget(const HukukReelsApp());
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Giriş'), findsNothing);
    expect(AccessGate.unlocked.value, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, ['recheck']);
    expect(find.byType(HomeShell), findsOneWidget,
        reason: 'offline recheck keeps the app open');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('native builds bypass the gate', (tester) async {
    AccessGate.native = true;
    await tester.pumpWidget(_app());
    expect(find.text('UYGULAMA'), findsOneWidget);
  });

  testWidgets('a definite 401 on recheck asks for the code again',
      (tester) async {
    _web(
        stored: _stored(_token), on: (_) => {'ok': false, 'reason': 'invalid'});
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('UYGULAMA'), findsNothing);
    expect(find.text('Kod doğrulanamadı. Tekrar dene.'), findsOneWidget);
    expect(AccessGate.unlocked.value, isFalse);
  });

  testWidgets('no token shows only the gate; bad code shows an error',
      (tester) async {
    final calls = _web(on: (_) => {'ok': false, 'reason': 'invalid'});
    await tester.pumpWidget(const HukukReelsApp());
    await tester.pump();
    expect(find.byType(HomeShell), findsNothing);
    expect(find.text('Giriş'), findsOneWidget);
    expect(find.text('Erişim kodu'), findsOneWidget);
    final field =
        tester.widget<TextField>(find.byKey(const ValueKey('gate-code')));
    expect(field.obscureText, isTrue);
    expect(field.autofocus, isTrue);

    await tester.tap(find.byKey(const ValueKey('gate-submit')));
    await tester.pump();
    expect(find.text('Kodu girmen gerekiyor.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('gate-code')), 'yanlis');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    expect(find.text('Kod biçimi geçersiz.'), findsOneWidget);
    expect(calls, isEmpty);

    final reply = Completer<Map<String, dynamic>>();
    AccessGate.call = (action, [data = const {}]) {
      calls.add(action);
      return reply.future;
    };
    await tester.enterText(find.byKey(const ValueKey('gate-code')), 'B' * 43);
    await tester.tap(find.byKey(const ValueKey('gate-submit')));
    await tester.pump();
    // İstek sürerken düğme kapalı; Enter yine _submit'e ulaşır ve _busy
    // koruması ikinci isteği engeller. Alan salt-okunur, odak korunur.
    final button = find.byKey(const ValueKey('gate-submit'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    final busyField =
        tester.widget<TextField>(find.byKey(const ValueKey('gate-code')));
    expect(busyField.readOnly, isTrue);
    expect(busyField.onSubmitted, isNotNull);
    busyField.onSubmitted!('B' * 43);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    expect(calls, ['verify'], reason: 'one request per submit');
    reply.complete({'ok': false, 'reason': 'invalid'});
    await tester.pump();
    expect(find.text('Kod doğrulanamadı. Tekrar dene.'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);

    await tester.tap(find.byTooltip('Kodu göster'));
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('gate-code')))
            .obscureText,
        isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rate limit and offline errors are explained', (tester) async {
    var reason = 'rate';
    _web(on: (_) => {'ok': false, 'reason': reason});
    await tester.pumpWidget(_app());
    await tester.enterText(find.byKey(const ValueKey('gate-code')), _token);
    await tester.tap(find.byKey(const ValueKey('gate-submit')));
    await tester.pump();
    expect(find.text('Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.'),
        findsOneWidget);
    reason = 'offline';
    await tester.tap(find.byKey(const ValueKey('gate-submit')));
    await tester.pump();
    expect(
        find.text('Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.'),
        findsOneWidget);
  });

  testWidgets('valid code opens the app and delivers a queued invite',
      (tester) async {
    final calls = _web(on: (_) => {'ok': true, 'me': 1});
    await tester.pumpWidget(_app());
    var invites = 0;
    AccessGate.whenUnlocked(() => invites++);
    await tester.pump();
    expect(invites, 0, reason: 'nothing opens while gated');
    await tester.enterText(find.byKey(const ValueKey('gate-code')), _token);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    await tester.pump();
    expect(calls, ['verify']);
    expect(find.text('UYGULAMA'), findsOneWidget);
    expect(invites, 1);
  });

  for (final size in [const Size(320, 480), const Size(844, 390)]) {
    testWidgets('gate fits $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      _web();
      await tester.pumpWidget(_app());
      await tester.enterText(find.byKey(const ValueKey('gate-code')), 'x');
      await tester.tap(find.byKey(const ValueKey('gate-submit')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('5xx has its own message', (tester) async {
    _web(on: (_) => {'ok': false, 'reason': 'server'});
    await tester.pumpWidget(_app());
    await tester.enterText(find.byKey(const ValueKey('gate-code')), _token);
    await tester.tap(find.byKey(const ValueKey('gate-submit')));
    await tester.pump();
    expect(find.text('Sunucuya şu an ulaşılamıyor. Biraz sonra tekrar dene.'),
        findsOneWidget);
  });

  test('a revoked stored code counts as absent (token kept)', () {
    _web(stored: jsonEncode({'token': _token, 'revoked': true}));
    expect(AccessGate.hasStoredCode(), isFalse);
  });
}
