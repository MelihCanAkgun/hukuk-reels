import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/home/home_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes are throttled, single-flight and writes update the list',
      () async {
    final store = HomeStore.instance;
    final calls = <String>[];
    var now = DateTime(2026, 10, 16, 12);
    final arrival = DateTime(2026, 10, 28).millisecondsSinceEpoch ~/ 1000;
    Map<String, dynamic> list(List<String> places) => {
          'connected': true,
          'trips': [
            for (var i = 0; i < places.length; i++)
              {
                'id': i + 1,
                'player': 2,
                'name': 'ari',
                'destination': places[i],
                'arrival': arrival,
                'created': arrival - 86400
              },
          ],
        };
    store
      ..clock = (() => now)
      ..call = (action, [data = const {}]) async {
        calls.add(action);
        return action == 'tripAdd'
            ? list(['İstanbul', data['destination'] as String])
            : list(['İstanbul']);
      };

    // Two refreshes at once → one request.
    await Future.wait([store.refresh(force: true), store.refresh(force: true)]);
    expect(calls, ['home']);
    expect(store.connected, isTrue);
    expect(store.trips.single.sentence, "ari'nin İstanbul'a gelmesine");

    // App resumes within a minute → no request; after a minute → one.
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['home']);
    now = now.add(const Duration(seconds: 61));
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['home', 'home']);

    // Adding uses the list the server returns (no extra fetch).
    final changes = store.changes.value;
    await store.add('Ankara', DateTime(2026, 11, 1));
    expect(calls, ['home', 'home', 'tripAdd']);
    expect(store.trips.map((t) => t.destination), ['İstanbul', 'Ankara']);
    expect(store.changes.value, greaterThan(changes));
  });

  test('player id is forgotten after leaving the group', () async {
    final store = HomeStore.instance;
    var reply = <String, dynamic>{'connected': true, 'me': 2};
    store.call = (action, [data = const {}]) async => reply;

    await store.refresh(force: true);
    expect(store.me, 2);
    expect(store.isAri, isTrue);

    // Bağlı yanıt kimliksiz gelirse bilinen oyuncu korunur.
    reply = {'connected': true};
    await store.refresh(force: true);
    expect(store.isAri, isTrue);

    // Gruptan çıkış: /home kimliksiz ve bağlantısız döner.
    reply = {'connected': false};
    var changes = store.changes.value;
    await store.refresh(force: true);
    expect(store.me, isNull);
    expect(store.isAri, isFalse);
    expect(store.changes.value, greaterThan(changes));

    // Liderlik tablosundaki "leave" de oyuncuyu unutturur ve bildirir.
    store.me = 2;
    changes = store.changes.value;
    store.forgetPlayer();
    expect(store.isAri, isFalse);
    expect(store.changes.value, changes + 1);
  });
}
