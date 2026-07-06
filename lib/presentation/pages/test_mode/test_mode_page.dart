import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/test_mode/test_mode_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/page_title.dart';

class TestModePage extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testModeState = ref.watch(testModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(title: AppStrings.testMode),
        SwitchListTile(
          title: const Text('Test Mode Active'),
          value: testModeState.isActive,
          onChanged: (val) => ref.read(testModeProvider.notifier).toggleActive(val),
        ),
      ],
    );
  }
}