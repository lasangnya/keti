import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/local/csv_store.dart';
import '../../core/services/study/participant_repository.dart';
import '../../domain/study/condition_assignment.dart';
import '../../domain/study/day_schedule.dart';
import '../../domain/study/participant.dart';
import '../../domain/study/study_config.dart';
import '../../domain/study/study_session.dart';
import 'participant_providers.dart';

part 'participant_entry_provider.g.dart';

/// UI state of the participant ID-entry flow (plan §3.2).
class ParticipantEntryState {
  const ParticipantEntryState({
    this.isLoading = false,
    this.errorMessage,
    this.participant,
    this.config,
    this.daySchedule,
    this.fromCache = false,
    this.resumableDayId,
    this.dayAlreadyCompleted = false,
  });

  final bool isLoading;
  final String? errorMessage;

  /// Set once a participant document has been fetched and validated.
  final Participant? participant;
  final StudyConfig? config;

  /// The schedule for the participant's currently active day.
  final DaySchedule? daySchedule;

  /// True when data came from the local cache because the network failed.
  final bool fromCache;

  /// Set when an unfinished local session exists for this participant.
  final String? resumableDayId;

  /// True when the active day's session is already marked completed locally.
  final bool dayAlreadyCompleted;

  bool get isReady => participant != null && daySchedule != null;

  ParticipantEntryState copyWith({
    bool? isLoading,
    String? errorMessage,
    Participant? participant,
    StudyConfig? config,
    DaySchedule? daySchedule,
    bool? fromCache,
    String? resumableDayId,
    bool? dayAlreadyCompleted,
  }) =>
      ParticipantEntryState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        participant: participant ?? this.participant,
        config: config ?? this.config,
        daySchedule: daySchedule ?? this.daySchedule,
        fromCache: fromCache ?? this.fromCache,
        resumableDayId: resumableDayId ?? this.resumableDayId,
        dayAlreadyCompleted: dayAlreadyCompleted ?? this.dayAlreadyCompleted,
      );
}

/// Keep-alive: this controller performs async work (fetch + cache) on behalf
/// of the whole page; autoDispose could tear it down mid-flight and strand
/// the UI in its loading state.
@Riverpod(keepAlive: true)
class ParticipantEntry extends _$ParticipantEntry {
  @override
  ParticipantEntryState build() => const ParticipantEntryState();

  /// Validates the entered code, fetches participant/config/schedule,
  /// caches everything locally, and detects resumable or completed days.
  Future<void> enterCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (!Participant.isValidCode(code)) {
      state = const ParticipantEntryState(
          errorMessage: 'Enter a valid participant code (e.g. P014).');
      return;
    }

    state = const ParticipantEntryState(isLoading: true);

    final repository = ref.read(participantRepositoryProvider);
    final store = await ref.read(localStoreProvider.future);
    final csv = ref.read(csvStoreProvider);

    try {
      final participant = await repository.fetchParticipant(code);
      final config = await repository.fetchStudyConfig();
      final style = styleForDay(participant.styleOrder, participant.activeDay);
      final schedule = await repository.fetchSchedule(
        participant.participantCode,
        participant.activeDay,
        style: style,
      );

      await store.setLastParticipantCode(participant.participantCode);
      await store.cacheParticipant(participant);
      await store.cacheStudyConfig(config);
      await store.cacheScheduleFor(participant.participantCode, schedule);

      state = await _readyState(csv, participant, config, schedule,
          fromCache: false);
    } on ParticipantNotFoundException {
      state = ParticipantEntryState(
          errorMessage: 'Unknown participant code $code.');
    } catch (_) {
      // Network failure path: fall back to whatever is cached locally.
      final cached = store.readCachedParticipant(code);
      final cachedConfig = store.readCachedStudyConfig();
      if (cached == null || cachedConfig == null) {
        state = ParticipantEntryState(
            errorMessage:
                'Could not load $code (offline and no cached data on this machine).');
        return;
      }
      final style = styleForDay(cached.styleOrder, cached.activeDay);
      final cachedSchedule = store.readCachedSchedule(
        cached.participantCode,
        'day${cached.activeDay}',
        style: style,
      );
      if (cachedSchedule == null) {
        state = ParticipantEntryState(
            errorMessage:
                'Could not load the schedule for $code (offline and no cached schedule).');
        return;
      }
      state = await _readyState(csv, cached, cachedConfig, cachedSchedule,
          fromCache: true);
    }
  }

  Future<ParticipantEntryState> _readyState(
    CsvStore csv,
    Participant participant,
    StudyConfig config,
    DaySchedule schedule, {
    required bool fromCache,
  }) async {
    final session =
        await csv.readSession(participant.participantCode, schedule.dayId);
    final completed = session?.status == StudySessionStatus.completed;
    final resumable = session?.status == StudySessionStatus.active;

    return ParticipantEntryState(
      participant: participant,
      config: config,
      daySchedule: schedule,
      fromCache: fromCache,
      resumableDayId: resumable ? schedule.dayId : null,
      dayAlreadyCompleted: completed,
      errorMessage:
          completed ? 'Day ${schedule.dayNumber} is already completed for '
              '${participant.participantCode}.' : null,
    );
  }

  /// Clears the flow back to the bare ID-entry form.
  void reset() {
    state = const ParticipantEntryState();
  }
}
