import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/study/reminder_event.dart';
import '../../../domain/study/study_enums.dart';

/// Write/read contract for `reminderEvents` documents (plan §7).
///
/// Lifecycle updates go through [updateEventLifecycle], which writes ONLY
/// the fields the Firestore rules allow clients to mutate — condition
/// fields (placement, style, ids, versions) are write-once at creation and
/// can never be smuggled into an update from here.
abstract class ReminderEventRepository {
  /// Pre-creates the 8 scheduled event docs at session start (batch).
  Future<void> createScheduledEvents(
    String participantCode,
    String dayId,
    List<ReminderEvent> events,
  );

  /// Applies the event's current lifecycle state to Firestore.
  Future<void> updateEventLifecycle(
    String participantCode,
    String dayId,
    ReminderEvent event,
  );

  Future<List<ReminderEvent>> getEvents(String participantCode, String dayId);
}

class FirestoreReminderEventRepository implements ReminderEventRepository {
  FirestoreReminderEventRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String code, String dayId) =>
      _firestore
          .collection('participants')
          .doc(code)
          .collection('studySessions')
          .doc(dayId)
          .collection('reminderEvents');

  @override
  Future<void> createScheduledEvents(
    String participantCode,
    String dayId,
    List<ReminderEvent> events,
  ) {
    final batch = _firestore.batch();
    for (final event in events) {
      batch.set(_col(participantCode, dayId).doc(event.eventId), event.toJson());
    }
    return batch.commit();
  }

  @override
  Future<void> updateEventLifecycle(
    String participantCode,
    String dayId,
    ReminderEvent event,
  ) {
    final data = <String, Object?>{
      'reminderShownAtLocal': event.reminderShownAtLocal?.toIso8601String(),
      'reminderHiddenAtLocal': event.reminderHiddenAtLocal?.toIso8601String(),
      'deliveryLatenessMs': event.deliveryLatenessMs,
      'deliveryStatus': event.deliveryStatus.wireName,
      'failureReason': event.failureReason,
      'suppressionReason': event.suppressionReason,
      'usedFallback': event.usedFallback,
      'cardShownAtLocal': event.cardShownAtLocal?.toIso8601String(),
      'outcome': event.outcome.wireName,
      'answeredAtLocal': event.answeredAtLocal?.toIso8601String(),
      'responseLatencyMs': event.responseLatencyMs,
      'sessionResumed': event.sessionResumed,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Server-authoritative stamps, only when the moment actually happened.
    if (event.reminderShownAtLocal != null) {
      data['reminderShownAt'] = FieldValue.serverTimestamp();
    }
    if (event.answeredAtLocal != null) {
      data['answeredAt'] = FieldValue.serverTimestamp();
    }
    return _col(participantCode, dayId).doc(event.eventId).update(data);
  }

  @override
  Future<List<ReminderEvent>> getEvents(
      String participantCode, String dayId) async {
    final snap = await _col(participantCode, dayId)
        .orderBy('reminderNumber')
        .get();
    return [
      for (final doc in snap.docs) ReminderEvent.fromJson(doc.data()),
    ];
  }
}
