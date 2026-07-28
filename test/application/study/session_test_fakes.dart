import 'package:keti/core/services/firestore/reminder_event_repository.dart';
import 'package:keti/core/services/firestore/session_repository.dart';
import 'package:keti/core/services/study/reminder_delivery.dart';
import 'package:keti/domain/reminders/reminder_content.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';

/// In-memory fakes shared by the session controller tests.

class FakeSessionRepository implements SessionRepository {
  final sessions = <String, StudySession>{};
  int createCalls = 0;
  int resumeCalls = 0;
  int completeCalls = 0;

  @override
  Future<void> createSession(StudySession session) async {
    createCalls++;
    sessions['${session.participantCode}/${session.dayId}'] = session;
  }

  @override
  Future<StudySession?> getSession(String code, String dayId) async =>
      sessions['$code/$dayId'];

  @override
  Future<void> markSessionResumed(String code, String dayId) async {
    resumeCalls++;
    final s = sessions['$code/$dayId'];
    if (s != null) {
      sessions['$code/$dayId'] = s.copyWith(resumedCount: s.resumedCount + 1);
    }
  }

  @override
  Future<void> completeSession(String code, String dayId) async {
    completeCalls++;
  }
}

class FakeEventRepository implements ReminderEventRepository {
  final created = <ReminderEvent>[];
  final updated = <ReminderEvent>[];
  int createCalls = 0;

  @override
  Future<void> createScheduledEvents(
      String code, String dayId, List<ReminderEvent> events) async {
    createCalls++;
    created.addAll(events);
  }

  @override
  Future<void> updateEventLifecycle(
      String code, String dayId, ReminderEvent event) async {
    updated.add(event);
  }

  @override
  Future<List<ReminderEvent>> getEvents(String code, String dayId) async =>
      [...created]..sort((a, b) => a.reminderNumber.compareTo(b.reminderNumber));
}

class RecordingDelivery implements ReminderDelivery {
  final calls = <({ReminderContent content, Placement placement})>[];
  bool throwNext = false;

  @override
  Future<void> show({
    required ReminderContent content,
    required Placement placement,
  }) async {
    if (throwNext) {
      throwNext = false;
      throw StateError('simulated display failure');
    }
    calls.add((content: content, placement: placement));
  }
}
