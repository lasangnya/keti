import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/study/day_schedule.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_links.dart';
import '../study/participant_repository.dart';

/// Firestore-backed [ParticipantRepository] (plan §7.1):
/// reads `participants/{code}`, `config/study`, `links/templates`, and
/// `participants/{code}/schedules/day{N}` — all client read-only by rules.
class FirestoreParticipantRepository implements ParticipantRepository {
  FirestoreParticipantRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Participant> fetchParticipant(String code) async {
    final snap = await _firestore.collection('participants').doc(code).get();
    if (!snap.exists) throw ParticipantNotFoundException(code);
    return Participant.fromJson(snap.data()!);
  }

  @override
  Future<StudyConfig> fetchStudyConfig() async {
    final snap = await _firestore.collection('config').doc('study').get();
    if (!snap.exists) {
      throw StateError('config/study document is missing — run admin setup.');
    }
    return StudyConfig.fromJson(snap.data()!);
  }

  @override
  Future<DaySchedule> fetchSchedule(
    String participantCode,
    int dayNumber, {
    required PresentationStyle style,
  }) async {
    final snap = await _firestore
        .collection('participants')
        .doc(participantCode)
        .collection('schedules')
        .doc('day$dayNumber')
        .get();
    if (!snap.exists) {
      throw ScheduleNotFoundException(participantCode, dayNumber);
    }
    return DaySchedule.fromJson(snap.data()!, style: style);
  }

  @override
  Future<StudyLinkTemplates> fetchLinkTemplates() async {
    final snap = await _firestore.collection('links').doc('templates').get();
    if (!snap.exists) return const StudyLinkTemplates();
    return StudyLinkTemplates.fromJson(snap.data()!);
  }

  @override
  Future<bool> hasSession(String participantCode, int dayNumber) async {
    final snap = await _firestore
        .collection('participants')
        .doc(participantCode)
        .collection('studySessions')
        .doc('day$dayNumber')
        .get();
    return snap.exists;
  }
}
