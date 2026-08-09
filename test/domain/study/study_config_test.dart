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
    links: links,
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

    test('fill leaves templates without placeholders untouched', () {
      expect(
        QuestionnaireLinks.fill('https://forms.example/x', participantId: 'P014'),
        'https://forms.example/x',
      );
    });

    group('resolvedWith', () {
      const shared = QuestionnaireLinks(
        start: 'https://shared/start?p={participantId}',
        day1End: 'https://shared/day1?p={participantId}',
        day2End: 'https://shared/day2?p={participantId}',
        finalLink: 'https://shared/final?p={participantId}',
      );

      test('null override returns shared unchanged', () {
        expect(shared.resolvedWith(null), shared);
      });

      test('full override replaces all fields', () {
        const override = QuestionnaireLinks(
          start: 'https://override/start',
          day1End: 'https://override/day1',
          day2End: 'https://override/day2',
          finalLink: 'https://override/final',
        );
        final resolved = shared.resolvedWith(override);
        expect(resolved.start, override.start);
        expect(resolved.day1End, override.day1End);
        expect(resolved.day2End, override.day2End);
        expect(resolved.finalLink, override.finalLink);
      });

      test('partial override falls back to shared for null fields', () {
        const override = QuestionnaireLinks(
          start: 'https://override/start',
          day1End: null,
          day2End: 'https://override/day2',
          finalLink: null,
        );
        final resolved = shared.resolvedWith(override);
        expect(resolved.start, override.start);
        expect(resolved.day1End, shared.day1End);
        expect(resolved.day2End, override.day2End);
        expect(resolved.finalLink, shared.finalLink);
      });

      test('override with all nulls returns shared unchanged', () {
        const override = QuestionnaireLinks(
          start: null,
          day1End: null,
          day2End: null,
          finalLink: null,
        );
        final resolved = shared.resolvedWith(override);
        expect(resolved.start, shared.start);
        expect(resolved.day1End, shared.day1End);
        expect(resolved.day2End, shared.day2End);
        expect(resolved.finalLink, shared.finalLink);
      });

      test('empty shared with partial override picks override where set', () {
        const shared = QuestionnaireLinks();
        const override = QuestionnaireLinks(
          start: 'https://override/start',
          day1End: null,
          day2End: null,
          finalLink: null,
        );
        final resolved = shared.resolvedWith(override);
        expect(resolved.start, override.start);
        expect(resolved.day1End, null);
        expect(resolved.day2End, null);
        expect(resolved.finalLink, null);
      });
    });
  });

  group('StudyConfig JSON', () {
    test('round-trips', () {
      final restored = StudyConfig.fromJson(config.toJson());
      expect(restored.protocolVersion, config.protocolVersion);
      expect(restored.links.toJson(), config.links.toJson());
      expect(restored.defaultSchedule, kDefaultScheduleTemplate);
    });

    test('stores the final link under the protocol key "final"', () {
      expect(config.toJson()['questionnaireLinks'],
          containsPair('final', links.finalLink));
    });
  });
}
