import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/study/schedule_evaluator.dart';
import '../../domain/study/scheduled_reminder.dart';

part 'scheduler_provider.g.dart';

/// Injectable wall clock — overridden with a fake in tests.
@Riverpod(keepAlive: true)
DateTime Function() studyClock(Ref ref) => DateTime.now;

/// How often the scheduler evaluates. Overridden in tests so the real timer
/// never fires; tests drive [StudyScheduler.tickOnce] manually.
@Riverpod(keepAlive: true)
Duration schedulerTickInterval(Ref ref) => const Duration(seconds: 1);

/// Tick-based reminder scheduler (plan §5.2).
///
/// A single periodic tick evaluates the schedule with absolute fire times.
/// The tick also detects long gaps (sleep / App Nap / severe throttling):
/// when the gap since the previous tick exceeds [_gapThresholdMs], reminders
/// missed during that gap are recorded as `device_inactive` instead of the
/// generic `late_delivery`.
class StudyScheduler {
  StudyScheduler({
    required this.clock,
    required this.onDecisions,
  });

  static const _gapThresholdMs = 10000; // 10s at a 1s tick means we stalled

  final DateTime Function() clock;

  /// Applies decisions (deliver/miss + persist). Awaited by [tickOnce] so
  /// tests can drive deterministic ticks; the production timer ignores it.
  final Future<void> Function(List<ScheduleDecision> decisions) onDecisions;

  Timer? _timer;
  DateTime? _lastTickAt;
  bool _stopped = false;

  DateTime? _sessionStartLocal;
  List<ScheduledReminder> _schedule = const [];
  Set<int> _finalizedReminders = {};

  bool get isRunning => _timer != null;

  void start({
    required DateTime sessionStartLocal,
    required List<ScheduledReminder> schedule,
    required Set<int> finalizedReminders,
    required Duration tickInterval,
  }) {
    stop();
    _stopped = false;
    _sessionStartLocal = sessionStartLocal;
    _schedule = schedule;
    _finalizedReminders = finalizedReminders;
    _lastTickAt = clock();
    _timer = Timer.periodic(tickInterval, (_) => tickOnce());
  }

  /// Stops the periodic timer. Safe to call multiple times.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Marks the scheduler as finished and stops ticking.
  void finish() {
    _stopped = true;
    stop();
  }

  /// One evaluation round. Public for tests; the timer calls this too.
  Future<void> tickOnce() async {
    if (_stopped) return;
    final start = _sessionStartLocal;
    if (start == null) return;

    final now = clock();
    final lastTick = _lastTickAt;
    _lastTickAt = now;

    final stalled = lastTick != null &&
        now.difference(lastTick).inMilliseconds > _gapThresholdMs;

    final decisions = evaluateSchedule(
      now: now,
      sessionStartLocal: start,
      schedule: _schedule,
      finalizedReminders: _finalizedReminders,
      missedReason: stalled ? 'device_inactive' : 'late_delivery',
    );
    if (decisions.isEmpty) return;

    // Decisions are applied by the caller; locally we treat them as
    // finalized immediately so a slow persistence path can't double-fire.
    _finalizedReminders = {
      ..._finalizedReminders,
      for (final d in decisions) d.reminder.reminderNumber,
    };
    await onDecisions(decisions);
  }
}

/// Factory provider — each consumer gets a fresh scheduler instance.
@riverpod
StudyScheduler studyScheduler(
  Ref ref, {
  required Future<void> Function(List<ScheduleDecision> decisions) onDecisions,
}) {
  return StudyScheduler(
    clock: ref.watch(studyClockProvider),
    onDecisions: onDecisions,
  );
}
