import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';
import 'package:hukuk_reels/features/reels/screens/reels_screen.dart';

void main() {
  testWidgets('reel swipes update the header and persist the latest page',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();

    await tester.pumpWidget(const MaterialApp(home: ReelsScreen()));
    await tester.pumpAndSettle();

    final total = ProgressService.instance.loadSession()!.questions.length;
    expect(find.text('1 / $total'), findsOneWidget);

    final page = tester.getRect(find.byType(PageView));
    await tester.dragFrom(
      Offset(page.center.dx, page.bottom - 28),
      Offset(0, -page.height * 0.75),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / $total'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(ProgressService.instance.loadSession()!.page, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
