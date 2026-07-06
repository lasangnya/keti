import 'package:flutter/material.dart';
import 'package:keti/presentation/pages/breaks/breaks_page.dart';
import 'package:keti/presentation/pages/hydration/hydration_page.dart';
import 'package:keti/presentation/pages/test_mode/test_mode_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_strings.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import 'navigation_item.dart';
part 'navigation_provider.g.dart';

@riverpod
class Navigation extends _$Navigation {

  final List<NavigationItem> _items = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: AppStrings.dashboard,
      page: const DashboardPage(),
    ),
    NavigationItem(
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
      label: AppStrings.breakReminders,
      page: const BreaksPage(),
    ),
    NavigationItem(
      icon: Icons.water_drop_outlined,
      selectedIcon: Icons.water_drop,
      label: AppStrings.hydrationReminders,
      page: const HydrationPage(),
    ),
    NavigationItem(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      label: AppStrings.testMode,
      page: TestModePage(),
    ),

  ];
  @override
  int build() => 0; // Default to Dashboard
  NavigationItem get currentItem => _items[state];
  List<NavigationItem> get allItems => _items;
  void setIndex(int index) => state = index;
}
