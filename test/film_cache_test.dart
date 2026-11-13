import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/films/film_store.dart';

Map<String, dynamic> _film(int id) => {
      'id': id,
      'tmdbId': 1000 + id,
      'title': 'Film $id',
      'genres': <String>[],
      'providers': <Map<String, dynamic>>[],
      'addedBy': 1,
      'added': 1794000000,
    };

void main() {
  test('önce önbellek gösterilir; değişmeyen yanıt ekranı yeniden kurmaz',
      () async {
    final store = FilmStore.instance;
    final calls = <Map<String, dynamic>>[];
    var changes = 0;
    store.changes.addListener(() => changes++);
    final replies = <Map<String, dynamic>>[
      // 1) Cihazdaki son kopya (ağ beklenmeden).
      {
        'films': [_film(1)],
        'connected': true,
        'cached': true,
        'me': 1
      },
      // 2) Sunucudaki liste aynı.
      {'unchanged': true, 'connected': true},
      // 3) Sonraki yenilemede yeni film var.
      {
        'films': [_film(1), _film(2)],
        'connected': true,
        'me': 1
      },
    ];
    store.call = (String action, [Map<String, dynamic> data = const {}]) async {
      calls.add({'action': action, ...data});
      return replies.removeAt(0);
    };

    await store.refresh(force: true);
    expect(calls, [
      {'action': 'films', 'cached': true},
      {'action': 'films', 'known': true},
    ]);
    expect(store.films.length, 1);
    expect(store.loaded, isTrue);
    // Yalnız önbellek uygulandı: tek bildirim.
    expect(changes, 1);

    await store.refresh(force: true);
    expect(calls.last, {'action': 'films', 'known': true});
    expect(store.films.length, 2);
    expect(changes, 2);
  });
}
