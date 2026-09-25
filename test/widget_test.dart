import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_score_board/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Typical phone viewport (iPhone 14/15-sized) instead of the 800x600 default.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MyApp), findsOneWidget);
  });
}
