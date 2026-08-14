import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/study/study_session.dart';
import '../../constants/app_config.dart';

/// Write/read contract for `studySessions` documents (plan §7).
abstract class SessionRepository {
  /// Creates the session document at day start, stamping a server
  /// `startedAt` alongside the model's `startedAtLocal`.
  Future<void> createSession(StudySession session);

  Future<StudySession?> getSession(String participantCode, String dayId);

  /// Increments `resumedCount` after an app relaunch mid-session.
  Future<void> markSessionResumed(String participantCode, String dayId);

  /// Marks the session completed with a server `completedAt`.
  Future<void> completeSession(String participantCode, String dayId);

  /// Records that the participant requested an app exit mid-session, with a
  /// server `participantExitRequestedAt` timestamp. The session itself stays
  /// active so a relaunch can resume it.
  Future<void> markParticipantExit(String participantCode, String dayId);
}

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String code, String dayId) =>
      _firestore
          .collection('participants')
          .doc(code)
          .collection('studySessions')
          .doc(dayId);

  @override
  Future<void> createSession(StudySession session) {
    final data = <String, Object?>{
      ...session.toJson(),
      'startedAt': FieldValue.serverTimestamp(),
      'environment': AppConfig.environment,
      'appVersion': AppConfig.appVersion,
      'protocolVersion': AppConfig.protocolVersion,
    };
    return _doc(session.participantCode, session.dayId).set(data);
  }

  @override
  Future<StudySession?> getSession(String participantCode, String dayId) async {
    final snap = await _doc(participantCode, dayId).get();
    if (!snap.exists) return null;
    return StudySession.fromJson(snap.data()!);
  }

  @override
  Future<void> markSessionResumed(String participantCode, String dayId) =>
      _doc(participantCode, dayId)
          .update({'resumedCount': FieldValue.increment(1)});

  @override
  Future<void> completeSession(String participantCode, String dayId) =>
      _doc(participantCode, dayId).update({
        'status': 'COMPLETED',
        'completedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> markParticipantExit(String participantCode, String dayId) =>
      _doc(participantCode, dayId).update({
        'participantExitRequestedAt': FieldValue.serverTimestamp(),
      });
}
