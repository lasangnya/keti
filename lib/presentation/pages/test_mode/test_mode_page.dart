import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/page_title.dart';

class TestModePage extends StatelessWidget {
  const TestModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(title: AppStrings.testMode),
        Expanded(child: Center(child: Text('Test Mode Content'))),
      ],
    );
  }
}