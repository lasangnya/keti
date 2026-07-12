import 'package:riverpod_annotation/riverpod_annotation.dart';

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