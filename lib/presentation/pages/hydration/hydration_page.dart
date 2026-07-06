import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/page_title.dart';

class HydrationPage extends StatelessWidget {
  const HydrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(title: AppStrings.hydrationReminders),
        Expanded(child: Center(child: Text('Hydration Reminders Content'))),
      ],
    );
  }
}