import 'package:flutter/material.dart';
import 'package:keti/presentation/pages/study/study_page.dart';
import 'package:keti/presentation/pages/test_mode/test_mode_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_strings.dart';
import '../study/app_environment_provider.dart';
import 'navigation_item.dart';
part 'navigation_provider.g.dart';

@riverpod
class Navigation extends _$Navigation {

  /// The Study tab is always present. Test Mode exists only outside the
  /// `study` environment — participant builds must not expose it.
  List<NavigationItem> _items(String environment) => [
    NavigationItem(
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      label: AppStrings.study,
      page: const StudyPage(),
    ),
    if (environment != 'study')
      NavigationItem(
        icon: Icons.terminal_outlined,
        selectedIcon: Icons.terminal,
        label: AppStrings.testMode,
        page: TestModePage(),
      ),
  ];

  @override
  int build() => 0; // Default to Study

  NavigationItem get currentItem {
    final items = _items(ref.watch(appEnvironmentProvider));
    return items[state.clamp(0, items.length - 1)];
  }

  List<NavigationItem> get allItems => _items(ref.watch(appEnvironmentProvider));

  void setIndex(int index) => state = index;
}
