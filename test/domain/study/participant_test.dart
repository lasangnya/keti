import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_links.dart';

const customFlags = ParticipantLinkFlags(
  preStudy: false,
  endOfDay1: true,
  endOfDay2: false,
  finalQuestionnaire: true,
);

Participant buildParticipant({ParticipantLinkFlags? linkFlags}) => Participant(
      participantCode: 'P014',
      serial: 14,
      styleOrder: StyleOrder.characterFirst,
      assignmentOverride: false,
      activeDay: 1,
      environment: 'study',
      protocolVersion: '2026-08-v1',
      linkFlags: linkFlags ?? const ParticipantLinkFlags.allOn(),
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

    test('round-trips with linkFlags', () {
      final participant = buildParticipant(linkFlags: customFlags);
      final restored = Participant.fromJson(participant.toJson());
      expect(restored.linkFlags.preStudy, false);
      expect(restored.linkFlags.endOfDay1, true);
      expect(restored.linkFlags.endOfDay2, false);
      expect(restored.linkFlags.finalQuestionnaire, true);
    });

    test('fromJson defaults missing linkFlags to all-on', () {
      final json = buildParticipant().toJson()..remove('linkFlags');
      final restored = Participant.fromJson(json);
      expect(restored.linkFlags.preStudy, isTrue);
      expect(restored.linkFlags.endOfDay1, isTrue);
      expect(restored.linkFlags.endOfDay2, isTrue);
      expect(restored.linkFlags.finalQuestionnaire, isTrue);
    });

    test('fromJson tolerates null linkFlags field', () {
      final json = buildParticipant().toJson()..['linkFlags'] = null;
      final restored = Participant.fromJson(json);
      expect(restored.linkFlags.finalQuestionnaire, isTrue);
    });
  });

  group('Participant CSV', () {
    test('header includes linkFlags column', () {
      expect(Participant.csvHeader, contains('linkFlags'));
    });

    test('toCsvRow serialises linkFlags as JSON', () {
      final participant = buildParticipant(linkFlags: customFlags);
      final row = participant.toCsvRow();
      final index = Participant.csvHeader.indexOf('linkFlags');
      expect(row[index], jsonEncode(customFlags.toJson()));
    });

    test('toCsvRow includes all-on flags by default', () {
      final participant = buildParticipant();
      final row = participant.toCsvRow();
      final index = Participant.csvHeader.indexOf('linkFlags');
      expect(jsonDecode(row[index] as String),
          const ParticipantLinkFlags.allOn().toJson());
    });
  });
}
