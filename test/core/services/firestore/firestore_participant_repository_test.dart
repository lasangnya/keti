import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/firestore/firestore_participant_repository.dart';
import 'package:keti/core/services/study/participant_repository.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreParticipantRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreParticipantRepository(firestore);
  });

  Future<void> seed() async {
    await firestore.collection('participants').doc('P014').set({
      'participantCode': 'P014',
      'serial': 14,
      'styleOrder': 'CHARACTER_FIRST',
      'assignmentOverride': false,
      'activeDay': 1,
      'environment': 'study',
      'protocolVersion': '2026-08-v1',
    });
    await firestore.collection('config').doc('study').set({
      'protocolVersion': '2026-08-v1',
      'defaultSchedule':
          kDefaultScheduleTemplate.map((r) => r.toJson()).toList(),
    });
    await firestore.collection('links').doc('templates').set({
      'preStudy': null,
      'endOfDayType1': 'https://forms.example/ambient?pid={participantId}',
      'endOfDayType2': null,
      'final': null,
    });
    await firestore
        .collection('participants')
        .doc('P014')
        .collection('schedules')
        .doc('day1')
        .set({
      'dayId': 'day1',
      'dayNumber': 1,
      'reminders': kDefaultScheduleTemplate.map((r) => r.toJson()).toList(),
    });
  }

  test('fetchParticipant returns the document', () async {
    await seed();
    final participant = await repository.fetchParticipant('P014');
    expect(participant.serial, 14);
    expect(participant.styleOrder, StyleOrder.characterFirst);
    expect(participant.activeDay, 1);
  });

  test('fetchParticipant throws ParticipantNotFoundException when missing',
      () async {
    expect(() => repository.fetchParticipant('P999'),
        throwsA(isA<ParticipantNotFoundException>()));
  });

  test('fetchStudyConfig parses protocol and default schedule', () async {
    await seed();
    final config = await repository.fetchStudyConfig();
    expect(config.protocolVersion, '2026-08-v1');
    expect(config.defaultSchedule.length, 8);
  });

  test('fetchLinkTemplates returns the global templates', () async {
    await seed();
    final templates = await repository.fetchLinkTemplates();
    expect(templates.endOfDayType1, contains('{participantId}'));
    expect(templates.endOfDayType2, isNull);
  });

  test('fetchSchedule returns the day schedule with the supplied style',
      () async {
    await seed();
    final schedule = await repository.fetchSchedule('P014', 1,
        style: PresentationStyle.characterBased);
    expect(schedule.dayId, 'day1');
    expect(schedule.style, PresentationStyle.characterBased);
    expect(schedule.reminders, kDefaultScheduleTemplate);
  });

  test('fetchSchedule throws ScheduleNotFoundException when the day doc is missing',
      () async {
    await seed();
    expect(
      () => repository.fetchSchedule('P014', 2,
          style: PresentationStyle.ambient),
      throwsA(isA<ScheduleNotFoundException>()),
    );
  });
}
