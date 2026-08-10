import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/study/day_schedule.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';

/// Key-value local store (plan §6.1 `local_store.dart`).
///
/// Holds everything the app needs to survive a relaunch without a network:
/// the last entered participant code (pre-fill), cached participant/config/
/// schedule documents (offline start), and the active-session pointer used
/// to offer resume after an accidental quit.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLastCode = 'lastParticipantCode';
  static String _keyParticipant(String code) => 'cache.participant.$code';
  static const _keyConfig = 'cache.studyConfig';
  static String _keySchedule(String code, String dayId) =>
      'cache.schedule.$code.$dayId';
  static String _keyActiveSession(String code) => 'session.active.$code';
  static String _keyTutorialSeen(String code) => 'tutorial.seen.$code';
  static String _keyQuestionnaire(String code, String dayId) =>
      'questionnaire.completed.$code.$dayId';

  // ── Last entered participant code (ID-entry pre-fill) ────────────

  String? get lastParticipantCode => _prefs.getString(_keyLastCode);

  Future<void> setLastParticipantCode(String code) =>
      _prefs.setString(_keyLastCode, code);

  // ── In-app tutorial (shown once per participant) ─────────────────

  bool isTutorialSeen(String code) => _prefs.getBool(_keyTutorialSeen(code)) ?? false;

  Future<void> setTutorialSeen(String code) =>
      _prefs.setBool(_keyTutorialSeen(code), true);

  // ── Questionnaire completion (participant self-declared) ─────────

  bool isQuestionnaireCompleted(String code, String dayId) =>
      _prefs.getBool(_keyQuestionnaire(code, dayId)) ?? false;

  Future<void> setQuestionnaireCompleted(String code, String dayId) =>
      _prefs.setBool(_keyQuestionnaire(code, dayId), true);

  // ── Cached Firestore documents (offline fallback) ────────────────

  Future<void> cacheParticipant(Participant participant) => _prefs.setString(
        _keyParticipant(participant.participantCode),
        jsonEncode(participant.toJson()),
      );

  Participant? readCachedParticipant(String code) {
    final raw = _prefs.getString(_keyParticipant(code));
    if (raw == null) return null;
    return Participant.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>());
  }

  Future<void> cacheStudyConfig(StudyConfig config) =>
      _prefs.setString(_keyConfig, jsonEncode(config.toJson()));

  StudyConfig? readCachedStudyConfig() {
    final raw = _prefs.getString(_keyConfig);
    if (raw == null) return null;
    return StudyConfig.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>());
  }

  /// Schedules are cached per participant and day.
  Future<void> cacheScheduleFor(String code, DaySchedule schedule) =>
      _prefs.setString(
        _keySchedule(code, schedule.dayId),
        jsonEncode(schedule.toJson()),
      );

  DaySchedule? readCachedSchedule(
    String code,
    String dayId, {
    required PresentationStyle style,
  }) {
    final raw = _prefs.getString(_keySchedule(code, dayId));
    if (raw == null) return null;
    return DaySchedule.fromJson((jsonDecode(raw) as Map).cast<String, Object?>(),
        style: style);
  }

  // ── Active session pointer (resume after accidental quit) ────────

  Future<void> setActiveSession(String code, String dayId) =>
      _prefs.setString(_keyActiveSession(code), dayId);

  /// The unfinished day for [code], if any (e.g. `day1`).
  String? readActiveSession(String code) =>
      _prefs.getString(_keyActiveSession(code));

  Future<void> clearActiveSession(String code) =>
      _prefs.remove(_keyActiveSession(code));
}
