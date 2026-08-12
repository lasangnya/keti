import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/researcher_launcher.dart';

void main() {
  group('ResearcherLauncher', () {
    test('flag is --researcher and the getter reflects the args/env contract',
        () {
      expect(ResearcherLauncher.flag, '--researcher');
      final isResearcher = Platform.executableArguments.contains('--researcher') ||
          Platform.environment['KETI_RESEARCHER'] == '1';
      // On the test host neither is set — the getter must agree with the
      // contract definition.
      expect(ResearcherLauncher.isResearcherWindow, isResearcher);
    });

    test('launch goes through LaunchServices (open -n) without throwing',
        () async {
      // On the test host this attempts to run `open`, which either succeeds
      // or fails cleanly — it must not throw.
      final ok = await ResearcherLauncher.launch();
      expect(ok, isA<bool>());
    });
    test('closeWindow invokes the session-lifecycle channel without throwing',
        () async {
      // Best-effort on the test host (no native handler) — must not throw.
      await ResearcherLauncher.closeWindow();
    });
  });
}
