import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/firestore/reminder_event_repository.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreReminderEventRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreReminderEventRepository(firestore);
  });

  List<ReminderEvent> buildEvents() => [
        for (final reminder in kDefaultScheduleTemplate)
          ReminderEvent.scheduled(
            participantCode: 'P014',
            dayNumber: 1,
            reminder: reminder,
            style: PresentationStyle.characterBased,
            sessionStartLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
            environment: 'study',
            appVersion: '1.0.0+1',
            protocolVersion: '2026-08-v1',
          ),
      ];

  test('createScheduledEvents writes all 8 docs with deterministic ids',
      () async {
    await repository.createScheduledEvents('P014', 'day1', buildEvents());
    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .collection('reminderEvents')
        .get();
    expect(snap.docs.length, 8);
    expect(snap.docs.map((d) => d.id).toList()..sort(),
        List.generate(8, (i) => 'reminder0${i + 1}'));
    expect(snap.docs.first.data()['deliveryStatus'], 'SCHEDULED');
  });

  test('getEvents returns events ordered by reminderNumber', () async {
    await repository.createScheduledEvents('P014', 'day1', buildEvents());
    final events = await repository.getEvents('P014', 'day1');
    expect(events.map((e) => e.reminderNumber).toList(), [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('updateEventLifecycle updates outcome fields only', () async {
    final events = buildEvents();
    await repository.createScheduledEvents('P014', 'day1', events);

    final answered = events[3]
        .markDelivered(
          shownAtLocal: DateTime.parse('2026-08-03T10:02:13+02:00'),
          latenessMs: 1830,
        )
        .markCardShown(DateTime.parse('2026-08-03T10:02:58+02:00'))
        .markAnswered(
          outcome: ResponseOutcome.completed,
          answeredAtLocal: DateTime.parse('2026-08-03T10:03:05+02:00'),
          cardResponse: 'Done',
        );
    await repository.updateEventLifecycle('P014', 'day1', answered);

    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .collection('reminderEvents')
        .doc('reminder04')
        .get();
    final data = snap.data()!;
    expect(data['outcome'], 'COMPLETED');
    expect(data['cardResponse'], 'Done');
    expect(data['responseLatencyMs'], 7000);
    expect(data['deliveryStatus'], 'DELIVERED');
    expect(data['updatedAt'], isNotNull);
    expect(data['answeredAt'], isNotNull);
    // Condition fields untouched.
    expect(data['placement'], 'CURSOR_PROXIMATE');
    expect(data['style'], 'CHARACTER_BASED');
    expect(data['reminderNumber'], 4);
  });

  test('updateEventLifecycle persists the Ignored label on card timeout',
      () async {
    final events = buildEvents();
    await repository.createScheduledEvents('P014', 'day1', events);

    final timedOut = events[5]
        .markDelivered(
          shownAtLocal: DateTime.parse('2026-08-03T10:02:13+02:00'),
          latenessMs: 900,
        )
        .markCardShown(DateTime.parse('2026-08-03T10:02:58+02:00'))
        .markTimedOut(DateTime.parse('2026-08-03T10:03:13+02:00'));
    await repository.updateEventLifecycle('P014', 'day1', timedOut);

    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .collection('reminderEvents')
        .doc('reminder06')
        .get();
    final data = snap.data()!;
    expect(data['outcome'], 'TIMED_OUT');
    expect(data['cardResponse'], 'Ignored');
  });

  test('scheduled event update carries no server show/answer stamps', () async {
    final events = buildEvents();
    await repository.createScheduledEvents('P014', 'day1', events);
    await repository.updateEventLifecycle(
        'P014', 'day1', events[0].markSuppressed('late_delivery'));

    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .collection('reminderEvents')
        .doc('reminder01')
        .get();
    expect(snap.data()!['deliveryStatus'], 'SUPPRESSED');
    expect(snap.data()!['suppressionReason'], 'late_delivery');
    expect(snap.data()!.containsKey('reminderShownAt'), isFalse);
    expect(snap.data()!.containsKey('answeredAt'), isFalse);
  });
}
