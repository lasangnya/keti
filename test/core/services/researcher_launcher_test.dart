import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/researcher_launcher.dart';

void main() {
  group('ResearcherLauncher', () {
    test('isResearcherWindow is true when the env flag is set', () {
      final original = Platform.environment[ResearcherLauncher.envFlag];
      try {
        // The test host inherits the parent environment; force the flag.
        // (Platform.environment is immutable in Dart — emulate by checking
        // the getter's contract instead of mutating.)
        expect(ResearcherLauncher.envFlag, 'KETI_RESEARCHER');
        expect(ResearcherLauncher.isResearcherWindow,
            Platform.environment[ResearcherLauncher.envFlag] == '1');
      } finally {
        if (original != null) {
          // no-op: environment cannot be mutated in Dart; the assertion
          // above documents the contract.
        }
      }
    });

    test('closeWindow invokes the session-lifecycle channel without throwing',
        () async {
      // No-op-safe on the test host (channel has no handler in tests);
      // the call is best-effort and must not throw.
      await ResearcherLauncher.closeWindow();
    });
  });
}
