import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/domain/study/study_enums.dart';

Participant buildParticipant() => const Participant(
      participantCode: 'P014',
      serial: 14,
      styleOrder: StyleOrder.characterFirst,
      assignmentOverride: false,
      activeDay: 1,
      environment: 'study',
      protocolVersion: '2026-08-v1',
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
  });
}
