import 'package:flutter/material.dart';
import 'package:keti/theme/app_colors.dart';
import 'package:keti/theme/reminder_colors.dart';
import 'package:keti/constants/app_strings.dart';

void main() {
  runApp(const KetiApp());
}

class KetiApp extends StatelessWidget {
  const KetiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.reminderAmber,
          surface: AppColors.background,
          onSurface: AppColors.primaryText,
          onSurfaceVariant: AppColors.secondaryText,
          outline: AppColors.border,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.reminderAmber,
        ),
        extensions: [
          const ReminderColors(
            blue: AppColors.reminderBlue,
            teal: AppColors.reminderTeal,
            sage: AppColors.reminderSage,
            darkAmber: AppColors.reminderDarkAmber,
            hotPink: AppColors.reminderHotPink,
            darkPink: AppColors.reminderDarkPink,
            caribbeanBlue: AppColors.reminderCaribbeanBlue,
          ),
        ],
      ),
      home: const KetiHomePage(),
    );
  }
}

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
          const Expanded(
            child: Center(
              child: Text('Main Content Area'),
            ),
          ),
        ],
      ),
    );
  }
}
