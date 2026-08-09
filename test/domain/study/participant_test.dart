import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';

const overrideLinks = QuestionnaireLinks(
  start: 'https://override/start?p={participantId}',
  day1End: null,
  day2End: 'https://override/day2?p={participantId}',
  finalLink: null,
);

Participant buildParticipant({QuestionnaireLinks? questionnaireLinks}) =>
    Participant(
      participantCode: 'P014',
      serial: 14,
      styleOrder: StyleOrder.characterFirst,
      assignmentOverride: false,
      activeDay: 1,
      environment: 'study',
      protocolVersion: '2026-08-v1',
      questionnaireLinks: questionnaireLinks,
    );

void main() {
  group('Participant.isValidCode', () {
    test('accepts P followed by 3–4 digits, any case', () {
      expect(Participant.isValidCode('P001'), isTrue);
      expect(Participant.isValidCode('p014'), isTrue);
      expect(Participant.isValidCode('P9999'), isTrue);
    });

    test('rejects malformed codes', () {
      expect(Participant.isValidCode(''), isFalse);
      expect(Participant.isValidCode('P01'), isFalse);
      expect(Participant.isValidCode('P00001'), isFalse);
      expect(Participant.isValidCode('A001'), isFalse);
      expect(Participant.isValidCode('P01A'), isFalse);
    });
  });

  group('Participant JSON', () {
    test('round-trips', () {
      final participant = buildParticipant();
      final restored = Participant.fromJson(participant.toJson());
      expect(restored.toJson(), participant.toJson());
    });

    test('uses the Firestore field names', () {
      final json = buildParticipant().toJson();
      expect(json['participantCode'], 'P014');
      expect(json['serial'], 14);
      expect(json['styleOrder'], 'CHARACTER_FIRST');
      expect(json['activeDay'], 1);
    });

    test('round-trips with questionnaireLinks override', () {
      final participant = buildParticipant(questionnaireLinks: overrideLinks);
      final restored = Participant.fromJson(participant.toJson());
      expect(restored.questionnaireLinks?.toJson(), overrideLinks.toJson());
    });

    test('fromJson tolerates missing questionnaireLinks field', () {
      final json = buildParticipant().toJson()
        ..remove('questionnaireLinks');
      final restored = Participant.fromJson(json);
      expect(restored.questionnaireLinks, isNull);
    });

    test('fromJson tolerates null questionnaireLinks field', () {
      final json = buildParticipant().toJson()
        ..['questionnaireLinks'] = null;
      final restored = Participant.fromJson(json);
      expect(restored.questionnaireLinks, isNull);
    });
  });

  group('Participant CSV', () {
    test('header includes questionnaireLinks column', () {
      expect(Participant.csvHeader, contains('questionnaireLinks'));
    });

    test('toCsvRow serialises questionnaireLinks as JSON', () {
      final participant = buildParticipant(questionnaireLinks: overrideLinks);
      final row = participant.toCsvRow();
      final linksIndex = Participant.csvHeader.indexOf('questionnaireLinks');
      expect(row[linksIndex], jsonEncode(overrideLinks.toJson()));
    });

    test('toCsvRow includes null when no override', () {
      final participant = buildParticipant();
      final row = participant.toCsvRow();
      final linksIndex = Participant.csvHeader.indexOf('questionnaireLinks');
      expect(row[linksIndex], isNull);
    });
  });
}
