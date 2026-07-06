import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class KetiHomePage extends StatefulWidget {
  const KetiHomePage({super.key});

  @override
  State<KetiHomePage> createState() => _KetiHomePageState();
}

class _KetiHomePageState extends State<KetiHomePage> {
  bool _isRailExtended = true;
  int _selectedIndex = 0;

  static const _destinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text(AppStrings.dashboard),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer),
      label: Text(AppStrings.breakReminders),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.water_drop_outlined),
      selectedIcon: Icon(Icons.water_drop),
      label: Text(AppStrings.hydrationReminders),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.terminal),
      selectedIcon: Icon(Icons.terminal),
      label: Text(AppStrings.testMode),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SizedBox(
                  width: _isRailExtended ? 120 : 48,
                  height: _isRailExtended ? 28 : 48,
                  child: Image.asset(
                    _isRailExtended
                        ? 'assets/images/logo.png'
                        : 'assets/images/logomark.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                child: NavigationRail(
                  extended: _isRailExtended,
                  selectedIndex: _selectedIndex,
                  indicatorShape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          icon: Icon(
                            _isRailExtended
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(
                                    () => _isRailExtended = !_isRailExtended);
                          },
                          tooltip: _isRailExtended
                              ? 'Collapse sidebar'
                              : 'Expand sidebar',
                        ),
                      ),
                    ),
                  ),
                  destinations: _destinations,
                ),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _getPageTitle(_selectedIndex),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              )
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index){
    switch (index) {
      case 0: return AppStrings.dashboard;
      case 1: return AppStrings.breakReminders;
      case 2: return AppStrings.hydrationReminders;
      case 3: return AppStrings.testMode;
      default: return '';
    }
  }

  Widget _getPage(int index){
    switch(index){
      case 0 : return const Center(child: Text('Dashboard Content'));
      case 1 : return const Center(child: Text('Break Reminders Content'));
      case 2 : return const Center(child: Text('Hydration Reminders Content'));
      case 3 : return const Center(child: Text('Test Mode Content'));
      default: return const SizedBox.shrink();
    }
  }
}