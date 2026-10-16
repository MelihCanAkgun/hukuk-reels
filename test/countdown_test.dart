import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/features/countdown/countdown_screen.dart';
import 'package:hukuk_reels/features/countdown/countdown_text.dart';

void main() {
  test('Turkish genitive follows vowel harmony and ignores emoji', () {
    expect(genitive('ari'), "ari'nin");
    expect(genitive('mqcan 😎'), "mqcan'ın");
    expect(genitive('Melih'), "Melih'in");
    expect(genitive('Doğu'), "Doğu'nun");
    expect(genitive('Gül'), "Gül'ün");
    expect(genitive('Arife 🌷'), "Arife'nin");
    expect(genitive('KUZU'), "KUZU'nun");
  });

  test('Turkish dative follows vowel harmony and buffer y', () {
    expect(dative('İstanbul'), "İstanbul'a");
    expect(dative('İzmir'), "İzmir'e");
    expect(dative('Ankara'), "Ankara'ya");
    expect(dative('Berlin'), "Berlin'e");
    expect(dative('Bursa'), "Bursa'ya");
    expect(dative('Eskişehir'), "Eskişehir'e");
    expect(dative('Köln'), "Köln'e");
    expect(dative('New York'), "New York'a");
    expect(tripSentence('ari', 'İstanbul'), "ari'nin İstanbul'a gelmesine");
  });

  test('remaining time shows days and hours, never seconds', () {
    expect(
        remainingText(
            const Duration(days: 12, hours: 5, minutes: 59, seconds: 59)),
        '12 gün 5 saat');
    expect(remainingText(const Duration(days: 3)), '3 gün');
    expect(remainingText(const Duration(hours: 7, minutes: 30)), '7 saat');
    expect(remainingText(const Duration(minutes: 20)), '1 saatten az');
    expect(remainingText(Duration.zero), isNull);
    expect(remainingText(const Duration(minutes: -5)), isNull);
  });

  test('dates are written in Turkish', () {
    final t = DateTime(2026, 11, 20, 9, 5); // Cuma
    expect(arrivalText(t), '20 Kasım Cuma · 09:05');
    expect(dateText(t), '20 Kasım 2026');
  });

  test('trips parse from the server and the plane moves with time', () {
    final created = DateTime(2026, 10, 1).millisecondsSinceEpoch ~/ 1000;
    final arrival = DateTime(2026, 10, 11).millisecondsSinceEpoch ~/ 1000;
    final trips = parseTrips({
      'trips': [
        {
          'id': 3,
          'player': 2,
          'name': 'ari',
          'destination': 'İstanbul',
          'arrival': arrival,
          'created': created
        },
      ],
    });
    expect(trips.single.sentence, "ari'nin İstanbul'a gelmesine");
    expect(trips.single.progress(DateTime(2026, 9, 1)), 0);
    expect(trips.single.progress(DateTime(2026, 10, 6)), closeTo(0.5, 0.01));
    expect(trips.single.progress(DateTime(2026, 12, 1)), 1);
  });
}
