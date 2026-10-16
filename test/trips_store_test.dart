import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/countdown/trips_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes are throttled, single-flight and writes update the list',
      () async {
    final store = TripsStore.instance;
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
    expect(calls, ['trips']);
    expect(store.connected, isTrue);
    expect(store.trips.single.sentence, "ari'nin İstanbul'a gelmesine");

    // App resumes within a minute → no request; after a minute → one.
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['trips']);
    now = now.add(const Duration(seconds: 61));
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['trips', 'trips']);

    // Adding uses the list the server returns (no extra fetch).
    final changes = store.changes.value;
    await store.add('Ankara', DateTime(2026, 11, 1));
    expect(calls, ['trips', 'trips', 'tripAdd']);
    expect(store.trips.map((t) => t.destination), ['İstanbul', 'Ankara']);
    expect(store.changes.value, greaterThan(changes));
  });
}
