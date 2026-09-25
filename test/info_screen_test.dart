import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_score_board/main.dart';

void main() {
  testWidgets('info screen links to privacy policy and imprint on the website', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    appLocaleNotifier.value = const Locale('de');
    await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
    await tester.pumpAndSettle();

    final privacy = find.byKey(const ValueKey('privacy_link'));
    final impressum = find.byKey(const ValueKey('impressum_link'));
    await tester.ensureVisible(privacy);
    await tester.pumpAndSettle();
    expect(find.descendant(of: privacy, matching: find.text('Datenschutz')), findsOneWidget);
    expect(find.descendant(of: impressum, matching: find.text('Impressum & Kontakt')), findsOneWidget);

    // Im Test gibt es keinen Browser: Antippen darf trotzdem nicht abstürzen
    await tester.tap(privacy);
    await tester.tap(impressum);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(privacyPolicyUrl, 'https://duschletta.me/countr/datenschutz.html');
    expect(impressumUrl, 'https://duschletta.me/impressum.html');
  });
}
