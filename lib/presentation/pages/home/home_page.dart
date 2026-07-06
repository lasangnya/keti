import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/navigation/navigation_provider.dart';

class KetiHomePage extends ConsumerStatefulWidget {
  const KetiHomePage({super.key});

  @override
  ConsumerState<KetiHomePage> createState() => _KetiHomePageState();
}

class _KetiHomePageState extends ConsumerState<KetiHomePage> {
  @override
  Widget build(BuildContext context) {

    final navNotifier = ref.watch(navigationProvider.notifier);
    final selectedIndex = ref.watch(navigationProvider);
    final currentItem = navNotifier.currentItem;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            destinations: navNotifier.allItems.map((item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(item.label),
            )).toList(),
            onDestinationSelected: (index) => navNotifier.setIndex(index),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: currentItem.page,
          ),
        ],
      ),
    );
  }
}
