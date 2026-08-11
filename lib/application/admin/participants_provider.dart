import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/study/participant.dart';
import '../../domain/study/scheduled_reminder.dart';
import '../../domain/study/study_enums.dart';
import '../../domain/study/study_links.dart';
import '../../domain/study/study_session.dart';
import 'admin_providers.dart';

part 'participants_provider.g.dart';

/// Participant list with admin actions. Refresh after each mutation.
@riverpod
class AdminParticipants extends _$AdminParticipants {
  @override
  Future<List<Participant>> build() =>
      ref.watch(adminRepositoryProvider).listParticipants();

  Future<void> createParticipant({
    required int serial,
    required StyleOrder styleOrder,
    required bool assignmentOverride,
  }) async {
    await ref.read(adminRepositoryProvider).createParticipant(
          serial: serial,
          styleOrder: styleOrder,
          assignmentOverride: assignmentOverride,
        );
    ref.invalidateSelf();
  }

  Future<void> setActiveDay(String participantCode, int day) async {
    await ref
        .read(adminRepositoryProvider)
        .setActiveDay(participantCode, day);
    ref.invalidateSelf();
  }

  Future<void> resetDay(String participantCode, int day) async {
    await ref.read(adminRepositoryProvider).resetDay(participantCode, day);
    ref.invalidateSelf();
  }

  Future<void> setStyleOrder(String participantCode, StyleOrder order,
      {required bool assignmentOverride}) async {
    await ref.read(adminRepositoryProvider).setStyleOrder(participantCode,
        order, assignmentOverride: assignmentOverride);
    ref.invalidateSelf();
  }

  Future<void> saveSchedule(String participantCode, int dayNumber,
      List<ScheduledReminder> reminders) async {
    await ref
        .read(adminRepositoryProvider)
        .saveSchedule(participantCode, dayNumber, reminders);
  }

  Future<void> saveParticipantLinkFlags(
      String participantCode, ParticipantLinkFlags flags) async {
    await ref
        .read(adminRepositoryProvider)
        .saveParticipantLinkFlags(participantCode, flags);
    ref.invalidateSelf();
  }
}

/// Sessions + per-day event tallies for the detail page.
class ParticipantDetail {
  const ParticipantDetail({required this.sessions, required this.eventCounts});

  /// `[day1, day2]`, each null when the day was never started.
  final List<StudySession?> sessions;

  /// dayId → {total, delivered, completedOutcome, notDelivered}
  final Map<String, Map<String, int>> eventCounts;
}

@riverpod
Future<ParticipantDetail> participantDetail(Ref ref, String code) async {
  final repo = ref.watch(adminRepositoryProvider);
  final sessions = await repo.getSessions(code);
  final counts = <String, Map<String, int>>{};
  for (final dayId in const ['day1', 'day2']) {
    final events = await repo.getEvents(code, dayId);
    counts[dayId] = {
      'total': events.length,
      'delivered':
          events.where((e) => e.deliveryStatus == DeliveryStatus.delivered).length,
      'completedOutcome':
          events.where((e) => e.outcome == ResponseOutcome.completed).length,
      'notDelivered': events
          .where((e) =>
              e.deliveryStatus == DeliveryStatus.failed ||
              e.deliveryStatus == DeliveryStatus.suppressed ||
              e.deliveryStatus == DeliveryStatus.notDisplayed)
          .length,
    };
  }
  return ParticipantDetail(sessions: sessions, eventCounts: counts);
}
