import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';

void main() {
  const links = QuestionnaireLinks(
    start: 'https://forms.example/start?pid={participantId}',
    day1End: 'https://forms.example/end?pid={participantId}&day={day}',
    day2End: 'https://forms.example/end2?pid={participantId}&day={day}',
    finalLink: 'https://forms.example/final?pid={participantId}',
  );

  const config = StudyConfig(
    protocolVersion: '2026-08-v1',
    defaultSchedule: kDefaultScheduleTemplate,
  );

  group('QuestionnaireLinks', () {
    test('endLinkForDay picks the right template', () {
      expect(links.endLinkForDay(1), links.day1End);
      expect(links.endLinkForDay(2), links.day2End);
      expect(const QuestionnaireLinks().endLinkForDay(1), isNull);
    });

    test('fill substitutes participant and day placeholders', () {
      final filled = QuestionnaireLinks.fill(
        links.day1End!,
        participantId: 'P014',
        day: 1,
      );
      expect(filled, 'https://forms.example/end?pid=P014&day=1');
    });

    test('fill substitutes the session placeholder from the day', () {
      final template = 'https://forms.example/end?entry.1={participantId}'
          '&entry.2={session}';
      expect(
        QuestionnaireLinks.fill(template, participantId: 'P014', day: 1),
        'https://forms.example/end?entry.1=P014&entry.2=Session+1',
      );
      expect(
        QuestionnaireLinks.fill(template, participantId: 'P014', day: 2),
        'https://forms.example/end?entry.1=P014&entry.2=Session+2',
      );
      // No day → placeholder removed, nothing substituted.
      expect(
        QuestionnaireLinks.fill(template, participantId: 'P014'),
        'https://forms.example/end?entry.1=P014&entry.2=',
      );
    });

    test('fill leaves templates without placeholders untouched', () {
      expect(
        QuestionnaireLinks.fill('https://forms.example/x', participantId: 'P014'),
        'https://forms.example/x',
      );
    });
  });

  group('StudyConfig JSON', () {
    test('round-trips', () {
      final restored = StudyConfig.fromJson(config.toJson());
      expect(restored.protocolVersion, config.protocolVersion);
      expect(restored.defaultSchedule, kDefaultScheduleTemplate);
    });

    test('does not carry questionnaire links (they live in links/templates)',
        () {
      expect(config.toJson().containsKey('questionnaireLinks'), isFalse);
    });
  });
}

