import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/firebase/firestore_providers.dart';
import '../../core/services/session_lifecycle_service.dart';
import '../../domain/study/event_log_entry.dart';
import '../../domain/study/reminder_content_resolver.dart';
import '../../domain/study/reminder_event.dart';
import '../../domain/study/schedule_evaluator.dart';
import '../../domain/study/scheduled_reminder.dart';
import '../../domain/study/study_config.dart';
import '../../domain/study/study_enums.dart';
import '../../domain/study/study_session.dart';
import '../reminders/reminder_orchestrator.dart';
import 'participant_entry_provider.dart';
import 'participant_providers.dart';
import 'scheduler_provider.dart';

part 'session_controller.g.dart';

/// UI-facing state of the running (or finished) study session.
class StudySessionState {
  const StudySessionState({
    this.session,
    this.events = const [],
    this.active = false,
    this.completed = false,
    this.errorMessage,
  });

  final StudySession? session;
  final List<ReminderEvent> events;
  final bool active;
  final bool completed;
  final String? errorMessage;

  /// Next pending fire time (absolute), for the status display.
  DateTime? get nextFireTime {
    final s = session;
    if (s == null) return null;
    final pending = events
        .where((e) => e.deliveryStatus == DeliveryStatus.scheduled)
        .map((e) => e.reminderNumber)
        .toSet();
    if (pending.isEmpty) return null;
    DateTime? earliest;
    for (final r in s.schedule.reminders) {
      if (!pending.contains(r.reminderNumber)) continue;
      final fire = s.startedAtLocal.add(r.offset);
      if (earliest == null || fire.isBefore(earliest)) earliest = fire;
    }
    return earliest;
  }

