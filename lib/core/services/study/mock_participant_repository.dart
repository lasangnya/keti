import '../../../domain/study/day_schedule.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/scheduled_reminder.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_links.dart';
import 'participant_repository.dart';

/// In-memory [ParticipantRepository] used until M3 wires Firestore, and in
/// tests. Contains two fake participants covering both counterbalancing
/// orders and both day-activation states.
class MockParticipantRepository implements ParticipantRepository {
  MockParticipantRepository({Map<String, Participant>? participants})
      : _participants = participants ?? defaultParticipants;

  final Map<String, Participant> _participants;

  static final defaultParticipants = <String, Participant>{
    'P001': const Participant(
      participantCode: 'P001',
      serial: 1,
      styleOrder: StyleOrder.ambientFirst,
      assignmentOverride: false,
      activeDay: 1,
      environment: 'dev',
      protocolVersion: '2026-08-v1',
    ),
    'P002': const Participant(
      participantCode: 'P002',
      serial: 2,
      styleOrder: StyleOrder.characterFirst,
      assignmentOverride: false,
      activeDay: 2,
      environment: 'dev',
      protocolVersion: '2026-08-v1',
    ),
    'P003': const Participant(
      participantCode: 'P003',
      serial: 3,
      styleOrder: StyleOrder.ambientFirst,
      assignmentOverride: false,
      activeDay: 1,
      environment: 'dev',
      protocolVersion: '2026-08-v1',
    ),
  };

  static const config = StudyConfig(
    protocolVersion: '2026-08-v1',
    defaultSchedule: kDefaultScheduleTemplate,
  );

  /// Global link templates used by the participant app in tests.
  static const linkTemplates = StudyLinkTemplates(
    preStudy:
        'https://docs.google.com/forms/d/e/example/viewform?usp=pp_url&entry.10={participantId}',
    endOfDayType1:
        'https://docs.google.com/forms/d/e/example/viewform?usp=pp_url&entry.10={participantId}&entry.11=ambient',
    endOfDayType2:
        'https://docs.google.com/forms/d/e/example/viewform?usp=pp_url&entry.10={participantId}&entry.11=character',
    finalLink:
        'https://docs.google.com/forms/d/e/example/viewform?usp=pp_url&entry.10={participantId}',
  );

  @override
  Future<Participant> fetchParticipant(String code) async {
    final participant = _participants[code];
    if (participant == null) throw ParticipantNotFoundException(code);
    return participant;
  }

  @override
  Future<StudyConfig> fetchStudyConfig() async => config;

  @override
  Future<DaySchedule> fetchSchedule(
    String participantCode,
    int dayNumber, {
    required PresentationStyle style,
  }) async {
    return DaySchedule(
      dayNumber: dayNumber,
      style: style,
      reminders: kDefaultScheduleTemplate,
    );
  }

  @override
  Future<StudyLinkTemplates> fetchLinkTemplates() async => linkTemplates;
}
