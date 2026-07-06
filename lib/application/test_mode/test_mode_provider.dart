import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_mode_provider.g.dart';

@riverpod
class TestMode extends _$TestMode {
  @override
  TestModeState build() {
    return TestModeState(isActive: false);
  }

  void toggleActive(bool value) {
    state = state.copyWith(isActive: value);
  }
}

class TestModeState {
  final bool isActive;
  final String? selectedStyle;
  TestModeState({required this.isActive, this.selectedStyle});

  TestModeState copyWith({bool? isActive, String? selectedStyle}) {
    return TestModeState(
      isActive: isActive ?? this.isActive,
      selectedStyle: selectedStyle ?? this.selectedStyle,
    );
  }
}