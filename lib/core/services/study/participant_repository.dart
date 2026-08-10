import '../../../domain/study/day_schedule.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';

/// Thrown when no participant document exists for the entered code.
class ParticipantNotFoundException implements Exception {
  const ParticipantNotFoundException(this.code);

  final String code;

  @override
  String toString() => 'ParticipantNotFoundException: $code';
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
}
