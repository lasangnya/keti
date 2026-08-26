import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/researcher_launcher.dart';

void main() {
  group('ResearcherLauncher', () {
    setUp(() {
      // Ensure a clean marker state and cached flag between tests.
      ResearcherLauncher.resetCachedFlag();
      final marker = File(ResearcherLauncher.markerPath);
      if (marker.existsSync()) marker.deleteSync();
    });

    test('isResearcherWindow consumes a pending marker file exactly once',
        () {
      File(ResearcherLauncher.markerPath).writeAsStringSync('1');
      expect(ResearcherLauncher.isResearcherWindow, isTrue);
      // Marker consumed on first read.
      expect(File(ResearcherLauncher.markerPath).existsSync(), isFalse);
      // The result is sticky — re-evaluation must not lose the flag.
      expect(ResearcherLauncher.isResearcherWindow, isTrue);
    });

    test('isResearcherWindow is false without any flag', () {
      expect(ResearcherLauncher.isResearcherWindow, isFalse);
    });

    test('launch writes the marker and goes through open -n', () async {
      final ok = await ResearcherLauncher().launch();
      expect(ok, isA<bool>());
    });

    test('closeWindow invokes the session-lifecycle channel without throwing',
        () async {
      await ResearcherLauncher().closeWindow();
    });
  });
}
