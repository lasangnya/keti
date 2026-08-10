import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/condition_assignment.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  group('styleOrderForSerial (counterbalancing parity)', () {
    test('odd serials get ambient first', () {
      expect(styleOrderForSerial(1), StyleOrder.ambientFirst);
      expect(styleOrderForSerial(13), StyleOrder.ambientFirst);
      expect(styleOrderForSerial(99), StyleOrder.ambientFirst);
    });

    test('even serials get character first', () {
      expect(styleOrderForSerial(2), StyleOrder.characterFirst);
      expect(styleOrderForSerial(14), StyleOrder.characterFirst);
      expect(styleOrderForSerial(100), StyleOrder.characterFirst);
    });
  });

  group('styleForDay', () {
    test('ambient-first order', () {
      expect(styleForDay(StyleOrder.ambientFirst, 1), PresentationStyle.ambient);
      expect(styleForDay(StyleOrder.ambientFirst, 2),
          PresentationStyle.characterBased);
    });

    test('character-first order', () {
      expect(styleForDay(StyleOrder.characterFirst, 1),
          PresentationStyle.characterBased);
      expect(styleForDay(StyleOrder.characterFirst, 2), PresentationStyle.ambient);
    });

    test('rejects invalid day numbers', () {
      expect(() => styleForDay(StyleOrder.ambientFirst, 0), throwsArgumentError);
      expect(() => styleForDay(StyleOrder.ambientFirst, 3), throwsArgumentError);
    });
  });
}
