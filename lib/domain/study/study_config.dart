import 'scheduled_reminder.dart';

/// Google Forms URL templates configured by the researcher (plan §7.2
/// `config/study`). Templates may contain `{participantId}` and `{day}`
/// placeholders, substituted when the app opens the browser.
///
/// Questionnaires live entirely outside the app; these are just links.
class QuestionnaireLinks {
  const QuestionnaireLinks({
    this.start,
    this.day1End,
    this.day2End,
    this.finalLink,
  });

  /// Pre-study questionnaire (shown on the day-start screen when set).
  final String? start;

  /// End-of-Day-1 questionnaire.
  final String? day1End;

  /// End-of-Day-2 questionnaire.
  final String? day2End;

  /// Final questionnaire (offered after Day 2 completes).
  final String? finalLink;

  /// The end-of-day link for [dayNumber] (1 or 2), if configured.
  String? endLinkForDay(int dayNumber) =>
      dayNumber == 1 ? day1End : day2End;

  /// Returns a new [QuestionnaireLinks] where each field that is non-null in
  /// [override] wins over the corresponding field in `this`. This implements
  /// per-field fallback: a null override field means "use the shared config".
  QuestionnaireLinks resolvedWith(QuestionnaireLinks? override) {
    if (override == null) return this;
    return QuestionnaireLinks(
      start: override.start ?? start,
      day1End: override.day1End ?? day1End,
      day2End: override.day2End ?? day2End,
      finalLink: override.finalLink ?? finalLink,
    );
  }

  /// Substitutes `{participantId}` and `{day}` placeholders in [template].
  static String fill(
    String template, {
    required String participantId,
    int? day,
  }) =>
      template
          .replaceAll('{participantId}', participantId)
          .replaceAll('{day}', day?.toString() ?? '');

  Map<String, Object?> toJson() => {
        'start': start,
        'day1End': day1End,
        'day2End': day2End,
        'final': finalLink,
      };

  factory QuestionnaireLinks.fromJson(Map<String, Object?> json) =>
      QuestionnaireLinks(
        start: json['start'] as String?,
        day1End: json['day1End'] as String?,
        day2End: json['day2End'] as String?,
        finalLink: json['final'] as String?,
      );
}

/// Study-wide configuration document (`config/study`), admin-written.
class StudyConfig {
  const StudyConfig({
    required this.protocolVersion,
    required this.links,
    required this.defaultSchedule,
  });

  final String protocolVersion;
  final QuestionnaireLinks links;

  /// Template copied into each new participant's per-day schedule docs.
  final List<ScheduledReminder> defaultSchedule;

  Map<String, Object?> toJson() => {
        'protocolVersion': protocolVersion,
        'questionnaireLinks': links.toJson(),
        'defaultSchedule': defaultSchedule.map((r) => r.toJson()).toList(),
      };

  factory StudyConfig.fromJson(Map<String, Object?> json) => StudyConfig(
        protocolVersion: json['protocolVersion'] as String? ?? 'unknown',
        links: json['questionnaireLinks'] != null
            ? QuestionnaireLinks.fromJson(
                (json['questionnaireLinks'] as Map).cast<String, Object?>())
            : const QuestionnaireLinks(),
        defaultSchedule: [
          if (json['defaultSchedule'] != null)
            for (final r in json['defaultSchedule'] as List)
              ScheduledReminder.fromJson((r as Map).cast<String, Object?>()),
        ],
      );
}
