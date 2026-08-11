import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/admin/admin_repository.dart';
import 'package:keti/domain/study/study_session.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreAdminRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreAdminRepository(firestore);
  });

  Future<void> seedParticipant({int activeDay = 1}) async {
    await firestore.collection('participants').doc('P001').set({
      'participantCode': 'P001',
      'serial': 1,
      'styleOrder': 'AMBIENT_FIRST',
      'assignmentOverride': false,
      'activeDay': activeDay,
      'environment': 'dev',
      'protocolVersion': '2026-08-v1',
    });
  }

  Future<void> seedDay1Session({StudySessionStatus status = StudySessionStatus.completed}) async {
    await firestore
        .collection('participants')
        .doc('P001')
        .collection('studySessions')
        .doc('day1')
        .set({
      'dayId': 'day1',
      'dayNumber': 1,
      'participantCode': 'P001',
      'style': 'AMBIENT',
      'status': status.wireName,
      'startedAtLocal': '2026-08-03T09:00:00+02:00',
      'resumedCount': 0,
      'scheduleSnapshot': [],
      'linksSnapshot': {},
    });
  }

  Future<Map<String, dynamic>?> participantDoc() async =>
      (await firestore.collection('participants').doc('P001').get()).data();

  test('reset Day 1 returns the gate to day 1 and stamps resetDay1At', () async {
    await seedParticipant(activeDay: 1);
    await seedDay1Session();

    await repository.resetDay('P001', 1);

    final doc = await participantDoc();
    expect(doc?['activeDay'], 1);
    expect(doc, containsPair('resetDay1At', isNotNull));
  });

  test('reset Day 2 keeps the gate at 2 when day 1 is still completed',
      () async {
    await seedParticipant(activeDay: 2);
    await seedDay1Session(status: StudySessionStatus.completed);
    await firestore
        .collection('participants')
        .doc('P001')
        .collection('studySessions')
        .doc('day2')
        .set({
      'dayId': 'day2',
      'dayNumber': 2,
      'participantCode': 'P001',
      'style': 'CHARACTER_BASED',
      'status': 'ACTIVE',
      'startedAtLocal': '2026-08-04T09:00:00+02:00',
      'resumedCount': 0,
    });

    await repository.resetDay('P001', 2);

    final doc = await participantDoc();
    expect(doc?['activeDay'], 2);
    expect(doc, containsPair('resetDay2At', isNotNull));
  });

  test(
      'reset Day 2 falls back to day 1 when day 1 was also reset (not completed)',
      () async {
    await seedParticipant(activeDay: 2);
    // Day 1 session does NOT exist → its completion gate is gone.
    await firestore
        .collection('participants')
        .doc('P001')
        .collection('studySessions')
        .doc('day2')
        .set({
      'dayId': 'day2',
      'dayNumber': 2,
      'participantCode': 'P001',
      'style': 'CHARACTER_BASED',
      'status': 'ACTIVE',
      'startedAtLocal': '2026-08-04T09:00:00+02:00',
      'resumedCount': 0,
    });

    await repository.resetDay('P001', 2);

    final doc = await participantDoc();
    expect(doc?['activeDay'], 1);
    expect(doc, containsPair('resetDay2At', isNotNull));
  });
}
