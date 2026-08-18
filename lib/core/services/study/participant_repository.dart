import '../../../domain/study/day_schedule.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_links.dart';

/// Thrown when no participant document exists for the entered code.
class ParticipantNotFoundException implements Exception {
  const ParticipantNotFoundException(this.code);

  final String code;

  @override
  String toString() => 'ParticipantNotFoundException: $code';
}

/// Thrown when a per-day schedule document is missing in Firestore
/// (`participants/{code}/schedules/day{N}`). The researcher must create it
/// (admin → participant → Schedule → Save).
class ScheduleNotFoundException implements Exception {
  const ScheduleNotFoundException(this.participantCode, this.dayNumber);

  final String participantCode;
  final int dayNumber;

  @override
  String toString() =>
      'ScheduleNotFoundException: $participantCode day$dayNumber';
}

/// Read-side contract for everything the ID-entry flow needs (plan §3.2).
///
/// M2 ships an in-memory [MockParticipantRepository]; M3 swaps in the
/// Firestore implementation without touching callers.
abstract class ParticipantRepository {
  Future<Participant> fetchParticipant(String code);

  Future<StudyConfig> fetchStudyConfig();

  /// The participant's schedule for [dayNumber]. [style] is resolved by the
  /// caller from the participant's style order — it is not stored in the
  /// schedule document.
  Future<DaySchedule> fetchSchedule(
    String participantCode,
    int dayNumber, {
    required PresentationStyle style,
  });

  /// The global questionnaire link templates (`links/templates`).
  Future<StudyLinkTemplates> fetchLinkTemplates();

  /// True when a session document exists for [participantCode]/[dayNumber].
  /// Used by the participant app to sanity-check the active-day gate (Day 2
  /// must not be offered before Day 1 was started).
  Future<bool> hasSession(String participantCode, int dayNumber);
}
