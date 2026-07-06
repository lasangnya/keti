import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/page_title.dart';

class BreaksPage extends StatelessWidget {
  const BreaksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(title: AppStrings.breakReminders),
        Expanded(child: Center(child: Text('Break Reminders Content'))),
      ],
    );
  }
}