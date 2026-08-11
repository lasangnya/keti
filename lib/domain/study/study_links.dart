import 'condition_assignment.dart';
import 'study_config.dart' show QuestionnaireLinks;
import 'study_enums.dart';

/// The four questionnaire URL templates, stored globally in the `links`
/// collection (`links/templates`), plan §3.1/§3.5.
///
/// End-of-day forms come in two variants because the two presentation
/// styles use different questionnaires:
///   - [endOfDayType1] — used on **ambient** days
///   - [endOfDayType2] — used on **character** days
/// The participant's day style comes from its counterbalancing order, so the
/// two study days always alternate between type 1 and type 2 automatically.
///
/// Templates contain the `{participantId}` placeholder (and `{day}` where the
/// researcher wants it), substituted when the app opens the browser.
class StudyLinkTemplates {
  const StudyLinkTemplates({
    this.preStudy,
    this.endOfDayType1,
    this.endOfDayType2,
    this.finalLink,
  });

  /// Pre-study questionnaire (shown on the tutorial's "Before you begin"
  /// step when enabled).
  final String? preStudy;

  /// End-of-day questionnaire for ambient-style days.
  final String? endOfDayType1;

  /// End-of-day questionnaire for character-based days.
  final String? endOfDayType2;

  /// Final questionnaire (offered after Day 2 completes).
  final String? finalLink;

  /// Substitutes placeholders in [template]:
  ///  - `{participantId}` → the participant code (e.g. `P014`)
  ///  - `{day}` → the day number (e.g. `1`)
  ///  - `{session}` → `Session 1` / `Session 2` from [day] (for Google Forms
  ///    multiple-choice prefill; the value is URL-encoded)
  static String fill(String template, {required String participantId, int? day}) =>
      template
          .replaceAll('{participantId}', participantId)
          .replaceAll('{day}', day?.toString() ?? '')
          .replaceAll(
              '{session}',
              day == null ? '' : Uri.encodeQueryComponent('Session $day'));

  Map<String, Object?> toJson() => {
        'preStudy': preStudy,
        'endOfDayType1': endOfDayType1,
        'endOfDayType2': endOfDayType2,
        'final': finalLink,
      };

  factory StudyLinkTemplates.fromJson(Map<String, Object?> json) =>
      StudyLinkTemplates(
        preStudy: json['preStudy'] as String?,
        endOfDayType1: json['endOfDayType1'] as String?,
        endOfDayType2: json['endOfDayType2'] as String?,
        finalLink: json['final'] as String?,
      );
}

/// Per-participant switches deciding which questionnaires the participant is
/// offered (stored on the participant document as `linkFlags`).
///
/// The end-of-day toggles are per study day; which of the two form types is
/// used on that day follows automatically from the day's presentation style
/// (see [resolveQuestionnaireLinks]).
class ParticipantLinkFlags {
  const ParticipantLinkFlags({
    required this.preStudy,
    required this.endOfDay1,
    required this.endOfDay2,
    required this.finalQuestionnaire,
  });

  /// All links enabled (default for new/legacy participants).
  const ParticipantLinkFlags.allOn()
      : preStudy = true,
        endOfDay1 = true,
        endOfDay2 = true,
        finalQuestionnaire = true;

  /// All links disabled.
  const ParticipantLinkFlags.allOff()
      : preStudy = false,
        endOfDay1 = false,
        endOfDay2 = false,
        finalQuestionnaire = false;

  final bool preStudy;
  final bool endOfDay1;
  final bool endOfDay2;
  final bool finalQuestionnaire;

  /// Missing flags default to all-on so legacy participants keep their
  /// questionnaires until the researcher explicitly switches them off.
  factory ParticipantLinkFlags.fromJson(Map<String, Object?>? json) {
    if (json == null) return const ParticipantLinkFlags.allOn();
    bool flag(String key) => json[key] as bool? ?? true;
    return ParticipantLinkFlags(
      preStudy: flag('preStudy'),
      endOfDay1: flag('endOfDay1'),
      endOfDay2: flag('endOfDay2'),
      finalQuestionnaire: flag('final'),
    );
  }

  Map<String, Object?> toJson() => {
        'preStudy': preStudy,
        'endOfDay1': endOfDay1,
        'endOfDay2': endOfDay2,
        'final': finalQuestionnaire,
      };
}

/// Resolves the participant's effective questionnaire links from the global
/// templates, the participant's own toggles, and its counterbalancing order.
///
/// The end-of-day link for a day is `endOfDayType1` when that day runs in the
/// ambient style and `endOfDayType2` in the character style — so the two days
/// alternate form types automatically (they can never use the same one).
QuestionnaireLinks resolveQuestionnaireLinks({
  required StudyLinkTemplates templates,
  required ParticipantLinkFlags flags,
  required StyleOrder styleOrder,
}) {
  String? endOfDayLinkFor(int dayNumber) {
    if (dayNumber == 1 && !flags.endOfDay1) return null;
    if (dayNumber == 2 && !flags.endOfDay2) return null;
    final style = styleForDay(styleOrder, dayNumber);
    return style == PresentationStyle.ambient
        ? templates.endOfDayType1
        : templates.endOfDayType2;
  }

  return QuestionnaireLinks(
    start: flags.preStudy ? templates.preStudy : null,
    day1End: endOfDayLinkFor(1),
    day2End: endOfDayLinkFor(2),
    finalLink: flags.finalQuestionnaire ? templates.finalLink : null,
  );
}
