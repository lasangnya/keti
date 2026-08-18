import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/study/day_schedule.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_links.dart';

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
  static String _keyResetWatermark(String code) => 'reset.watermark.$code';

  // ── Last entered participant code (ID-entry pre-fill) ────────────

  String? get lastParticipantCode => _prefs.getString(_keyLastCode);

  Future<void> setLastParticipantCode(String code) =>
      _prefs.setString(_keyLastCode, code);

  // ── In-app tutorial (shown once per participant) ─────────────────

  bool isTutorialSeen(String code) => _prefs.getBool(_keyTutorialSeen(code)) ?? false;

  Future<void> setTutorialSeen(String code) =>
      _prefs.setBool(_keyTutorialSeen(code), true);

  /// Clears the tutorial-seen flag (full participant reset — the tutorial
  /// must show again so the participant starts over completely fresh).
  Future<void> clearTutorialSeen(String code) =>
      _prefs.remove(_keyTutorialSeen(code));

  /// The last applied full-reset signal for [code] (ISO string of the
  /// participant document's `resetAllAt`), used to apply each full reset
  /// exactly once.
  String? readResetWatermark(String code) =>
      _prefs.getString(_keyResetWatermark(code));

  Future<void> setResetWatermark(String code, String value) =>
      _prefs.setString(_keyResetWatermark(code), value);

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

  // ── Cached link templates (offline ID entry) ─────────────────────

  static const _keyLinkTemplates = 'cache.linkTemplates';

  Future<void> cacheLinkTemplates(StudyLinkTemplates templates) =>
      _prefs.setString(_keyLinkTemplates, jsonEncode(templates.toJson()));

  StudyLinkTemplates readCachedLinkTemplates() {
    final raw = _prefs.getString(_keyLinkTemplates);
    if (raw == null) return const StudyLinkTemplates();
    return StudyLinkTemplates.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>());
  }

  // ── Active session pointer (resume after accidental quit) ────────

  Future<void> setActiveSession(String code, String dayId) =>
      _prefs.setString(_keyActiveSession(code), dayId);

  /// The unfinished day for [code], if any (e.g. `day1`).
  String? readActiveSession(String code) =>
      _prefs.getString(_keyActiveSession(code));

  Future<void> clearActiveSession(String code) =>
      _prefs.remove(_keyActiveSession(code));

  /// Removes every cached document for [code] (participant, both day
  /// schedules, active-session pointer) — part of a full participant reset.
  Future<void> forgetCachedParticipant(String code) async {
    await _prefs.remove(_keyParticipant(code));
    await _prefs.remove(_keySchedule(code, 'day1'));
    await _prefs.remove(_keySchedule(code, 'day2'));
    await _prefs.remove(_keyActiveSession(code));
  }
}
