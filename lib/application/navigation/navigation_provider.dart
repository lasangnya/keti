import 'package:flutter/material.dart';
import 'package:keti/presentation/pages/study/study_page.dart';
import 'package:keti/presentation/pages/test_mode/test_mode_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_strings.dart';
import 'navigation_item.dart';
part 'navigation_provider.g.dart';

@riverpod
class Navigation extends _$Navigation {

  final List<NavigationItem> _items = [
    NavigationItem(
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      label: AppStrings.study,
      page: const StudyPage(),
    ),
    NavigationItem(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      label: AppStrings.testMode,
      page: TestModePage(),
    ),

  ];
  @override
  int build() => 0; // Default to Study
  NavigationItem get currentItem => _items[state];
  List<NavigationItem> get allItems => _items;
  void setIndex(int index) => state = index;
}
