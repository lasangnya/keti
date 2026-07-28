import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/reminders/reminder_content.dart';
import '../../domain/study/reminder_content_resolver.dart';
import '../../domain/study/study_enums.dart';

part 'test_mode_provider.g.dart';

@riverpod
class TestMode extends _$TestMode {
  static const _resolver = ReminderContentResolver();

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

  /// Helper to get notch dimensions based on preset AND style.
  ///
  /// Test-mode-only escape hatch: the study resolver bakes in the protocol
  /// defaults (character → narrow-deep 250×250, ambient → default 400×100);
  /// this override exists for layout experimentation in the test tab.
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

  PresentationStyle get _selectedPresentationStyle =>
      state.selectedStyle == 'character'
          ? PresentationStyle.characterBased
          : PresentationStyle.ambient;

  /// Content for Break (micro-break) reminders in the selected style,
  /// resolved via the shared study resolver.
  ReminderContent getBreakContent({String? notchPreset}) =>
      _resolve(ReminderKind.microBreak, notchPreset);

  /// Content for Hydration reminders in the selected style,
  /// resolved via the shared study resolver.
  ReminderContent getHydrationContent({String? notchPreset}) =>
      _resolve(ReminderKind.hydration, notchPreset);

  ReminderContent _resolve(ReminderKind kind, String? notchPreset) {
    final resolved = _resolver.resolve(kind, _selectedPresentationStyle).content;
    if (notchPreset == null) return resolved;
    final (nWidth, nHeight) = _getNotchDimensions(notchPreset, state.selectedStyle);
    return resolved.copyWith(notchWidth: nWidth, notchHeight: nHeight);
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
