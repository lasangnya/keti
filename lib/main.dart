import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keti/presentation/pages/home/home_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/reminder_colors.dart';

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
        textTheme: GoogleFonts.geistTextTheme(),
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
