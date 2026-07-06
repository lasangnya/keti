import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/page_title.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(title: AppStrings.dashboard),
        Expanded(child: Center(child: Text('Dashboard Content'))),
      ],
    );
  }
}