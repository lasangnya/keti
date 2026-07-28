import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/firestore/session_repository.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreSessionRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreSessionRepository(firestore);
  });

  StudySession buildSession() => StudySession(
        participantCode: 'P014',
        dayNumber: 1,
        style: PresentationStyle.characterBased,
        status: StudySessionStatus.active,
        startedAtLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
        schedule: const DaySchedule(
          dayNumber: 1,
          style: PresentationStyle.characterBased,
          reminders: kDefaultScheduleTemplate,
        ),
        links: const QuestionnaireLinks(
            day1End: 'https://forms.example/end?pid={participantId}'),
      );

  test('createSession writes the document with audit and server fields',
      () async {
    await repository.createSession(buildSession());
    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .get();
    expect(snap.exists, isTrue);
    expect(snap.data()!['status'], 'ACTIVE');
    expect(snap.data()!['appVersion'], isNotNull);
    expect(snap.data()!['protocolVersion'], '2026-08-v1');
    expect(snap.data()!['startedAt'], isNotNull); // serverTimestamp materialized
  });

  test('getSession round-trips the snapshot', () async {
    await repository.createSession(buildSession());
    final restored = await repository.getSession('P014', 'day1');
    expect(restored, isNotNull);
    expect(restored!.participantCode, 'P014');
    expect(restored.schedule.reminders, kDefaultScheduleTemplate);
    expect(restored.links.day1End, contains('{participantId}'));
  });

  test('getSession returns null when missing', () async {
    expect(await repository.getSession('P014', 'day2'), isNull);
  });

  test('markSessionResumed increments resumedCount', () async {
    await repository.createSession(buildSession());
    await repository.markSessionResumed('P014', 'day1');
    await repository.markSessionResumed('P014', 'day1');
    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .get();
    expect(snap.data()!['resumedCount'], 2);
  });

  test('completeSession sets status and completedAt', () async {
    await repository.createSession(buildSession());
    await repository.completeSession('P014', 'day1');
    final snap = await firestore
        .collection('participants')
        .doc('P014')
        .collection('studySessions')
        .doc('day1')
        .get();
    expect(snap.data()!['status'], 'COMPLETED');
    expect(snap.data()!['completedAt'], isNotNull);
  });
}
