import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  group('enum wire values (protocol-frozen)', () {
    test('Placement wire names', () {
      expect(Placement.cursorProximate.wireName, 'CURSOR_PROXIMATE');
      expect(Placement.notchCard.wireName, 'NOTCH_CARD');
      expect(Placement.systemTray.wireName, 'SYSTEM_TRAY');
    });

    test('PresentationStyle wire names', () {
      expect(PresentationStyle.ambient.wireName, 'AMBIENT');
      expect(PresentationStyle.characterBased.wireName, 'CHARACTER_BASED');
    });

    test('ReminderKind wire names', () {
      expect(ReminderKind.hydration.wireName, 'HYDRATION');
      expect(ReminderKind.microBreak.wireName, 'MICRO_BREAK');
    });

    test('DeliveryStatus wire names', () {
      expect(DeliveryStatus.scheduled.wireName, 'SCHEDULED');
      expect(DeliveryStatus.delivered.wireName, 'DELIVERED');
      expect(DeliveryStatus.suppressed.wireName, 'SUPPRESSED');
      expect(DeliveryStatus.failed.wireName, 'FAILED');
      expect(DeliveryStatus.notDisplayed.wireName, 'NOT_DISPLAYED');
    });

    test('ResponseOutcome wire names', () {
      expect(ResponseOutcome.none.wireName, 'NONE');
      expect(ResponseOutcome.completed.wireName, 'COMPLETED');
      expect(ResponseOutcome.dismissed.wireName, 'DISMISSED');
      expect(ResponseOutcome.timedOut.wireName, 'TIMED_OUT');
    });

    test('StyleOrder wire names', () {
      expect(StyleOrder.ambientFirst.wireName, 'AMBIENT_FIRST');
      expect(StyleOrder.characterFirst.wireName, 'CHARACTER_FIRST');
    });
  });

  group('fromWireName round-trips', () {
    test('every enum value round-trips through its wire name', () {
      for (final v in Placement.values) {
        expect(PlacementWire.fromWireName(v.wireName), v);
      }
      for (final v in PresentationStyle.values) {
        expect(PresentationStyleWire.fromWireName(v.wireName), v);
      }
      for (final v in ReminderKind.values) {
        expect(ReminderKindWire.fromWireName(v.wireName), v);
      }
      for (final v in DeliveryStatus.values) {
        expect(DeliveryStatusWire.fromWireName(v.wireName), v);
      }
      for (final v in ResponseOutcome.values) {
        expect(ResponseOutcomeWire.fromWireName(v.wireName), v);
      }
      for (final v in StyleOrder.values) {
        expect(StyleOrderWire.fromWireName(v.wireName), v);
      }
    });

    test('unknown wire values throw ArgumentError', () {
      expect(() => PlacementWire.fromWireName('TRAY'), throwsArgumentError);
      expect(() => PresentationStyleWire.fromWireName('character'),
          throwsArgumentError);
      expect(() => DeliveryStatusWire.fromWireName(''), throwsArgumentError);
    });
  });
}
