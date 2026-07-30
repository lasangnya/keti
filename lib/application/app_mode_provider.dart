import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_mode_provider.g.dart';

enum AppMode { participant, admin }

@riverpod
class AppModeState extends _$AppModeState {
  @override
  AppMode build() => AppMode.participant;

  void setMode(AppMode mode) {
    state = mode;
  }
}
