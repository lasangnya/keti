import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/admin/admin_providers.dart';
import 'package:keti/core/services/admin/admin_repository.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_links.dart';
import 'package:keti/domain/study/study_session.dart';

void main() {
  test('participantSchedule fetches reminders and the saved flag for a day',
      () async {
    final reminders = [
      ScheduledReminder(
        reminderNumber: 1,
        offset: const Duration(minutes: 5),
        placement: Placement.cursorProximate,
        kind: ReminderKind.hydration,
        variantNumber: 1,
      ),
    ];
    final repo = _FakeAdminRepository(schedule: reminders, saved: true);

    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(participantScheduleProvider('P014', 1).future);

    expect(result.reminders, reminders);
    expect(result.saved, isTrue);
    expect(repo.lastGetScheduleCode, 'P014');
    expect(repo.lastGetScheduleDay, 1);
  });

  test('participantSchedule reports saved=false when no schedule exists',
      () async {
    final repo = _FakeAdminRepository(schedule: const [], saved: false);

    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(participantScheduleProvider('P001', 2).future);

    expect(result.reminders, isEmpty);
    expect(result.saved, isFalse);
    expect(repo.lastHasSavedScheduleCode, 'P001');
    expect(repo.lastHasSavedScheduleDay, 2);
  });
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({required this.schedule, required this.saved});

  final List<ScheduledReminder> schedule;
  final bool saved;

  String? lastGetScheduleCode;
  int? lastGetScheduleDay;
  String? lastHasSavedScheduleCode;
  int? lastHasSavedScheduleDay;

  @override
  Future<List<ScheduledReminder>> getSchedule(
      String participantCode, int dayNumber) async {
    lastGetScheduleCode = participantCode;
    lastGetScheduleDay = dayNumber;
    return schedule;
  }

  @override
  Future<bool> hasSavedSchedule(String participantCode, int dayNumber) async {
    lastHasSavedScheduleCode = participantCode;
    lastHasSavedScheduleDay = dayNumber;
    return saved;
  }

  @override
  Future<List<Participant>> listParticipants() => throw UnimplementedError();

  @override
  Future<StudyConfig> getConfig() => throw UnimplementedError();

  @override
  Future<StudyLinkTemplates> getLinkTemplates() => throw UnimplementedError();

  @override
  Future<void> saveLinkTemplates(StudyLinkTemplates templates) =>
      throw UnimplementedError();

  @override
  Future<Participant> createParticipant({
    required int serial,
    required StyleOrder styleOrder,
    required bool assignmentOverride,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setActiveDay(String participantCode, int day) =>
      throw UnimplementedError();

  @override
  Future<void> resetDay(String participantCode, int day) =>
      throw UnimplementedError();

  @override
  Future<void> resetParticipant(String participantCode) =>
      throw UnimplementedError();

  @override
  Future<void> setStyleOrder(
    String participantCode,
    StyleOrder order, {
    required bool assignmentOverride,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveParticipantLinkFlags(
          String participantCode, ParticipantLinkFlags flags) =>
      throw UnimplementedError();

  @override
  Future<void> saveSchedule(
          String participantCode, int dayNumber, List<ScheduledReminder> reminders) =>
      throw UnimplementedError();

  @override
  Future<List<StudySession?>> getSessions(String participantCode) =>
      throw UnimplementedError();

  @override
  Future<List<ReminderEvent>> getEvents(String participantCode, String dayId) =>
      throw UnimplementedError();
}
