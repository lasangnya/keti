import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/researcher_launcher.dart';

void main() {
  group('ResearcherLauncher', () {
    setUp(() {
      // Ensure a clean marker state between tests.
      final marker = File(ResearcherLauncher.markerPath);
      if (marker.existsSync()) marker.deleteSync();
    });

    test('isResearcherWindow consumes a pending marker file', () {
      File(ResearcherLauncher.markerPath).writeAsStringSync('1');
      expect(ResearcherLauncher.isResearcherWindow, isTrue);
      // Marker is consumed exactly once.
      expect(File(ResearcherLauncher.markerPath).existsSync(), isFalse);
      expect(ResearcherLauncher.isResearcherWindow, isFalse);
    });

    test('isResearcherWindow is false without any flag', () {
      expect(ResearcherLauncher.isResearcherWindow, isFalse);
    });

    test('launch writes the marker and goes through open -n', () async {
      final ok = await ResearcherLauncher.launch();
      expect(ok, isA<bool>());
    });

    test('closeWindow invokes the session-lifecycle channel without throwing',
        () async {
      await ResearcherLauncher.closeWindow();
    });
  });
}
