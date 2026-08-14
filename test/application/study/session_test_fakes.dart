import 'package:keti/application/reminders/reminder_orchestrator.dart';
import 'package:keti/core/services/firestore/reminder_event_repository.dart';
import 'package:keti/core/services/firestore/session_repository.dart';
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
  int exitMarkCalls = 0;

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

  @override
  Future<void> markParticipantExit(String code, String dayId) async {
    exitMarkCalls++;
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

/// Records sequences and drives the callback chain synchronously.
class FakeReminderOrchestrator extends ReminderOrchestrator {
  final calls =
      <({String reminderId, ReminderContent content, Placement placement})>[];
  bool failNext = false;

  /// When true (default), runs deliver → hidden → cardShown → answered.
  /// When false, stops after onDelivered (outcome stays open).
  bool completeChain = true;
  String answerAction = 'completed';

  @override
  Future<void> runReminderSequence({
    required String reminderId,
    required ReminderContent content,
    required Placement placement,
    required String question,
    required String button1Text,
    required String button2Text,
    required int visibilityMs,
    required int cardDelayMs,
    required int cardTimeoutMs,
    required Future<void> Function() onDelivered,
    required Future<void> Function() onReminderHidden,
    required Future<void> Function() onCardShown,
    required Future<void> Function(String action) onCardAnswered,
    required Future<void> Function() onCardTimedOut,
    required Future<void> Function(String reason) onFailed,
  }) async {
    calls.add(
        (reminderId: reminderId, content: content, placement: placement));
    if (failNext) {
      failNext = false;
      await onFailed('display_dispatch:simulated');
      return;
    }
    await onDelivered();
    if (completeChain) {
      await onReminderHidden();
      await onCardShown();
      await onCardAnswered(answerAction);
    }
  }
}
