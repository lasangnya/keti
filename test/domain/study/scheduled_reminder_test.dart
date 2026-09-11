import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  group('kDefaultScheduleTemplate (study protocol table)', () {
    test('has exactly 8 reminders numbered 1–8 in order', () {
      expect(kDefaultScheduleTemplate.length, 8);
      for (var i = 0; i < 8; i++) {
        expect(kDefaultScheduleTemplate[i].reminderNumber, i + 1);
      }
    });

    test('offsets match the protocol (minutes from session start)', () {
      const expectedMinutes = [20, 30, 40, 60, 65, 80, 90, 100];
      final actual = kDefaultScheduleTemplate
          .map((r) => r.offset.inMinutes)
          .toList();
      expect(actual, expectedMinutes);
    });

    test('placements match the protocol table', () {
      const expected = [
        Placement.cursorProximate,
        Placement.notchCard,
        Placement.systemTray,
        Placement.cursorProximate,
        Placement.notchCard,
        Placement.cursorProximate,
        Placement.systemTray,
        Placement.systemTray,
      ];
      expect(kDefaultScheduleTemplate.map((r) => r.placement).toList(), expected);
    });

    test('kinds and variant counters match the protocol table', () {
      final kinds = kDefaultScheduleTemplate.map((r) => r.kind).toList();
      expect(kinds, [
        ReminderKind.hydration,
        ReminderKind.microBreak,
        ReminderKind.hydration,
        ReminderKind.microBreak,
        ReminderKind.hydration,
        ReminderKind.hydration,
        ReminderKind.microBreak,
        ReminderKind.hydration,
      ]);

      final hydrationVariants = kDefaultScheduleTemplate
          .where((r) => r.kind == ReminderKind.hydration)
          .map((r) => r.variantNumber)
          .toList();
      expect(hydrationVariants, [1, 2, 3, 4, 5]);

      final breakVariants = kDefaultScheduleTemplate
          .where((r) => r.kind == ReminderKind.microBreak)
          .map((r) => r.variantNumber)
          .toList();
      expect(breakVariants, [1, 2, 3]);
    });

    test('contentVariantId format', () {
      expect(kDefaultScheduleTemplate[0].contentVariantId, 'hydration_1');
      expect(kDefaultScheduleTemplate[1].contentVariantId, 'micro_break_1');
      expect(kDefaultScheduleTemplate[7].contentVariantId, 'hydration_5');
    });
  });

  group('ScheduledReminder JSON', () {
    test('round-trips every template entry', () {
      for (final reminder in kDefaultScheduleTemplate) {
        final restored = ScheduledReminder.fromJson(reminder.toJson());
        expect(restored, reminder);
      }
    });

    test('uses the Firestore field names', () {
      final json = kDefaultScheduleTemplate[0].toJson();
      expect(json, {
        'n': 1,
        'offsetSec': 1200,
        'placement': 'CURSOR_PROXIMATE',
        'kind': 'HYDRATION',
        'variant': 1,
      });
    });
  });

  group('DaySchedule', () {
    test('dayId derives from dayNumber', () {
      final schedule = DaySchedule(
        dayNumber: 2,
        style: PresentationStyle.ambient,
        reminders: kDefaultScheduleTemplate,
      );
      expect(schedule.dayId, 'day2');
    });

    test('JSON round-trip preserves day and reminders', () {
      final original = DaySchedule(
        dayNumber: 1,
        style: PresentationStyle.characterBased,
        reminders: kDefaultScheduleTemplate,
      );
      final restored = DaySchedule.fromJson(original.toJson(),
          style: PresentationStyle.characterBased);
      expect(restored.dayNumber, 1);
      expect(restored.style, PresentationStyle.characterBased);
      expect(restored.reminders, kDefaultScheduleTemplate);
    });
  });

  group('variant selection helpers', () {
    test('baseVariantCountFor returns 5 hydration / 3 micro break', () {
      expect(baseVariantCountFor(ReminderKind.hydration), 5);
      expect(baseVariantCountFor(ReminderKind.microBreak), 3);
    });

    test('variantCeilingFor returns base when highestUsed <= base', () {
      expect(variantCeilingFor(ReminderKind.hydration), 5);
      expect(variantCeilingFor(ReminderKind.microBreak), 3);
      expect(variantCeilingFor(ReminderKind.hydration, highestUsed: 3), 5);
      expect(variantCeilingFor(ReminderKind.microBreak, highestUsed: 2), 3);
    });

    test('variantCeilingFor returns highestUsed when it exceeds base', () {
      expect(variantCeilingFor(ReminderKind.hydration, highestUsed: 8), 8);
      expect(variantCeilingFor(ReminderKind.microBreak, highestUsed: 4), 4);
      expect(variantCeilingFor(ReminderKind.hydration, highestUsed: 5), 5);
      expect(variantCeilingFor(ReminderKind.microBreak, highestUsed: 3), 3);
    });

    test('availableVariantsFor lists 1..ceiling per kind', () {
      expect(availableVariantsFor(ReminderKind.hydration), [1, 2, 3, 4, 5]);
      expect(availableVariantsFor(ReminderKind.microBreak), [1, 2, 3]);
      expect(
        availableVariantsFor(ReminderKind.hydration, highestUsed: 7),
        [1, 2, 3, 4, 5, 6, 7],
      );
      expect(
        availableVariantsFor(ReminderKind.microBreak, highestUsed: 6),
        [1, 2, 3, 4, 5, 6],
      );
    });

    test('highestVariantByKind computes per-kind maxima', () {
      final reminders = [
        ScheduledReminder(
          reminderNumber: 1,
          offset: Duration.zero,
          placement: Placement.cursorProximate,
          kind: ReminderKind.hydration,
          variantNumber: 2,
        ),
        ScheduledReminder(
          reminderNumber: 2,
          offset: Duration.zero,
          placement: Placement.cursorProximate,
          kind: ReminderKind.hydration,
          variantNumber: 6,
        ),
        ScheduledReminder(
          reminderNumber: 3,
          offset: Duration.zero,
          placement: Placement.cursorProximate,
          kind: ReminderKind.microBreak,
          variantNumber: 4,
        ),
      ];
      expect(highestVariantByKind(reminders), {
        ReminderKind.hydration: 6,
        ReminderKind.microBreak: 4,
      });
    });

    test('highestVariantByKind returns empty map for empty input', () {
      expect(highestVariantByKind([]), {});
    });
  });
}
