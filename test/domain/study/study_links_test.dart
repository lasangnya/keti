import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_links.dart';

const templates = StudyLinkTemplates(
  preStudy: 'https://forms.example/pre?pid={participantId}',
  endOfDayType1: 'https://forms.example/ambient?pid={participantId}',
  endOfDayType2: 'https://forms.example/character?pid={participantId}',
  finalLink: 'https://forms.example/final?pid={participantId}',
);

void main() {
  group('StudyLinkTemplates JSON', () {
    test('round-trips', () {
      final restored = StudyLinkTemplates.fromJson(templates.toJson());
      expect(restored.preStudy, templates.preStudy);
      expect(restored.endOfDayType1, templates.endOfDayType1);
      expect(restored.endOfDayType2, templates.endOfDayType2);
      expect(restored.finalLink, templates.finalLink);
    });

    test('stores the final link under the wire key "final"', () {
      expect(templates.toJson(), containsPair('final', templates.finalLink));
    });

    test('fill substitutes the participant placeholder', () {
      expect(
        StudyLinkTemplates.fill(templates.preStudy!, participantId: 'P014'),
        'https://forms.example/pre?pid=P014',
      );
    });
  });

  group('ParticipantLinkFlags', () {
    test('fromJson defaults missing flags to all-on', () {
      final flags = ParticipantLinkFlags.fromJson(null);
      expect(flags.preStudy, isTrue);
      expect(flags.endOfDay1, isTrue);
      expect(flags.endOfDay2, isTrue);
      expect(flags.finalQuestionnaire, isTrue);
    });

    test('fromJson parses stored booleans', () {
      final flags = ParticipantLinkFlags.fromJson(const {
        'preStudy': false,
        'endOfDay1': true,
        'endOfDay2': false,
        'final': true,
      });
      expect(flags.preStudy, isFalse);
      expect(flags.endOfDay1, isTrue);
      expect(flags.endOfDay2, isFalse);
      expect(flags.finalQuestionnaire, isTrue);
    });

    test('round-trips through JSON', () {
      const flags = ParticipantLinkFlags(
        preStudy: false,
        endOfDay1: true,
        endOfDay2: false,
        finalQuestionnaire: true,
      );
      final restored = ParticipantLinkFlags.fromJson(flags.toJson());
      expect(restored.toJson(), flags.toJson());
    });
  });

  group('resolveQuestionnaireLinks', () {
    const allOn = ParticipantLinkFlags.allOn();
    const allOff = ParticipantLinkFlags.allOff();

    test('ambient-first: day 1 uses type 1, day 2 uses type 2', () {
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: allOn,
        styleOrder: StyleOrder.ambientFirst,
      );
      expect(links.start, templates.preStudy);
      expect(links.day1End, templates.endOfDayType1);
      expect(links.day2End, templates.endOfDayType2);
      expect(links.finalLink, templates.finalLink);
    });

    test('character-first: day 1 uses type 2, day 2 uses type 1 (alternates)',
        () {
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: allOn,
        styleOrder: StyleOrder.characterFirst,
      );
      expect(links.day1End, templates.endOfDayType2);
      expect(links.day2End, templates.endOfDayType1);
    });

    test('all-off flags resolve to null links', () {
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: allOff,
        styleOrder: StyleOrder.ambientFirst,
      );
      expect(links.start, isNull);
      expect(links.day1End, isNull);
      expect(links.day2End, isNull);
      expect(links.finalLink, isNull);
    });

    test('per-day toggles gate the end-of-day links independently', () {
      const flags = ParticipantLinkFlags(
        preStudy: true,
        endOfDay1: false,
        endOfDay2: true,
        finalQuestionnaire: false,
      );
      final links = resolveQuestionnaireLinks(
        templates: templates,
        flags: flags,
        styleOrder: StyleOrder.ambientFirst,
      );
      expect(links.start, templates.preStudy);
      expect(links.day1End, isNull);
      expect(links.day2End, templates.endOfDayType2);
      expect(links.finalLink, isNull);
    });

    test('missing templates yield null even when flags are on', () {
      final links = resolveQuestionnaireLinks(
        templates: const StudyLinkTemplates(),
        flags: allOn,
        styleOrder: StyleOrder.ambientFirst,
      );
      expect(links.start, isNull);
      expect(links.day1End, isNull);
      expect(links.day2End, isNull);
      expect(links.finalLink, isNull);
    });
  });
}
