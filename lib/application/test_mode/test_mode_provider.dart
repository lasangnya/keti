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

  /// Helper to get notch dimensions based on preset AND style
  (double, double) _getNotchDimensions(String preset, String style) {
    if (style == 'character') {
      switch (preset) {
        case 'wide-shallow':
          return (600, 150);
        case 'narrow-deep':
          return (250, 250);
        case 'default':
        default:
          return (400, 400);
      }
    } else {
      switch (preset) {
        case 'wide-shallow':
          return (500, 40);
        case 'narrow-deep':
          return (200, 300);
        case 'default':
        default:
          return (400, 100);
      }
    }
  }

  /// Logic to determine what content to show for Break Reminders
  ReminderContent getBreakContent({String? notchPreset}) {
    // PROGRAMMING: Define which preset is used for each style branch here
    final preset = notchPreset ?? (state.selectedStyle == 'character' ? 'narrow-deep' : 'default');
    final (nWidth, nHeight) = _getNotchDimensions(preset, state.selectedStyle);

    if (state.selectedStyle == 'character') {
      return ReminderContent(
        message: "Keti needs a stretch!",
        cursorResource: "character_break_cursor_pill",
        notchResource: "character_break_cursor_pill",
        trayResource: "character_break_cursor_pill",
        cursorWidth: 80,
        cursorHeight: 80,
        cursorOffsetX: 0,
        cursorOffsetY: -40,
        notchWidth: nWidth,
        notchHeight: nHeight,
        trayWidth: 22,
        trayHeight: 22,
        totalFrames: 250,
      );
    }
    return ReminderContent(
      message: "Time for a break",
      cursorResource: "ambient_break_cursor_pill",
      notchResource: "ambient_break_notch_card",
      trayResource: "ambient_break_cursor_pill",
      cursorWidth: 86,
      cursorHeight: 15,
      cursorOffsetX: -10,
      cursorOffsetY: -30,
      notchWidth: nWidth,
      notchHeight: nHeight,
      trayWidth: 22,
      trayHeight: 4,
      totalFrames: 100,
    );
  }

  /// Logic to determine what content to show for Hydration Reminders
  ReminderContent getHydrationContent({String? notchPreset}) {
    // PROGRAMMING: Define which preset is used for each style branch here
    final preset = notchPreset ?? (state.selectedStyle == 'character' ? 'wide-shallow' : 'default');
    final (nWidth, nHeight) = _getNotchDimensions(preset, state.selectedStyle);

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
        trayWidth: 22,
        trayHeight: 22,
        totalFrames: 250,
      );
    }
    return ReminderContent(
      message: "Stay hydrated",
      cursorResource: "ambient_hydration_cursor_pill",
      notchResource: "ambient_hydration_notch_card",
      trayResource: "ambient_hydration_cursor_pill", // using the same resource as the cursor proximate
      cursorWidth: 15,
      cursorHeight: 86,
      cursorOffsetX: 20,
      cursorOffsetY: -55,
      notchWidth: nWidth,
      notchHeight: nHeight,
      trayWidth: 4,
      trayHeight: 22,
      totalFrames: 100,
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
