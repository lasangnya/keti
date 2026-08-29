import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/test_mode/test_mode_provider.dart';
import 'package:keti/domain/study/reminder_content_resolver.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  const resolver = ReminderContentResolver();

  group('ReminderContentResolver — asset matrix', () {
    test('ambient break uses dedicated cursor and notch assets', () {
      final resolved = resolver.resolve(ReminderKind.microBreak, PresentationStyle.ambient);
      final c = resolved.content;
      expect(c.message, 'Time for a break');
      expect(c.cursorResource, 'ambient_break_cursor_pill');
      expect(c.notchResource, 'ambient_break_notch_card');
      expect(c.trayResource, 'ambient_break_cursor_pill');
      expect((c.cursorWidth, c.cursorHeight), (48.0, 48.0));
      expect((c.cursorOffsetX, c.cursorOffsetY), (12.0, -24.0));
      expect((c.notchWidth, c.notchHeight), (400.0, 100.0));
      expect((c.trayWidth, c.trayHeight), (22.0, 22.0));
      expect(c.totalFrames, 250);
      expect(resolved.fallbackPlacements, {Placement.systemTray});
    });

    test('ambient hydration uses dedicated cursor and notch assets', () {
      final resolved = resolver.resolve(ReminderKind.hydration, PresentationStyle.ambient);
      final c = resolved.content;
      expect(c.message, 'Stay hydrated');
      expect(c.cursorResource, 'ambient_hydration_cursor_pill');
      expect(c.notchResource, 'ambient_hydration_notch_card');
      expect(c.trayResource, 'ambient_hydration_cursor_pill');
      expect((c.cursorWidth, c.cursorHeight), (48.0, 48.0));
      expect((c.cursorOffsetX, c.cursorOffsetY), (12.0, -24.0));
      expect((c.notchWidth, c.notchHeight), (400.0, 100.0));
      expect((c.trayWidth, c.trayHeight), (22.0, 22.0));
      expect(c.totalFrames, 250);
      expect(resolved.fallbackPlacements, {Placement.systemTray});
    });

    test('character break reuses the cursor asset everywhere (fallback logged)', () {
      final resolved =
          resolver.resolve(ReminderKind.microBreak, PresentationStyle.characterBased);
      final c = resolved.content;
      expect(c.message, 'Keti needs a stretch!');
      expect(c.cursorResource, 'character_break_cursor_pill');
      expect(c.notchResource, 'character_break_cursor_pill');
      expect(c.trayResource, 'character_break_cursor_pill');
      expect((c.cursorWidth, c.cursorHeight), (80.0, 80.0));
      expect((c.notchWidth, c.notchHeight), (250.0, 250.0));
      expect((c.trayWidth, c.trayHeight), (22.0, 22.0));
      expect(c.totalFrames, 250);
      expect(resolved.fallbackPlacements,
          {Placement.notchCard, Placement.systemTray});
    });

    test('character hydration reuses the cursor asset everywhere (fallback logged)', () {
      final resolved =
          resolver.resolve(ReminderKind.hydration, PresentationStyle.characterBased);
      final c = resolved.content;
      expect(c.message, 'Drink water with Keti!');
      expect(c.cursorResource, 'character_hydration_cursor_pill');
      expect(c.notchResource, 'character_hydration_cursor_pill');
      expect(c.trayResource, 'character_hydration_cursor_pill');
      expect(c.totalFrames, 250);
      expect(resolved.fallbackPlacements,
          {Placement.notchCard, Placement.systemTray});
    });

    test('isFallback reports per placement', () {
      final resolved = resolver.resolve(ReminderKind.hydration, PresentationStyle.ambient);
      expect(resolved.isFallback(Placement.systemTray), isTrue);
      expect(resolved.isFallback(Placement.cursorProximate), isFalse);
      expect(resolved.isFallback(Placement.notchCard), isFalse);
    });
  });

  group('TestMode provider delegates to the resolver (behavior preserved)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('ambient style matches resolver output', () {
      final notifier = container.read(testModeProvider.notifier);
      notifier.setStyle('ambient');
      expect(
        notifier.getBreakContent().message,
        resolver
            .resolve(ReminderKind.microBreak, PresentationStyle.ambient)
            .content
            .message,
      );
      expect(notifier.getHydrationContent().notchResource,
          'ambient_hydration_notch_card');
    });

    test('character style matches resolver output', () {
      final notifier = container.read(testModeProvider.notifier);
      notifier.setStyle('character');
      expect(notifier.getBreakContent().cursorResource,
          'character_break_cursor_pill');
      expect(
        (notifier.getHydrationContent().notchWidth,
            notifier.getHydrationContent().notchHeight),
        (250.0, 250.0),
      );
    });

    test('notchPreset override still works for test-mode experiments', () {
      final notifier = container.read(testModeProvider.notifier);
      notifier.setStyle('character');
      final overridden = notifier.getBreakContent(notchPreset: 'wide-shallow');
      expect((overridden.notchWidth, overridden.notchHeight), (600.0, 150.0));
      // …while everything else stays resolver-driven.
      expect(overridden.cursorResource, 'character_break_cursor_pill');
    });
  });
}
