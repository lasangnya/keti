import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/csv_codec.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_enums.dart';

ReminderEvent buildScheduledEvent() => ReminderEvent.scheduled(
      participantCode: 'P014',
      dayNumber: 1,
      reminder: kDefaultScheduleTemplate[3], // reminder 4
      style: PresentationStyle.characterBased,
      sessionStartLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
      environment: 'study',
      appVersion: '1.0.0+2',
      protocolVersion: '2026-08-v1',
    );

void main() {
  group('ReminderEvent.scheduled', () {
    test('derives identity, schedule and condition from the reminder row', () {
      final event = buildScheduledEvent();
      expect(event.eventId, 'reminder04');
      expect(event.participantCode, 'P014');
      expect(event.dayId, 'day1');
      expect(event.dayNumber, 1);
      expect(event.reminderNumber, 4);
      expect(event.scheduledOffsetSec, 3600);
      expect(event.scheduledAtLocal,
          DateTime.parse('2026-08-03T10:02:11+02:00'));
      expect(event.placement, Placement.cursorProximate);
      expect(event.style, PresentationStyle.characterBased);
      expect(event.reminderKind, ReminderKind.microBreak);
      expect(event.contentVariantId, 'micro_break_2');
      expect(event.deliveryStatus, DeliveryStatus.scheduled);
      expect(event.outcome, ResponseOutcome.none);
      expect(event.usedFallback, isFalse);
      expect(event.sessionResumed, isFalse);
    });

    test('pads the event id to two digits', () {
      final event8 = ReminderEvent.scheduled(
        participantCode: 'P001',
        dayNumber: 2,
        reminder: kDefaultScheduleTemplate[7],
        style: PresentationStyle.ambient,
        sessionStartLocal: DateTime.parse('2026-08-03T09:00:00'),
        environment: 'study',
        appVersion: '1.0.0+2',
        protocolVersion: '2026-08-v1',
      );
      expect(event8.eventId, 'reminder08');
    });
  });

  group('lifecycle transitions', () {
    test('markDelivered records status, timestamp and lateness', () {
      final event = buildScheduledEvent().markDelivered(
        shownAtLocal: DateTime.parse('2026-08-03T10:02:13+02:00'),
        latenessMs: 1830,
        usedFallback: true,
      );
      expect(event.deliveryStatus, DeliveryStatus.delivered);
      expect(event.reminderShownAtLocal,
          DateTime.parse('2026-08-03T10:02:13+02:00'));
      expect(event.deliveryLatenessMs, 1830);
      expect(event.usedFallback, isTrue);
    });

    test('markAnswered computes latency from the card-shown timestamp', () {
      final event = buildScheduledEvent()
          .markDelivered(
            shownAtLocal: DateTime.parse('2026-08-03T10:02:13+02:00'),
            latenessMs: 1830,
          )
          .markReminderHidden(DateTime.parse('2026-08-03T10:02:58+02:00'))
          .markCardShown(DateTime.parse('2026-08-03T10:02:58+02:00'))
          .markAnswered(
            outcome: ResponseOutcome.completed,
            answeredAtLocal: DateTime.parse('2026-08-03T10:03:05.120+02:00'),
          );
      expect(event.outcome, ResponseOutcome.completed);
      expect(event.responseLatencyMs, 7120);
    });

    test('markTimedOut sets the timeout outcome without latency', () {
      final event = buildScheduledEvent()
          .markCardShown(DateTime.parse('2026-08-03T10:02:58+02:00'))
          .markTimedOut(DateTime.parse('2026-08-03T10:04:58+02:00'));
      expect(event.outcome, ResponseOutcome.timedOut);
      expect(event.responseLatencyMs, isNull);
    });

    test('failure and suppression paths set status plus reason', () {
      final failed = buildScheduledEvent().markFailed('platform_exception:channel');
      expect(failed.deliveryStatus, DeliveryStatus.failed);
      expect(failed.failureReason, 'platform_exception:channel');

      final suppressed =
          buildScheduledEvent().markSuppressed('late_delivery');
      expect(suppressed.deliveryStatus, DeliveryStatus.suppressed);
      expect(suppressed.suppressionReason, 'late_delivery');

      final notShown =
          buildScheduledEvent().markNotDisplayed('app_terminated');
      expect(notShown.deliveryStatus, DeliveryStatus.notDisplayed);
      expect(notShown.suppressionReason, 'app_terminated');
    });
  });

  group('CSV', () {
    test('header is frozen in protocol order', () {
      expect(ReminderEvent.csvHeader, [
        'eventId',
        'participantCode',
        'dayId',
        'dayNumber',
        'reminderNumber',
        'scheduledOffsetSec',
        'scheduledAtLocal',
        'reminderShownAtLocal',
        'reminderHiddenAtLocal',
        'deliveryLatenessMs',
        'placement',
        'style',
        'reminderKind',
        'contentVariantId',
        'deliveryStatus',
        'failureReason',
        'suppressionReason',
        'usedFallback',
        'cardShownAtLocal',
        'outcome',
        'answeredAtLocal',
        'responseLatencyMs',
        'sessionResumed',
        'environment',
        'appVersion',
        'protocolVersion',
      ]);
    });

    test('row round-trips through the codec with nulls intact', () {
      final event = buildScheduledEvent();
      final text = CsvCodec.encode(ReminderEvent.csvHeader, [event.toCsvRow()]);
      final rows = CsvCodec.decode(text);
      expect(rows.length, 2); // header + 1 row
      final restored = ReminderEvent.fromCsvRow(rows[1]);
      expect(restored.toCsvRow().toString(), event.toCsvRow().toString());
      expect(restored.reminderShownAtLocal, isNull);
      expect(restored.failureReason, isNull);
    });

    test('row with commas and quotes in the failure reason survives', () {
      final event = buildScheduledEvent()
          .markFailed('platform_exception: channel "cursor_pill", busy');
      final text = CsvCodec.encode(ReminderEvent.csvHeader, [event.toCsvRow()]);
      final restored = ReminderEvent.fromCsvRow(CsvCodec.decode(text)[1]);
      expect(restored.failureReason,
          'platform_exception: channel "cursor_pill", busy');
    });

    test('full lifecycle row round-trips', () {
      final event = buildScheduledEvent()
          .markSessionResumed()
          .markDelivered(
            shownAtLocal: DateTime.parse('2026-08-03T10:02:13+02:00'),
            latenessMs: 1830,
          )
          .markReminderHidden(DateTime.parse('2026-08-03T10:02:58+02:00'))
          .markCardShown(DateTime.parse('2026-08-03T10:02:58+02:00'))
          .markAnswered(
            outcome: ResponseOutcome.dismissed,
            answeredAtLocal: DateTime.parse('2026-08-03T10:03:05+02:00'),
          );
      final text = CsvCodec.encode(ReminderEvent.csvHeader, [event.toCsvRow()]);
      final restored = ReminderEvent.fromCsvRow(CsvCodec.decode(text)[1]);
      expect(restored.toCsvRow().toString(), event.toCsvRow().toString());
      expect(restored.sessionResumed, isTrue);
      expect(restored.responseLatencyMs, 7000);
    });
  });

  group('JSON', () {
    test('round-trips a scheduled event', () {
      final event = buildScheduledEvent();
      final restored = ReminderEvent.fromJson(event.toJson());
      expect(restored.toJson(), event.toJson());
    });

    test('round-trips a fully answered event', () {
      final event = buildScheduledEvent()
          .markDelivered(
            shownAtLocal: DateTime.parse('2026-08-03T10:02:13+02:00'),
            latenessMs: 1830,
          )
          .markCardShown(DateTime.parse('2026-08-03T10:02:58+02:00'))
          .markAnswered(
            outcome: ResponseOutcome.completed,
            answeredAtLocal: DateTime.parse('2026-08-03T10:03:05+02:00'),
          );
      final restored = ReminderEvent.fromJson(event.toJson());
      expect(restored.toJson(), event.toJson());
    });

    test('uses the Firestore field names', () {
      final json = buildScheduledEvent().toJson();
      expect(json['eventId'], 'reminder04');
      expect(json['participantCode'], 'P014');
      expect(json['placement'], 'CURSOR_PROXIMATE');
      expect(json['style'], 'CHARACTER_BASED');
      expect(json['deliveryStatus'], 'SCHEDULED');
      expect(json['outcome'], 'NONE');
      expect(json['protocolVersion'], '2026-08-v1');
    });
  });
}