  StudySessionState copyWith({
    StudySession? session,
    List<ReminderEvent>? events,
    bool? active,
    bool? completed,
    String? errorMessage,
  }) =>
      StudySessionState(
        session: session ?? this.session,
        events: events ?? this.events,
        active: active ?? this.active,
        completed: completed ?? this.completed,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

/// Orchestrates a participant-day session (plan §5.2/§6.5):
/// session + event creation (CSV-first, then Firestore), the tick
/// scheduler, delivery, catch-up and resume after an app quit, and
/// day completion.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  static const _resolver = ReminderContentResolver();

  StudyScheduler? _scheduler;

  @override
  StudySessionState build() {
    ref.onDispose(() => _scheduler?.stop());
    return const StudySessionState();
  }

  DateTime _now() => ref.read(studyClockProvider)();

  /// Starts the currently loaded participant-day. Assumes the ID-entry
  /// flow already validated participant, config and schedule.
  Future<void> startDay() async {
    final entry = ref.read(participantEntryProvider);
    if (!entry.isReady || state.active) return;
    // Never start over an unfinished session: a second start would reuse the
    // same event doc IDs in Firestore (rejected as an update by the rules,
    // leaving mixed data). Resuming is the only legitimate path; a full
    // restart requires a researcher reset.
    if (entry.resumableDayId != null) return;
    final participant = entry.participant!;
    final schedule = entry.daySchedule!;

    final now = _now();
    final resolvedLinks = entry.links ?? const QuestionnaireLinks();
    final session = StudySession(
      participantCode: participant.participantCode,
      dayNumber: schedule.dayNumber,
      style: schedule.style,
      status: StudySessionStatus.active,
      startedAtLocal: now,
      schedule: schedule,
      links: resolvedLinks,
    );
    final events = [
      for (final reminder in schedule.reminders)
        ReminderEvent.scheduled(
          participantCode: participant.participantCode,
          dayNumber: schedule.dayNumber,
          reminder: reminder,
          style: schedule.style,
          sessionStartLocal: now,
          environment: AppConfig.environment,
          appVersion: AppConfig.appVersion,
          protocolVersion: AppConfig.protocolVersion,
        ),
    ];

    final csv = ref.read(csvStoreProvider);
    final store = await ref.read(localStoreProvider.future);
    final code = participant.participantCode;
    final dayId = session.dayId;

    // CSV-first: local record is ground truth.
    await csv.writeSession(session);
    await csv.writeEvents(code, dayId, events);
    await csv.appendEventLog(
      code,
      dayId,
      EventLogEntry(
        timestamp: now,
        eventId: 'session',
        transition: 'session_started',
        newValue: dayId,
      ),
    );
    await store.setActiveSession(code, dayId);

    // Firestore second — failures here are covered by reconciliation (M8).
    try {
      await ref.read(sessionRepositoryProvider).createSession(session);
      await ref
          .read(reminderEventRepositoryProvider)
          .createScheduledEvents(code, dayId, events);
    } catch (_) {
      // Offline: the SDK queues what it can; CSVs hold everything.
    }

    await SessionLifecycleService.setSessionActive(true);

    state = StudySessionState(session: session, events: events, active: true);
    _startScheduler(session);
  }

  /// Resumes an unfinished session for the entered participant after an
  /// app quit (plan §3.4). Re-anchors to the ORIGINAL start time, marks
  /// long-missed reminders as `notDisplayed(app_terminated)`, delivers
  /// anything still inside the grace window, and continues the schedule.
  Future<bool> resumeActiveSession() async {
    final entry = ref.read(participantEntryProvider);
    final participant = entry.participant;
    if (participant == null || state.active) return false;
    final code = participant.participantCode;

    final csv = ref.read(csvStoreProvider);
    final dayId = await csv.findActiveDayId(code);
    if (dayId == null) return false;

    final session = await csv.readSession(code, dayId);
    final events = await csv.readEvents(code, dayId);
    if (session == null || events == null || events.isEmpty) return false;

    final resumedSession =
        session.copyWith(resumedCount: session.resumedCount + 1);
    await csv.writeSession(resumedSession);
    await csv.appendEventLog(
      code,
      dayId,
      EventLogEntry(
        timestamp: _now(),
        eventId: 'session',
        transition: 'session_resumed',
        newValue: '${resumedSession.resumedCount}',
      ),
    );
    try {
      await ref
          .read(sessionRepositoryProvider)
          .markSessionResumed(code, dayId);
    } catch (_) {}

    // Everything still pending is from after the resume — flag it.
    var currentEvents = [
      for (final e in events)
        e.deliveryStatus == DeliveryStatus.scheduled
            ? e.markSessionResumed()
            : e,
    ];
    await csv.writeEvents(code, dayId, currentEvents);

    state = StudySessionState(
        session: resumedSession, events: currentEvents, active: true);

    // Catch up on anything that came due while the app was dead.
    await _evaluate(
      missedReason: 'app_terminated',
      now: _now(),
    );

    if (!state.completed) {
      await SessionLifecycleService.setSessionActive(true);
      _startScheduler(resumedSession);
    }
    return true;
  }

  /// Test seam: drive one scheduler tick with the (fake) injected clock.
  Future<void> debugTick() async => _scheduler?.tickOnce();

  /// Clears the finished day-1 session state so the participant can start
  /// Day 2. Called by the completed view's "Start Day 2" action.
  void resetForNewDay() {
    _scheduler?.stop();
    state = const StudySessionState();
  }

  /// Test seam: wait until all in-flight reminder sequences have finished.
  Future<void> debugAwaitIdle() => Future.wait(_inFlight.toList());

  /// Participant tapped Exit during an active session. Records the event
  /// locally and in Firestore, then terminates the app. The session itself
  /// stays active, so a relaunch offers Resume (same as a window close).
  Future<void> requestExit() async {
    final session = state.session;
    if (session == null || !state.active) return;
    final code = session.participantCode;
    final dayId = session.dayId;

    // CSV-first: local record is ground truth.
    final csv = ref.read(csvStoreProvider);
    await csv.appendEventLog(
      code,
      dayId,
      EventLogEntry(
        timestamp: _now(),
        eventId: 'session',
        transition: 'participant_exit_requested',
      ),
    );
    try {
      await ref
          .read(sessionRepositoryProvider)
          .markParticipantExit(code, dayId)
          // Best effort: never block the exit on a slow/unreachable network.
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Firestore exit marker failed: $e');
    }
    await SessionLifecycleService.exitApp();
  }

  final Set<Future<void>> _inFlight = {};

  void _trackInFlight(Future<void> future) {
    _inFlight.add(future);
    future.whenComplete(() => _inFlight.remove(future));
  }

  // ── internals ────────────────────────────────────────────────────

  void _startScheduler(StudySession session) {
    _scheduler?.stop();
    final finalized = state.events
        .where((e) => e.deliveryStatus != DeliveryStatus.scheduled)
        .map((e) => e.reminderNumber)
        .toSet();
    final scheduler = StudyScheduler(
      clock: _now,
      onDecisions: _handleDecisions,
    );
    scheduler.start(
      sessionStartLocal: session.startedAtLocal,
      schedule: session.schedule.reminders,
      finalizedReminders: finalized,
      tickInterval: ref.read(schedulerTickIntervalProvider),
    );
    _scheduler = scheduler;
  }

  Future<void> _handleDecisions(List<ScheduleDecision> decisions) async {
    for (final decision in decisions) {
      if (!ref.mounted) return;
      switch (decision) {
        case ScheduleDue(:final reminder, :final latenessMs):
          await _deliver(reminder, latenessMs);
        case ScheduleMissed(:final reminder, :final reason):
          await _miss(reminder, reason);
      }
    }
    if (!ref.mounted) return;
    await _completeDayIfDone();
  }

  /// One catch-up evaluation outside the timer (used by resume).
  Future<void> _evaluate({
    required String missedReason,
    required DateTime now,
  }) async {
    final session = state.session!;
    final finalized = state.events
        .where((e) => e.deliveryStatus != DeliveryStatus.scheduled)
        .map((e) => e.reminderNumber)
        .toSet();
    final decisions = evaluateSchedule(
      now: now,
      sessionStartLocal: session.startedAtLocal,
      schedule: session.schedule.reminders,
      finalizedReminders: finalized,
      missedReason: missedReason,
    );
    await _handleDecisions(decisions);
  }

  Future<void> _deliver(ScheduledReminder reminder, int latenessMs) async {
    final session = state.session!;
    final code = session.participantCode;
    final event = state.events
        .firstWhere((e) => e.reminderNumber == reminder.reminderNumber);

    final resolved = _resolver.resolve(reminder.kind, session.style);
    final usedFallback = resolved.isFallback(reminder.placement);
    final question = reminder.kind == ReminderKind.hydration
        ? AppStrings.complianceHydrationQuestion
        : AppStrings.complianceBreakQuestion;

    // The reminder → window → compliance-card chain runs for up to ~3
    // minutes. It is kicked off detached — the 1 s tick must not block on
    // it — and progress arrives through the callbacks below.
    final sequence = ref.read(reminderOrchestratorProvider).runReminderSequence(
        reminderId: event.eventId,
        content: resolved.content,
        placement: reminder.placement,
        question: question,
        button1Text: AppStrings.complianceButton1,
        button2Text: AppStrings.complianceButton2,
        visibilityMs: AppConfig.reminderVisibilityMs,
        cardDelayMs: AppConfig.complianceCardDelayMs,
        cardTimeoutMs: AppConfig.complianceCardTimeoutMs,
        onDelivered: () async {
          if (!ref.mounted) return;
          final current = _eventById(event.eventId);
          await _persistEvent(
            code,
            session.dayId,
            current.markDelivered(
              shownAtLocal: _now(),
              latenessMs: latenessMs,
              usedFallback: usedFallback,
            ),
            'delivered',
          );
        },
        onReminderHidden: () async {
          if (!ref.mounted) return;
          final current = _eventById(event.eventId);
          await _persistEvent(
            code,
            session.dayId,
            current.markReminderHidden(_now()),
            'reminder_hidden',
          );
        },
        onCardShown: () async {
          if (!ref.mounted) return;
          final current = _eventById(event.eventId);
          final shown = current.markCardShown(_now());
          debugPrint('ComplianceCard: ${event.eventId} card shown at '
              '${shown.cardShownAtLocal?.toIso8601String()}');
          await _persistEvent(
            code,
            session.dayId,
            shown,
            'card_shown',
          );
        },
        onCardAnswered: (action) async {
          if (!ref.mounted) return;
          final current = _eventById(event.eventId);
          final isCompleted = action == 'completed';
          final answered = current.markAnswered(
            outcome: isCompleted
                ? ResponseOutcome.completed
                : ResponseOutcome.dismissed,
            answeredAtLocal: _now(),
            // The actual label the participant saw and pressed.
            cardResponse: isCompleted
                ? AppStrings.complianceButton1
                : AppStrings.complianceButton2,
          );
          debugPrint('ComplianceCard: ${event.eventId} answered action=$action '
              'outcome=${answered.outcome.wireName} '
              'cardResponse=${answered.cardResponse} '
              'latencyMs=${answered.responseLatencyMs}');
          await _persistEvent(
            code,
            session.dayId,
            answered,
            'answered',
          );
          await _completeDayIfDone();
        },
        onCardTimedOut: () async {
          if (!ref.mounted) return;
          final current = _eventById(event.eventId);
          final timedOut = current.markTimedOut(_now());
          debugPrint('ComplianceCard: ${event.eventId} timed out — '
              'outcome=${timedOut.outcome.wireName} '
              'cardResponse=${timedOut.cardResponse}');
          await _persistEvent(
            code,
            session.dayId,
            timedOut,
            'timed_out',
          );
          await _completeDayIfDone();
        },
        onFailed: (reason) async {
          if (!ref.mounted) return;
          final current = _eventById(event.eventId);
          await _persistEvent(
            code,
            session.dayId,
            current.markFailed(reason),
            'failed',
          );
          await _completeDayIfDone();
        },
      );
    _trackInFlight(sequence);
  }

  ReminderEvent _eventById(String eventId) =>
      state.events.firstWhere((e) => e.eventId == eventId);

  Future<void> _miss(ScheduledReminder reminder, String reason) async {
    final session = state.session!;
    final code = session.participantCode;
    final event = state.events
        .firstWhere((e) => e.reminderNumber == reminder.reminderNumber);

    final updated = reason == 'app_terminated'
        ? event.markNotDisplayed(reason)
        : event.markSuppressed(reason);
    await _persistEvent(code, session.dayId, updated, 'missed:$reason');
  }

  Future<void> _persistEvent(
    String code,
    String dayId,
    ReminderEvent updated,
    String transition,
  ) async {
    if (!ref.mounted) return;
    final events = [
      for (final e in state.events)
        e.eventId == updated.eventId ? updated : e,
    ];
    state = state.copyWith(events: events);

    final csv = ref.read(csvStoreProvider);
    await csv.writeEvents(code, dayId, events);
    await csv.appendEventLog(
      code,
      dayId,
      EventLogEntry(
        timestamp: _now(),
        eventId: updated.eventId,
        transition: transition,
        field: 'deliveryStatus',
        newValue: updated.deliveryStatus.wireName,
      ),
    );
    try {
      await ref
          .read(reminderEventRepositoryProvider)
          .updateEventLifecycle(code, dayId, updated);
    } catch (e) {
      debugPrint('Firestore sync FAILED for $transition ${updated.eventId}: $e');
    }
  }

  /// An event is final when it left the scheduled state AND — for delivered
  /// reminders — the compliance card has produced an outcome.
  static bool _isFinal(ReminderEvent e) {
    if (e.deliveryStatus == DeliveryStatus.scheduled) return false;
    if (e.deliveryStatus == DeliveryStatus.delivered &&
        e.outcome == ResponseOutcome.none) {
      return false;
    }
    return true;
  }

  Future<void> _completeDayIfDone() async {
    if (!ref.mounted) return;
    final session = state.session;
    if (session == null || state.completed) return;
    final allFinalized = state.events.every(_isFinal);
    if (!allFinalized) return;

    _scheduler?.finish();
    final completed = session.copyWith(
      status: StudySessionStatus.completed,
      completedAtLocal: _now(),
    );
    final csv = ref.read(csvStoreProvider);
    await csv.writeSession(completed);
    await csv.appendEventLog(
      session.participantCode,
      session.dayId,
      EventLogEntry(
        timestamp: _now(),
        eventId: 'session',
        transition: 'session_completed',
      ),
    );
    final store = await ref.read(localStoreProvider.future);
    await store.clearActiveSession(session.participantCode);
    try {
      await ref
          .read(sessionRepositoryProvider)
          .completeSession(session.participantCode, session.dayId);
    } catch (_) {}
    await SessionLifecycleService.setSessionActive(false);

    state = state.copyWith(
      session: completed,
      active: false,
      completed: true,
    );
  }
}
