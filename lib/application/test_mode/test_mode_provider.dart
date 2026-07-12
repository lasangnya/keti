import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/reminders/reminder_content.dart';

part 'test_mode_provider.g.dart';

@riverpod
class TestMode extends _$TestMode {
  @override
  TestModeState build() {
    return TestModeState(
      isActive: false,
      selectedStyle: 'ambient',
      selectedType: 'cursor',
    );
  }

  void toggleActive(bool value) {
    state = state.copyWith(isActive: value);
  }

  void setStyle(String style) {
    state = state.copyWith(selectedStyle: style);
  }

  void setType(String type) {
    state = state.copyWith(selectedType: type);
  }

  /// Helper to get notch dimensions based on preset
  (double, double) _getNotchDimensions(String preset) {
    switch (preset) {
      case 'wide-shallow':
        return (500, 40);
      case 'narrow-deep':
        return (250, 90);
      case 'default':
      default:
        return (350, 60);
    }
  }

  /// Logic to determine what content to show for Break Reminders
  ReminderContent getBreakContent({String notchPreset = 'default'}) {
    final (nWidth, nHeight) = _getNotchDimensions(notchPreset);
    
    if (state.selectedStyle == 'character') {
      return ReminderContent(
        message: "Keti needs a stretch!",
        cursorResource: "character_break_cursor",
        notchResource: "character_break_notch",
        trayResource: "character_break_tray",
        cursorWidth: 150,
        cursorHeight: 150,
        cursorOffsetX: -75,
        cursorOffsetY: -75,
        notchWidth: nWidth,
        notchHeight: nHeight,
      );
    }
    return ReminderContent(
      message: "Time for a break",
      cursorResource: "ambient_break_cursor_pill",
      notchResource: "ambient_break_notch",
      trayResource: "ambient_break_tray",
      cursorWidth: 86,
      cursorHeight: 15,
      cursorOffsetX: -10,
      cursorOffsetY: -30,
      notchWidth: nWidth,
      notchHeight: nHeight,
    );
  }

  /// Logic to determine what content to show for Hydration Reminders
  ReminderContent getHydrationContent({String notchPreset = 'default'}) {
    final (nWidth, nHeight) = _getNotchDimensions(notchPreset);

    if (state.selectedStyle == 'character') {
      return ReminderContent(
        message: "Drink water with Keti!",
        cursorResource: "character_water_cursor",
        notchResource: "character_water_notch",
        trayResource: "character_water_tray",
        cursorWidth: 150,
        cursorHeight: 150,
        cursorOffsetX: -75,
        cursorOffsetY: -75,
        notchWidth: nWidth,
        notchHeight: nHeight,
      );
    }
    return ReminderContent(
      message: "Stay hydrated",
      cursorResource: "ambient_hydration_cursor_pill",
      notchResource: "ambient_water_notch",
      trayResource: "ambient_water_tray",
      cursorWidth: 15,
      cursorHeight: 86,
      cursorOffsetX: 20,
      cursorOffsetY: -55,
      notchWidth: nWidth,
      notchHeight: nHeight,
    );
  }
}

class TestModeState {
  final bool isActive;
  final String selectedStyle;
  final String selectedType;

  TestModeState({
    required this.isActive,
    required this.selectedStyle,
    required this.selectedType,
  });

  TestModeState copyWith({
    bool? isActive,
    String? selectedStyle,
    String? selectedType,
  }) {
    return TestModeState(
      isActive: isActive ?? this.isActive,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}
