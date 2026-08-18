import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/study/participant.dart';
import '../../../domain/study/reminder_event.dart';
import '../../../domain/study/scheduled_reminder.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_links.dart';
import '../../../domain/study/study_session.dart';
import '../../constants/app_config.dart';

/// Write-side contract for the admin backend (plan §6.6). Every method here
/// requires the Firestore rules' admin claim.
abstract class AdminRepository {
  Future<List<Participant>> listParticipants();

  Future<StudyConfig> getConfig();

  /// Reads the global questionnaire link templates (`links/templates`).
  Future<StudyLinkTemplates> getLinkTemplates();

  /// Replaces the four questionnaire link templates in `links/templates`.
  Future<void> saveLinkTemplates(StudyLinkTemplates templates);

  /// Creates the participant document plus both per-day schedule documents
  /// (copied from the config's default schedule template). The code is
  /// derived from the serial (`P014`).
  Future<Participant> createParticipant({
    required int serial,
    required StyleOrder styleOrder,
    required bool assignmentOverride,
  });

  /// The "Activate Day 2" action (also allows flipping back to day 1 for
  /// pilot corrections).
  Future<void> setActiveDay(String participantCode, int day);

  /// Deletes the [day] session and its events (Firestore), stamps a
  /// per-day reset signal (`resetDay{1,2}At`) that wipes the same day on the
  /// participant device on its next code entry, and moves the active-day
  /// gate back to [day] so the participant can redo it.
  Future<void> resetDay(String participantCode, int day);

  /// FULL participant reset: deletes both days' sessions and events
  /// (Firestore), stamps a full reset signal (`resetAllAt` + both per-day
  /// signals) that wipes ALL local device data on the participant's next
  /// code entry — sessions, tutorial-seen flag and caches — and moves the
  /// active-day gate back to day 1, so the same code starts over as a
  /// fresh participant. Identity, condition assignment and schedules are
  /// kept.
  Future<void> resetParticipant(String participantCode);

  /// Admin-only order change — the UI blocks it once Day 1 has started.
  Future<void> setStyleOrder(String participantCode, StyleOrder order,
      {required bool assignmentOverride});

  /// Writes the per-participant questionnaire switches to the participant
  /// document (`linkFlags`), deciding which links the app offers.
  Future<void> saveParticipantLinkFlags(
      String participantCode, ParticipantLinkFlags flags);

  Future<List<ScheduledReminder>> getSchedule(
      String participantCode, int dayNumber);

  /// True when a schedule document exists for the participant/day (i.e. the
  /// researcher has actually saved it — a missing doc silently falls back to
  /// the template in [getSchedule]).
  Future<bool> hasSavedSchedule(String participantCode, int dayNumber);

  Future<void> saveSchedule(String participantCode, int dayNumber,
      List<ScheduledReminder> reminders);

  /// `[day1, day2]` sessions, each null when not started.
  Future<List<StudySession?>> getSessions(String participantCode);

