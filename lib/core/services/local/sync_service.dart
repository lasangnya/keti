import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../application/study/participant_providers.dart';
import '../../../domain/study/reminder_event.dart';
import '../../../domain/study/study_session.dart';
import '../../services/firebase/firestore_providers.dart';
import '../../services/firestore/reminder_event_repository.dart';
import '../../services/firestore/session_repository.dart';
import 'csv_store.dart';

part 'sync_service.g.dart';

/// Result of a reconciliation pass over one participant.
class SyncResult {
  const SyncResult({this.synced = 0, this.failed = 0, this.messages = const []});

  final int synced;
  final int failed;
  final List<String> messages;
}

/// Belt-and-braces CSV→Firestore reconciliation (plan §6.4).
///
/// When a session was started entirely offline the Firestore docs don't exist
/// — every event write went to the CSVs and the *remote* operations were
/// silently dropped. This runs on participant-code entry (and can run at any
/// time, since all writes are idempotent) to backfill missing Firestore
/// documents and push lifecycle updates.
@riverpod
SyncService syncService(Ref ref) => SyncService(
      csvStore: ref.watch(csvStoreProvider),
      sessionRepo: ref.watch(sessionRepositoryProvider),
      eventRepo: ref.watch(reminderEventRepositoryProvider),
    );

class SyncService {
  SyncService({
    required CsvStore csvStore,
    required SessionRepository sessionRepo,
    required ReminderEventRepository eventRepo,
  })  : _csv = csvStore,
        _sessions = sessionRepo,
        _events = eventRepo;

  final CsvStore _csv;
  final SessionRepository _sessions;
  final ReminderEventRepository _events;

  /// Reconciles every day directory that has a CSV store for [participantCode]
  /// (day1, day2), creating missing Firestore documents and pushing lifecycle
  /// updates where the local state is ahead.
  Future<SyncResult> reconcileParticipant(String participantCode) async {
    int synced = 0, failed = 0;
    final messages = <String>[];

    for (final dayId in const ['day1', 'day2']) {
      final hasSession = await _csv.hasSession(participantCode, dayId);
      if (!hasSession) continue;

      final localSession = await _csv.readSession(participantCode, dayId);
      if (localSession == null) continue;

      // ── Session document ───────────────────────────────────────
      try {
        final remoteSession =
            await _sessions.getSession(participantCode, dayId);
        if (remoteSession == null) {
          await _sessions.createSession(localSession);
          messages.add('Backfilled session doc $dayId.');
        } else if (localSession.status == StudySessionStatus.completed &&
            remoteSession.status != StudySessionStatus.completed) {
          await _sessions.completeSession(participantCode, dayId);
        }
      } catch (e) {
        failed++;
        messages.add('Session $dayId sync failed: $e');
        continue;
      }

      // ── Reminder events ────────────────────────────────────────
      final localEvents = await _csv.readEvents(participantCode, dayId);
      if (localEvents == null || localEvents.isEmpty) continue;

      try {
        final remoteEvents =
            await _events.getEvents(participantCode, dayId);
        final remoteMap = <String, ReminderEvent>{
          for (final e in remoteEvents) e.eventId: e,
        };

        final missing = localEvents
            .where((e) => !remoteMap.containsKey(e.eventId))
            .toList();
        if (missing.isNotEmpty) {
          await _events.createScheduledEvents(
              participantCode, dayId, missing);
          synced += missing.length;
          messages.add(
              'Backfilled ${missing.length} missing event docs for $dayId.');
        }

        for (final local in localEvents) {
          final remote = remoteMap[local.eventId];
          if (remote == null) continue; // just backfilled above
          if (_needsUpdate(local, remote)) {
            await _events.updateEventLifecycle(
                participantCode, dayId, local);
            synced++;
          }
        }
      } catch (e) {
        failed++;
        messages.add('Events $dayId sync failed: $e');
      }
    }

    return SyncResult(synced: synced, failed: failed, messages: messages);
  }

  /// True when the local copy carries a later lifecycle state than the
  /// Firestore side — both are represented by their CSV serialization, so
  /// the comparison only measures protocol fields (no server timestamps).
  static bool _needsUpdate(ReminderEvent local, ReminderEvent remote) =>
      local.toCsvRow().toString() != remote.toCsvRow().toString();
}
