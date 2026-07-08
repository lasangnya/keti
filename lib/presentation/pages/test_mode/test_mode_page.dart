import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/test_mode/test_mode_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notch_hook_service.dart';
import '../../widgets/page_title.dart';
import '../../widgets/keti_card.dart';

class TestModePage extends ConsumerWidget {
  const TestModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testModeState = ref.watch(testModeProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const PageTitle(title: AppStrings.testMode),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // Offset for ListListTile internal padding
            child: SwitchListTile(
              title: const Text(AppStrings.testModeActive),
              value: testModeState.isActive,
              onChanged: (val) =>
                  ref.read(testModeProvider.notifier).toggleActive(val),
            ),
          ),
          if (testModeState.isActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                AppStrings.reminderStyle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.ambient,
                        subtitle: AppStrings.ambientSubtitle,
                        isSelected: false,
                        onSelected: (_) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.character,
                        subtitle: AppStrings.characterSubtitle,
                        isSelected: false,
                        onSelected: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                AppStrings.reminderType,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.cursor,
                        subtitle: AppStrings.cursorSubtitle,
                        showButton: true,
                        buttonText: AppStrings.test,
                        isSelected: false,
                        onSelected: (_) {},
                        onButtonPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.island,
                        subtitle: AppStrings.islandSubtitle,
                        showButton: true,
                        buttonText: AppStrings.test,
                        isSelected: false,
                        onSelected: (_) {},
                        onButtonPressed: () async {
                          await NotchHookService.showIsland('Time to drink water! 💧');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.tray,
                        subtitle: AppStrings.traySubtitle,
                        showButton: true,
                        buttonText: AppStrings.test,
                        isSelected: false,
                        onSelected: (_) {},
                        onButtonPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
