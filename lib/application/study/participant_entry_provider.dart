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
      final participant = await repository.fetchParticipant(code);
      final config = await repository.fetchStudyConfig();
      final templates = await repository.fetchLinkTemplates();
      final style = styleForDay(participant.styleOrder, participant.activeDay);
      final schedule = await repository.fetchSchedule(
        participant.participantCode,
        participant.activeDay,
        style: style,
      );
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: participant.linkFlags,
        styleOrder: participant.styleOrder,
      );

      // --- NEW: Reset Day 1 signal detection ---
      if (participant.resetDay1At != null) {
        final localSession = await csv.readSession(participant.participantCode, 'day1');
        debugPrint('Checking reset signal for ${participant.participantCode}. '
            'Server resetDay1At: ${participant.resetDay1At}. '
            'Local session start: ${localSession?.startedAtLocal}');
            
        if (localSession != null) {
          if (localSession.startedAtLocal.isBefore(participant.resetDay1At!)) {
            debugPrint('MATCH: Local session is older than reset signal. Wiping...');
            await csv.deleteSessionDirectory(participant.participantCode, 'day1');
            debugPrint('Local Day 1 session wiped (server reset signal).');
          } else {
            debugPrint('SKIP: Local session is newer than or equal to reset signal.');
          }
        } else {
          debugPrint('SKIP: No local session found for day1.');
        }
      }

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
      errorMessage:
          completed ? 'Day ${schedule.dayNumber} is already completed for '
              '${participant.participantCode}.' : null,
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
}
