import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/study/app_environment_provider.dart';
import 'package:keti/presentation/pages/home/home_page.dart';

import '../../../helpers/firebase_mock.dart';

void main() {
  setUpAll(initFirebaseForTest);

  Future<void> pumpHome(WidgetTester tester, String environment) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
        ],
        child: const MaterialApp(home: KetiHomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('study environment hides Test Mode from the rail',
      (tester) async {
    await pumpHome(tester, 'study');
    expect(find.text('Study'), findsWidgets);
    expect(find.text('Test Mode'), findsNothing);
  });

  testWidgets('dev environment shows Test Mode in the rail', (tester) async {
    await pumpHome(tester, 'dev');
    expect(find.text('Study'), findsWidgets);
    expect(find.text('Test Mode'), findsOneWidget);
  });

  testWidgets('pilot environment still shows Test Mode', (tester) async {
    await pumpHome(tester, 'pilot');
    expect(find.text('Test Mode'), findsOneWidget);
  });
}
