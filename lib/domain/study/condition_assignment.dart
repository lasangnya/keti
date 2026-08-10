import 'study_enums.dart';

/// Deterministic counterbalancing (plan §4).
///
/// Participant codes carry a serial (P001, P002, …). Parity decides the style
/// order: odd serial → ambient on Day 1, even serial → character-based on
/// Day 1. The assignment is a pure function of the serial — reproducible by
/// anyone, with no randomness and no server state.
StyleOrder styleOrderForSerial(int serial) =>
    serial.isOdd ? StyleOrder.ambientFirst : StyleOrder.characterFirst;

/// Resolves the presentation style for a study day given the participant's
/// counterbalancing order. [dayNumber] must be 1 or 2.
PresentationStyle styleForDay(StyleOrder order, int dayNumber) =>
    switch ((order, dayNumber)) {
      (StyleOrder.ambientFirst, 1) ||
      (StyleOrder.characterFirst, 2) =>
        PresentationStyle.ambient,
      (StyleOrder.ambientFirst, 2) ||
      (StyleOrder.characterFirst, 1) =>
        PresentationStyle.characterBased,
      _ => throw ArgumentError.value(dayNumber, 'dayNumber', 'Must be 1 or 2'),
    };
