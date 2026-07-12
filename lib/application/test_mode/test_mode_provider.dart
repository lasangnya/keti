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

  /// Logic to determine what content to show for Break Reminders
  ReminderContent getBreakContent() {
    if (state.selectedStyle == 'character') {
      return const ReminderContent(
        message: "Keti needs a stretch!",
        cursorResource: "character_break_cursor",
        notchResource: "character_break_notch",
        trayResource: "character_break_tray",
        width: 150,
        height: 150,
        offsetX: -75,
        offsetY: -75,
      );
    }
    return const ReminderContent(
      message: "Time for a break",
      cursorResource: "ambient_break_cursor_pill",
      notchResource: "ambient_break_notch",
      trayResource: "ambient_break_tray",
      width: 86,
      height: 15,
      offsetX: -10,
      offsetY: -30,
    );
  }

  /// Logic to determine what content to show for Hydration Reminders
  ReminderContent getHydrationContent() {
    if (state.selectedStyle == 'character') {
      return const ReminderContent(
        message: "Drink water with Keti!",
        cursorResource: "character_water_cursor",
        notchResource: "character_water_notch",
        trayResource: "character_water_tray",
        width: 150,
        height: 150,
        offsetX: -75,
        offsetY: -75,
      );
    }
    return const ReminderContent(
      message: "Stay hydrated",
      cursorResource: "ambient_hydration_cursor_pill",
      notchResource: "ambient_water_notch",
      trayResource: "ambient_water_tray",
      width: 15,
      height: 86,
      offsetX: 20,
      offsetY: -55,
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
