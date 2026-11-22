import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/gate/access_gate.dart';

/// İki gerçek oyuncunun kapıda kilitlenmediğini doğrular (web yolu, JS'siz).
final _token = 'A' * 43;
// Kapıdan önceki kayıt biçimi: `me` alanı yok.
final _oldFormat = jsonEncode({
  'url': 'https://social.example',
  'token': _token,
  'best': 120,
  'bests': {'flappy': 4},
  'blockSeason': 2,
  'plays': {},
});

List<String> _web(String? Function() read,
    FutureOr<Map<String, dynamic>> Function(String) on) {
  final calls = <String>[];
  AccessGate.native = false;
  AccessGate.readStored = read;
  AccessGate.call = (action, [data = const {}]) async {
    calls.add(action);
    return on(action);
  };
  return calls;
}

final _navKey = GlobalKey<NavigatorState>();
Widget _app() => MaterialApp(
    navigatorKey: _navKey, home: const AccessGate(child: Text('UYGULAMA')));

void main() {
  tearDown(AccessGate.debugReset);

  testWidgets('8 old-format config (no me) opens on the first frame',
      (tester) async {
    _web(() => _oldFormat, (_) => {'ok': false, 'reason': 'offline'});
    await tester.pumpWidget(_app());
    expect(find.text('UYGULAMA'), findsOneWidget);
    expect(find.text('Giriş'), findsNothing);
  });

  testWidgets('4 updated config with cached me also opens', (tester) async {
    final stored = jsonEncode({...jsonDecode(_oldFormat), 'me': 2});
    _web(() => stored, (_) => {'ok': true, 'me': 2});
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('UYGULAMA'), findsOneWidget);
  });

  // 1 + 2: offline, 5xx, 429, timeout, bridge error map, bridge throw.
  final outcomes = <String, FutureOr<Map<String, dynamic>> Function()>{
    'offline': () => {'ok': false, 'reason': 'offline'},
    'server 500': () => {'ok': false, 'reason': 'server'},
    'rate 429': () => {'ok': false, 'reason': 'rate'},
    'bridge error map': () => {'error': 'Bağlantı kurulamadı.'},
    'bridge throws': () => throw StateError('x'),
    'slow (timeout)': () => Future.delayed(
        const Duration(seconds: 13), () => {'ok': false, 'reason': 'offline'}),
  };
  outcomes.forEach((name, outcome) {
    testWidgets('1/2 recheck $name keeps the app open', (tester) async {
      final calls = _web(() => _oldFormat, (_) => outcome());
      await tester.pumpWidget(_app());
      expect(find.text('UYGULAMA'), findsOneWidget);
      await tester.pump(const Duration(seconds: 14));
      expect(calls, ['recheck']);
      expect(find.text('UYGULAMA'), findsOneWidget);
      expect(find.text('Giriş'), findsNothing);
      expect(AccessGate.unlocked.value, isTrue);
    });
  });

  testWidgets('3 401 mid-game: game keeps running, gate on return home',
      (tester) async {
    final reply = Completer<Map<String, dynamic>>();
    var reads = 0;
    _web(() {
      reads++;
      return _oldFormat;
    }, (_) => reply.future);
    await tester.pumpWidget(_app());
    _navKey.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('OYUN'))));
    await tester.pumpAndSettle();
    expect(find.text('OYUN'), findsOneWidget);
    reply.complete({'ok': false, 'reason': 'invalid'});
    await tester.pumpAndSettle();
    expect(find.text('OYUN'), findsOneWidget, reason: 'game is not closed');
    expect(AccessGate.unlocked.value, isFalse, reason: 'invites wait');
    _navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('UYGULAMA'), findsNothing);
    expect(find.text('Giriş'), findsOneWidget);
    expect(find.text('Kod doğrulanamadı. Tekrar dene.'), findsOneWidget);
    // Dart saklı değere dokunmaz.
    expect(AccessGate.hasStoredCode(), isTrue);
    expect(reads, greaterThanOrEqualTo(1));
  });

  testWidgets('3b 401 on the home route locks immediately', (tester) async {
    _web(() => _oldFormat, (_) => {'ok': false, 'reason': 'invalid'});
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('UYGULAMA'), findsNothing);
    expect(find.text('Giriş'), findsOneWidget);
  });

  testWidgets('5 localStorage throws → gate, no crash', (tester) async {
    _web(() => throw StateError('SecurityError'), (_) => {'ok': true, 'me': 1});
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Giriş'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('gate-code')), _token);
    await tester.tap(find.byKey(const ValueKey('gate-submit')));
    await tester.pump();
    await tester.pump();
    expect(find.text('UYGULAMA'), findsOneWidget,
        reason: 'valid code still unlocks this session');
  });

  testWidgets('6 after leave (token "") next launch shows the gate',
      (tester) async {
    final left = jsonEncode({...jsonDecode(_oldFormat), 'token': ''});
    final calls = _web(() => left, (_) => {'ok': true});
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('Giriş'), findsOneWidget);
    expect(calls, isEmpty, reason: 'no recheck without a code');
  });

  for (final bad in ['{', 'not json', '[]', 'null', '"x"', '{"token":5}']) {
    testWidgets('7 malformed stored config $bad → gate, no crash',
        (tester) async {
      _web(() => bad, (_) => {'ok': false, 'reason': 'offline'});
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Giriş'), findsOneWidget);
    });
  }
}
