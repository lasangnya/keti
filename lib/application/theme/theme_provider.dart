import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/reminder_colors.dart';

part 'theme_provider.g.dart';

@riverpod
class AppTheme extends _$AppTheme {
  @override
  ThemeData build() {
    return _buildTheme(AppColors.reminderAmber);
  }

  void updateSeedColor(Color color) {
    state = _buildTheme(color);
  }

  ThemeData _buildTheme(Color seedColor) {
    final base = ThemeData(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Geist',
      textTheme: base.textTheme.apply(fontFamily: 'Geist'),
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        surface: AppColors.background,
        onSurface: AppColors.primaryText,
        onSurfaceVariant: AppColors.secondaryText,
        outline: AppColors.border,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: seedColor,
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
    );
  }
}
