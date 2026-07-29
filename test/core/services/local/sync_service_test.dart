import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/firestore/reminder_event_repository.dart';
import 'package:keti/core/services/firestore/session_repository.dart';
import 'package:keti/core/services/local/csv_store.dart';
import 'package:keti/core/services/local/sync_service.dart';
import 'package:keti/core/services/study/mock_participant_repository.dart';
import 'package:keti/core/services/study/participant_repository.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';

import '../../../application/study/session_test_fakes.dart';

void main() {
  late Directory csvRoot;
  late CsvStore csvStore;
  late FakeSessionRepository sessionRepo;
  late FakeEventRepository eventRepo;
  late ParticipantRepository participantRepo;
  late SyncService syncService;

  setUp(() {
    csvRoot = Directory.systemTemp.createTempSync('keti_sync_test');
    csvStore = CsvStore(rootDir: csvRoot);
    sessionRepo = FakeSessionRepository();
    eventRepo = FakeEventRepository();
    participantRepo = MockParticipantRepository(); // unused — sync doesn't take it
    syncService = SyncService(
      csvStore: csvStore,
      sessionRepo: sessionRepo,
      eventRepo: eventRepo,
    );
  });

  tearDown(() {
    if (csvRoot.existsSync()) csvRoot.deleteSync(recursive: true);
  });

  List<ReminderEvent> buildEvents({
    String code = 'P001',
    int dayNumber = 1,
    DateTime? start,
  }) =>
      [
        for (final reminder in kDefaultScheduleTemplate)
          ReminderEvent.scheduled(
            participantCode: code,
            dayNumber: dayNumber,
            reminder: reminder,
            style: PresentationStyle.ambient,
            sessionStartLocal:
                start ?? DateTime.parse('2026-08-03T09:02:11+02:00'),
            environment: 'study',
            appVersion: '1.0.0+1',
            protocolVersion: '2026-08-v1',
          ),
      ];

  StudySession buildSession({String code = 'P001', int day = 1}) =>
      StudySession(
        participantCode: code,
        dayNumber: day,
        style: PresentationStyle.ambient,
        status: StudySessionStatus.active,
        startedAtLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
        schedule: DaySchedule(
          dayNumber: day,
          style: PresentationStyle.ambient,
          reminders: kDefaultScheduleTemplate,
        ),
        links: const QuestionnaireLinks(),
      );

  test('reconcile escapes quickly when there is no local session', () async {
    final result = await syncService.reconcileParticipant('P099');
    expect(result.synced, 0);
    expect(result.failed, 0);
  });

  test('backfills missing session + events when Firestore is empty',
      () async {
    await csvStore.writeSession(buildSession());
    await csvStore.writeEvents('P001', 'day1', buildEvents());

    final result = await syncService.reconcileParticipant('P001');

    expect(result.failed, 0);
    expect(result.synced, greaterThanOrEqualTo(8));
    expect(sessionRepo.createCalls, 1);
    expect(eventRepo.createCalls, 1);
    expect(eventRepo.created, hasLength(8));
  });

  test('updates lifecycle when the local copy is ahead', () async {
    // Pre-seed Firestore with scheduled events (like an online start).
    await sessionRepo.createSession(buildSession());
    await eventRepo.createScheduledEvents('P001', 'day1', buildEvents());
    // Locally, one event was delivered late.
    final events = buildEvents();
    events[0] = events[0].markDelivered(
      shownAtLocal: DateTime.parse('2026-08-03T09:22:12+02:00'),
      latenessMs: 900,
      usedFallback: true,
    );
    await csvStore.writeSession(buildSession());
    await csvStore.writeEvents('P001', 'day1', events);

    final result = await syncService.reconcileParticipant('P001');

    expect(result.failed, 0);
    expect(result.synced, 1);
    expect(eventRepo.updated.single.deliveryStatus, DeliveryStatus.delivered);
    expect(eventRepo.updated.single.usedFallback, isTrue);
  });

  test('backfills session completion status', () async {
    await csvStore.writeSession(
        buildSession().copyWith(status: StudySessionStatus.completed));
    final events = buildEvents();
    // Mark all as finalized so the test is coherent.
    for (var i = 0; i < events.length; i++) {
      events[i] = events[i].markSuppressed('late_delivery');
    }
    await csvStore.writeEvents('P001', 'day1', events);

    final result = await syncService.reconcileParticipant('P001');

    expect(sessionRepo.createCalls, 1);
    expect(result.failed, 0);
  });
}