  Future<List<ReminderEvent>> getEvents(String participantCode, String dayId);
}

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _participant(String code) =>
      _firestore.collection('participants').doc(code);

  DocumentReference<Map<String, dynamic>> _scheduleDoc(String code, int day) =>
      _participant(code).collection('schedules').doc('day$day');

  @override
  Future<List<Participant>> listParticipants() async {
    final snap = await _firestore.collection('participants').get();
    final participants = [
      for (final doc in snap.docs) Participant.fromJson(doc.data()),
    ];
    participants.sort((a, b) => a.serial.compareTo(b.serial));
    return participants;
  }

  @override
  Future<StudyConfig> getConfig() async {
    final snap = await _firestore.collection('config').doc('study').get();
    if (!snap.exists) {
      return const StudyConfig(
        protocolVersion: AppConfig.protocolVersion,
        defaultSchedule: kDefaultScheduleTemplate,
      );
    }
    return StudyConfig.fromJson(snap.data()!);
  }

  @override
  Future<StudyLinkTemplates> getLinkTemplates() async {
    final snap = await _firestore.collection('links').doc('templates').get();
    if (!snap.exists) return const StudyLinkTemplates();
    return StudyLinkTemplates.fromJson(snap.data()!);
  }

  @override
  Future<void> saveLinkTemplates(StudyLinkTemplates templates) async {
    await _firestore.collection('links').doc('templates').set({
      ...templates.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Participant> createParticipant({
    required int serial,
    required StyleOrder styleOrder,
    required bool assignmentOverride,
  }) async {
    final code = 'P${serial.toString().padLeft(3, '0')}';
    final existing = await _participant(code).get();
    if (existing.exists) {
      throw StateError('Participant $code already exists.');
    }

    final participant = Participant(
      participantCode: code,
      serial: serial,
      styleOrder: styleOrder,
      assignmentOverride: assignmentOverride,
      activeDay: 1,
      environment: AppConfig.environment,
      protocolVersion: AppConfig.protocolVersion,
    );

    final config = await getConfig();
    final batch = _firestore.batch();
    batch.set(_participant(code), {
      ...participant.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (final day in [1, 2]) {
      batch.set(_scheduleDoc(code, day), {
        'dayId': 'day$day',
        'dayNumber': day,
        'reminders': config.defaultSchedule.map((r) => r.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return participant;
  }

  @override
  Future<void> setActiveDay(String participantCode, int day) =>
      _participant(participantCode).update({'activeDay': day});

  @override
  Future<void> resetDay(String participantCode, int day) async {
    final batch = _firestore.batch();

    // 1. Delete the day's session.
    final sessionRef = _participant(participantCode)
        .collection('studySessions')
        .doc('day$day');
    batch.delete(sessionRef);

    // 2. Delete all reminderEvents for that day.
    final eventsRef = sessionRef.collection('reminderEvents');
    final eventsSnap = await eventsRef.get();
    for (final doc in eventsSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. The active-day gate points at the first day that still needs to be
    //    done: resetting Day 1 always returns to Day 1; resetting Day 2 only
    //    stays on Day 2 when Day 1 is still completed — otherwise (e.g. both
    //    days reset) it falls back to Day 1 so the participant restarts from
    //    the beginning.
    var nextActiveDay = 1;
    if (day == 2) {
      final day1Snap = await _participant(participantCode)
          .collection('studySessions')
          .doc('day1')
          .get();
      final Map<String, dynamic>? day1Data = day1Snap.exists ? day1Snap.data() : null;
      final Object? rawStatus = day1Data?['status'];
      final day1Status = rawStatus as String?;
      if (day1Status == StudySessionStatus.completed.wireName) {
        nextActiveDay = 2;
      }
    }

    // 4. Stamp the per-day reset signal (wipes the same day locally on the
    //    device) and move the active-day gate.
    batch.update(_participant(participantCode), {
      'activeDay': nextActiveDay,
      'resetDay$day' 'At': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> resetParticipant(String participantCode) async {
    final batch = _firestore.batch();

    // Delete both days' sessions and every reminder event under them.
    for (final day in const [1, 2]) {
      final sessionRef = _participant(participantCode)
          .collection('studySessions')
          .doc('day$day');
      final eventsRef = sessionRef.collection('reminderEvents');
      final eventsSnap = await eventsRef.get();
      for (final doc in eventsSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(sessionRef);
    }

    // Back to a fresh state: day-1 gate, default link flags, and full +
    // per-day reset signals so the participant device wipes everything on
    // its next code entry.
    batch.update(_participant(participantCode), {
      'activeDay': 1,
      'linkFlags': const ParticipantLinkFlags.allOn().toJson(),
      'resetDay1At': FieldValue.serverTimestamp(),
      'resetDay2At': FieldValue.serverTimestamp(),
      'resetAllAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> setStyleOrder(String participantCode, StyleOrder order,
          {required bool assignmentOverride}) =>
      _participant(participantCode).update({
        'styleOrder': order.wireName,
        'assignmentOverride': assignmentOverride,
      });

  @override
  Future<void> saveParticipantLinkFlags(
          String participantCode, ParticipantLinkFlags flags) =>
      _participant(participantCode).update({'linkFlags': flags.toJson()});

  @override
  Future<List<ScheduledReminder>> getSchedule(
      String participantCode, int dayNumber) async {
    final snap = await _scheduleDoc(participantCode, dayNumber).get();
    if (!snap.exists) return kDefaultScheduleTemplate;
    return [
      for (final r in (snap.data()!['reminders'] as List))
        ScheduledReminder.fromJson((r as Map).cast<String, Object?>()),
    ];
  }

  @override
  Future<bool> hasSavedSchedule(String participantCode, int dayNumber) async =>
      (await _scheduleDoc(participantCode, dayNumber).get()).exists;

  @override
  Future<void> saveSchedule(String participantCode, int dayNumber,
          List<ScheduledReminder> reminders) =>
      _scheduleDoc(participantCode, dayNumber).set({
        'dayId': 'day$dayNumber',
        'dayNumber': dayNumber,
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<List<StudySession?>> getSessions(String participantCode) async {
    final result = <StudySession?>[];
    for (final dayId in const ['day1', 'day2']) {
      final snap = await _participant(participantCode)
          .collection('studySessions')
          .doc(dayId)
          .get();
      result.add(snap.exists ? StudySession.fromJson(snap.data()!) : null);
    }
    return result;
  }

  @override
  Future<List<ReminderEvent>> getEvents(
      String participantCode, String dayId) async {
    final snap = await _participant(participantCode)
        .collection('studySessions')
        .doc(dayId)
        .collection('reminderEvents')
        .orderBy('reminderNumber')
        .get();
    return [for (final doc in snap.docs) ReminderEvent.fromJson(doc.data())];
  }
}
