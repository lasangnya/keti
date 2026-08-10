import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/presentation/pages/home/home_page.dart';
import 'package:keti/presentation/pages/study/study_page.dart';

import '../../../helpers/firebase_mock.dart';

void main() {
  setUpAll(initFirebaseForTest);

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: KetiHomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('participant shell has no side panel', (tester) async {
    await pumpHome(tester);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(StudyPage), findsOneWidget);
  });

  testWidgets('researcher access entry is pinned bottom-right', (tester) async {
    await pumpHome(tester);
    expect(find.text('Researcher Access'), findsOneWidget);
    final element = tester.element(find.widgetWithText(TextButton, 'Researcher Access'));
    final align = element.findAncestorWidgetOfExactType<Align>();
    expect(align, isNotNull);
    expect(align!.alignment, Alignment.bottomRight);
  });
}
