import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/profile/profile_avatar.dart';
import 'package:hukuk_reels/features/profile/profile_settings_screen.dart';

const _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'flower_surprise_seen_v2': true});
    await ProgressService.instance.init();
  });

  // Her test temiz profil ile başlar (önceki test yarıda kalsa bile).
  setUp(() async {
    await ProgressService.instance.setAvatarDataUrl(null);
    await ProgressService.instance.setNick(null);
  });

  test('avatar and nick persist, validate input and survive reset', () async {
    final p = ProgressService.instance;
    final prefs = await SharedPreferences.getInstance();
    expect(await p.setAvatarDataUrl('not an image'), isFalse);
    expect(p.avatar, isNull);
    expect(await p.setAvatarDataUrl(_png), isTrue);
    expect(p.avatar, isNotNull);
    expect(prefs.getString('profile_avatar_v1'), isNotEmpty);
    await p.setNick('  ari  ');
    expect(p.nick, 'ari');
    await p.resetAll();
    expect(p.avatar, isNotNull, reason: 'profile is kept by reset');
    expect(p.nick, 'ari');
    expect(await p.setAvatarDataUrl(null), isTrue);
    expect(p.avatar, isNull);
    expect(prefs.getString('profile_avatar_v1'), isNull);
    await p.setNick(null);
    expect(p.nick, isNull);
  });

  for (final size in const [Size(393, 852), Size(320, 568)]) {
    testWidgets('profile & settings lays out on $size', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = size * 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await ProgressService.instance.setNick('mqcan 😎');
      await ProgressService.instance.setAvatarDataUrl(_png);
      await tester.pumpWidget(
          const MaterialApp(home: ProfileSettingsScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('mqcan 😎'), findsOneWidget);
      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(find.text('Profil & Ayarlar'), findsOneWidget);
      // Scroll through every section; any overflow throws.
      for (final label in [
        'İLERLEME',
        'SORULAR',
        'SES',
        'İkimizin sıralaması',
        'Her şeyi sıfırla',
        'Sendeyiz Arifecim 🫂',
      ]) {
        await tester.scrollUntilVisible(find.text(label), 200,
            scrollable: find.byType(Scrollable).first);
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('nick editing explains how to join when not connected',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Takma ad yok'), findsOneWidget);
    await tester.tap(find.byTooltip('Takma adı değiştir'));
    await tester.pumpAndSettle();
    expect(find.text('Takma ad sıralamadan gelir'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset dialogs keep their confirmations', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileSettingsScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(find.text('Her şeyi sıfırla'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Her şeyi sıfırla'));
    await tester.pumpAndSettle();
    expect(find.text('Her şey sıfırlansın mı?'), findsOneWidget);
    expect(find.textContaining('Profil fotoğrafın ve takma adın korunur'),
        findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Her şey sıfırlansın mı?'), findsNothing);
  });
}
