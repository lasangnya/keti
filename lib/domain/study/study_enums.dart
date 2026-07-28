/// Study-protocol enums with their Firestore/CSV wire values.
///
/// Wire values are part of the frozen study protocol (see
/// docs/study-prototype-implementation-plan.md §7): they appear in Firestore
/// documents, on-device CSVs, and every export. Do not rename a wire value
/// without bumping the protocol version.
library;

/// Screen placement condition (IV 1).
enum Placement { cursorProximate, notchCard, systemTray }

/// Presentation style condition (IV 2).
enum PresentationStyle { ambient, characterBased }

/// Health-reminder category.
enum ReminderKind { hydration, microBreak }

/// Technical delivery lifecycle of one reminder exposure.
enum DeliveryStatus { scheduled, delivered, suppressed, failed, notDisplayed }

/// Behavioral outcome recorded from the uniform compliance card.
enum ResponseOutcome { none, completed, dismissed, timedOut }

/// Counterbalancing order across the two study days.
enum StyleOrder { ambientFirst, characterFirst }

extension PlacementWire on Placement {
  String get wireName => switch (this) {
        Placement.cursorProximate => 'CURSOR_PROXIMATE',
        Placement.notchCard => 'NOTCH_CARD',
        Placement.systemTray => 'SYSTEM_TRAY',
      };

  static Placement fromWireName(String value) => switch (value) {
        'CURSOR_PROXIMATE' => Placement.cursorProximate,
        'NOTCH_CARD' => Placement.notchCard,
        'SYSTEM_TRAY' => Placement.systemTray,
        _ => throw ArgumentError.value(value, 'value', 'Unknown Placement'),
      };
}

extension PresentationStyleWire on PresentationStyle {
  String get wireName => switch (this) {
        PresentationStyle.ambient => 'AMBIENT',
        PresentationStyle.characterBased => 'CHARACTER_BASED',
      };

  static PresentationStyle fromWireName(String value) => switch (value) {
        'AMBIENT' => PresentationStyle.ambient,
        'CHARACTER_BASED' => PresentationStyle.characterBased,
        _ => throw ArgumentError.value(
            value, 'value', 'Unknown PresentationStyle'),
      };
}

extension ReminderKindWire on ReminderKind {
  String get wireName => switch (this) {
        ReminderKind.hydration => 'HYDRATION',
        ReminderKind.microBreak => 'MICRO_BREAK',
      };

  static ReminderKind fromWireName(String value) => switch (value) {
        'HYDRATION' => ReminderKind.hydration,
        'MICRO_BREAK' => ReminderKind.microBreak,
        _ => throw ArgumentError.value(value, 'value', 'Unknown ReminderKind'),
      };
}

extension DeliveryStatusWire on DeliveryStatus {
  String get wireName => switch (this) {
        DeliveryStatus.scheduled => 'SCHEDULED',
        DeliveryStatus.delivered => 'DELIVERED',
        DeliveryStatus.suppressed => 'SUPPRESSED',
        DeliveryStatus.failed => 'FAILED',
        DeliveryStatus.notDisplayed => 'NOT_DISPLAYED',
      };

  static DeliveryStatus fromWireName(String value) => switch (value) {
        'SCHEDULED' => DeliveryStatus.scheduled,
        'DELIVERED' => DeliveryStatus.delivered,
        'SUPPRESSED' => DeliveryStatus.suppressed,
        'FAILED' => DeliveryStatus.failed,
        'NOT_DISPLAYED' => DeliveryStatus.notDisplayed,
        _ => throw ArgumentError.value(value, 'value', 'Unknown DeliveryStatus'),
      };
}

extension ResponseOutcomeWire on ResponseOutcome {
  String get wireName => switch (this) {
        ResponseOutcome.none => 'NONE',
        ResponseOutcome.completed => 'COMPLETED',
        ResponseOutcome.dismissed => 'DISMISSED',
        ResponseOutcome.timedOut => 'TIMED_OUT',
      };

  static ResponseOutcome fromWireName(String value) => switch (value) {
        'NONE' => ResponseOutcome.none,
        'COMPLETED' => ResponseOutcome.completed,
        'DISMISSED' => ResponseOutcome.dismissed,
        'TIMED_OUT' => ResponseOutcome.timedOut,
        _ => throw ArgumentError.value(
            value, 'value', 'Unknown ResponseOutcome'),
      };
}

extension StyleOrderWire on StyleOrder {
  String get wireName => switch (this) {
        StyleOrder.ambientFirst => 'AMBIENT_FIRST',
        StyleOrder.characterFirst => 'CHARACTER_FIRST',
      };

  static StyleOrder fromWireName(String value) => switch (value) {
        'AMBIENT_FIRST' => StyleOrder.ambientFirst,
        'CHARACTER_FIRST' => StyleOrder.characterFirst,
        _ => throw ArgumentError.value(value, 'value', 'Unknown StyleOrder'),
      };
}
