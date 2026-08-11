import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/firebase/auth_service.dart';
import '../../core/services/local/csv_store.dart';
import '../../core/services/local/sync_service.dart';
import '../../core/services/study/participant_repository.dart';
import '../../domain/study/condition_assignment.dart';
import '../../domain/study/day_schedule.dart';
import '../../domain/study/participant.dart';
import '../../domain/study/study_config.dart';
import '../../domain/study/study_links.dart';
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
    this.links,
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

  /// The participant's resolved questionnaire links (templates × linkFlags
  /// × style order), fetched together with the schedule at ID entry.
  final QuestionnaireLinks? links;

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
    QuestionnaireLinks? links,
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
        links: links ?? this.links,
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
          errorMessage: 'Enter a valid participant ID (e.g. P014).');
      return;
    }

    state = const ParticipantEntryState(isLoading: true);

    // Safety: ensure we have an anonymous session before making Firestore calls.
    // Usually handled by AppModeState, but this provides a retry/wait if needed.
    try {
      await AuthService().signInAnonymouslyIfNeeded();
    } catch (e) {
      debugPrint('ParticipantEntry: Pre-fetch auth attempt failed: $e');
    }

    final repository = ref.read(participantRepositoryProvider);
    final store = await ref.read(localStoreProvider.future);
    final csv = ref.read(csvStoreProvider);

    try {
      final fetchedParticipant = await repository.fetchParticipant(code);
      // Sanity-check the active-day gate: Day 2 must not be offered before
      // Day 1 was started. This heals stale docs where an old reset left
      // activeDay=2 without a day-1 session.
      var participant = fetchedParticipant;
      if (participant.activeDay == 2 &&
          !await repository.hasSession(participant.participantCode, 1)) {
        debugPrint(
            'ParticipantEntry: activeDay=2 but no day-1 session — '
            'falling back to day 1');
        participant = Participant(
          participantCode: participant.participantCode,
          serial: participant.serial,
          styleOrder: participant.styleOrder,
          assignmentOverride: participant.assignmentOverride,
          activeDay: 1,
          environment: participant.environment,
          protocolVersion: participant.protocolVersion,
          resetDay1At: participant.resetDay1At,
          resetDay2At: participant.resetDay2At,
          linkFlags: participant.linkFlags,
        );
      }
      final config = await repository.fetchStudyConfig();
      final templates = await repository.fetchLinkTemplates();
      final style = styleForDay(participant.styleOrder, participant.activeDay);
      final fetched = await repository.fetchSchedule(
        participant.participantCode,
        participant.activeDay,
        style: style,
      );
      // Force the requested day number (see loadDay2): the stored schedule
      // document may carry a wrong/missing dayNumber (fromJson defaults to 1),
      // which would resolve against the wrong day's session.
      final schedule = fetched.dayNumber == participant.activeDay
          ? fetched
          : DaySchedule(
              dayNumber: participant.activeDay,
              style: fetched.style,
              reminders: fetched.reminders,
            );
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: participant.linkFlags,
        styleOrder: participant.styleOrder,
      );

      // Reset-signal detection: wipe any day whose server-side reset
      // timestamp is newer than the local session start.
      await _applyResetSignals(csv, participant);

      await store.setLastParticipantCode(participant.participantCode);
      await store.cacheParticipant(participant);
      await store.cacheStudyConfig(config);
      await store.cacheScheduleFor(participant.participantCode, schedule);
      await store.cacheLinkTemplates(templates);

      // Best-effort background reconciliation of any offline sessions.
      unawaited(ref
          .read(syncServiceProvider)
          .reconcileParticipant(participant.participantCode));

      state = await _readyState(csv, participant, config, schedule, links,
          fromCache: false);
    } on ParticipantNotFoundException {
      state = ParticipantEntryState(
          errorMessage: 'Unknown participant code $code.');
    } on ScheduleNotFoundException catch (e) {
      debugPrint('ParticipantEntry: schedule missing for $code');
      state = ParticipantEntryState(
          errorMessage:
              'No schedule is set up for $code (day ${e.dayNumber}). '
              'Please ask the researcher to save the schedule in the admin app.');
    } catch (e) {
      debugPrint('ParticipantEntry error: $e');

      // If we are signed out, Firestore will throw a permission-denied error.
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        state = ParticipantEntryState(
            errorMessage: 'Authentication failed. Please check your internet '
                'connection or Firebase Console settings.');
        return;
      }

      // Network failure path: fall back to whatever is cached locally.
      final cached = store.readCachedParticipant(code);
      final cachedConfig = store.readCachedStudyConfig();
      if (cached == null || cachedConfig == null) {
        // If there's no cache, the error might be data-related (cast error)
        // or a real network error on the first run.
        final message = (e is TypeError)
            ? 'Data error: $e. Check the Firestore document for $code.'
            : 'Could not load $code (offline and no cached data on this machine).';
        state = ParticipantEntryState(errorMessage: message);
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
      final cachedTemplates = store.readCachedLinkTemplates();
      final links = resolveQuestionnaireLinks(
        templates: cachedTemplates,
        flags: cached.linkFlags,
        styleOrder: cached.styleOrder,
      );
      state = await _readyState(csv, cached, cachedConfig, cachedSchedule,
          links, fromCache: true);
    }
  }

  /// Wipes local CSV sessions for any day whose server-side reset timestamp
  /// (`resetDay1At` / `resetDay2At`) is newer than the local session start.
  ///
  /// Called at ID entry and when starting Day 2, so a researcher's reset of
  /// either day takes effect on the device (the local CSV is the source of
  /// truth, but the server signal must be able to override it).
  Future<void> _applyResetSignals(CsvStore csv, Participant participant) async {
    final code = participant.participantCode;
    for (final day in const [1, 2]) {
      final resetAt = day == 1 ? participant.resetDay1At : participant.resetDay2At;
      if (resetAt == null) continue;
      final localSession = await csv.readSession(code, 'day$day');
      debugPrint('Checking reset signal for $code day$day. '
          'Server resetDay${day}At: $resetAt. '
          'Local session start: ${localSession?.startedAtLocal}');
      if (localSession != null &&
          localSession.startedAtLocal.isBefore(resetAt)) {
        debugPrint(
            'MATCH: Local day $day session is older than reset signal. Wiping...');
        await csv.deleteSessionDirectory(code, 'day$day');
        debugPrint('Local Day $day session wiped (server reset signal).');
      } else {
        debugPrint(
            'SKIP: No local day $day session or it is newer than the reset signal.');
      }
    }
  }

  Future<ParticipantEntryState> _readyState(
    CsvStore csv,
    Participant participant,
    StudyConfig config,
    DaySchedule schedule,
    QuestionnaireLinks links, {
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
      links: links,
      fromCache: fromCache,
      resumableDayId: resumable ? schedule.dayId : null,
      dayAlreadyCompleted: completed,
      // No errorMessage here: a completed day is a normal state shown via
      // the completed view, not an error. Setting one here leaks stale
      // "Day N is already completed" text into unrelated UI (e.g. the
      // Start Day 2 snackbar).
    );
  }

  /// Clears the flow back to the bare ID-entry form.
  void reset() {
    state = const ParticipantEntryState();
  }

  /// Re-fetches the participant document (e.g. to pick up a Day-2 activation
  /// from the researcher while the participant sits on the day-1 completion
  /// screen). Non-destructive: only [ParticipantEntryState.participant] is
  /// replaced.
  Future<void> refreshParticipant() async {
    final current = state.participant;
    if (current == null) return;
    try {
      final fresh = await ref
          .read(participantRepositoryProvider)
          .fetchParticipant(current.participantCode);
      state = state.copyWith(participant: fresh);
    } catch (_) {
      // Keep the cached participant on network failure.
    }
  }

  /// Loads the Day-2 schedule for the already-entered participant (pressed
  /// from the day-1 completion screen after the researcher activates Day 2).
  ///
  /// Unlike [enterCode], this does NOT reset the state to loading — the
  /// participant stays loaded the whole time, so the UI never falls back to
  /// the tutorial. Uses the fresh participant document (activeDay must be 2).
  Future<void> loadDay2() async {
    final current = state.participant;
    if (current == null) return;

    final repository = ref.read(participantRepositoryProvider);
    final store = await ref.read(localStoreProvider.future);
    final csv = ref.read(csvStoreProvider);

    // Clear any stale message from the day-1 entry flow (e.g. "Day 1 is
    // already completed") before we start.
    state = state.copyWith(errorMessage: null);

    try {
      final fresh = await repository.fetchParticipant(current.participantCode);
      debugPrint('loadDay2: fresh activeDay=${fresh.activeDay} '
          '(current was ${current.activeDay})');
      if (fresh.activeDay == 2 &&
          !await repository.hasSession(fresh.participantCode, 1)) {
        // Stale gate: activeDay=2 without a day-1 session (e.g. old reset).
        // Refuse to start Day 2 and fall back to the day-1 flow.
        debugPrint('loadDay2: activeDay=2 but no day-1 session — '
            'refusing day 2');
        state = state.copyWith(
          participant: fresh,
          errorMessage:
              'Day 2 has not been activated yet by the researcher.',
        );
        return;
      }
      if (fresh.activeDay != 2) {
        // Not activated yet — keep showing the day-1 completion screen.
        debugPrint('loadDay2: day 2 not activated yet');
        state = state.copyWith(
          participant: fresh,
          errorMessage:
              'Day 2 has not been activated yet by the researcher.',
        );
        return;
      }
      // A researcher "Reset Day 2" must wipe the stale local day-2 session
      // before we resolve state — otherwise a previously completed day 2
      // would instantly re-complete.
      await _applyResetSignals(csv, fresh);
      final config = await repository.fetchStudyConfig();
      debugPrint('loadDay2: config ok (${config.protocolVersion})');
      final templates = await repository.fetchLinkTemplates();
      debugPrint('loadDay2: templates ok');
      final style = styleForDay(fresh.styleOrder, fresh.activeDay);
      final schedule = await repository.fetchSchedule(
        fresh.participantCode,
        fresh.activeDay,
        style: style,
      );
      debugPrint('loadDay2: schedule ok (day ${schedule.dayNumber}, '
          '${schedule.reminders.length} reminders)');
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: fresh.linkFlags,
        styleOrder: fresh.styleOrder,
      );

      await store.setLastParticipantCode(fresh.participantCode);
      await store.cacheParticipant(fresh);
      await store.cacheStudyConfig(config);
      await store.cacheScheduleFor(fresh.participantCode, schedule);
      await store.cacheLinkTemplates(templates);
      debugPrint('loadDay2: cached');

      state = await _readyState(csv, fresh, config, schedule, links,
          fromCache: false);
      debugPrint('loadDay2: state updated, dayAlreadyCompleted='
          '${state.dayAlreadyCompleted}, day=${state.daySchedule?.dayNumber}');
    } on ScheduleNotFoundException {
      debugPrint('loadDay2: schedule document missing');
      state = state.copyWith(
        errorMessage:
            'Day 2 schedule is not set up yet. Please ask the researcher '
            'to save the Day 2 schedule in the admin app.',
      );
    } catch (e) {
      // Surface the failure instead of silently doing nothing.
      debugPrint('loadDay2 error: $e');
      state = state.copyWith(
        errorMessage: 'Could not start Day 2: $e',
      );
    }
  }
}
