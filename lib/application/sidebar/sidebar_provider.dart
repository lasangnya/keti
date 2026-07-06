import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sidebar_provider.g.dart';

@riverpod
class Sidebar extends _$Sidebar {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void setExtended(bool value) {
    state = value;
  }
}