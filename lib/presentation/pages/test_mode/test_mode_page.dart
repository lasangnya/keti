import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/test_mode/test_mode_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/cursor_pill_service.dart';
import '../../../core/services/notch_hook_service.dart';
import '../../../core/services/tray_pill_service.dart';
import '../../widgets/page_title.dart';
import '../../widgets/keti_card.dart';

class TestModePage extends ConsumerWidget {
  const TestModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testModeState = ref.watch(testModeProvider);
    final notifier = ref.read(testModeProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const PageTitle(title: AppStrings.testMode),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SwitchListTile(
              title: const Text(AppStrings.testModeActive),
              value: testModeState.isActive,
              onChanged: (val) => notifier.toggleActive(val),
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
                        isSelected: testModeState.selectedStyle == 'ambient',
                        onSelected: (_) => notifier.setStyle('ambient'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.character,
                        subtitle: AppStrings.characterSubtitle,
                        isSelected: testModeState.selectedStyle == 'character',
                        onSelected: (_) => notifier.setStyle('character'),
                        enabled: false,
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
                        showButtons: true,
                        showRadio: false,
                        button1Text: AppStrings.testBreak,
                        onButton1Pressed: () async {
                          final content = ref.read(testModeProvider.notifier).getBreakContent();
                          await CursorPillService.showPill(content);
                        },
                        button2Text: AppStrings.testHydration,
                        onButton2Pressed: () async {
                          final content = ref.read(testModeProvider.notifier).getHydrationContent();
                          await CursorPillService.showPill(content);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.island,
                        subtitle: AppStrings.islandSubtitle,
                        showButtons: true,
                        showRadio: false,
                        button1Text: AppStrings.testBreak,
                        onButton1Pressed: () async {
                          // PROGRAMMING: Change notchPreset to 'wide-shallow' or 'narrow-deep' to test
                          final content = ref.read(testModeProvider.notifier).getBreakContent(notchPreset: 'default');
                          await NotchHookService.showIsland(content);
                        },
                        button2Text: AppStrings.testHydration,
                        onButton2Pressed: () async {
                          // PROGRAMMING: Change notchPreset to 'wide-shallow' or 'narrow-deep' to test
                          final content = ref.read(testModeProvider.notifier).getHydrationContent(notchPreset: 'default');
                          await NotchHookService.showIsland(content);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KetiCard(
                        title: AppStrings.tray,
                        subtitle: AppStrings.traySubtitle,
                        showButtons: true,
                        showRadio: false,
                        button1Text: AppStrings.testBreak,
                        onButton1Pressed: () async {
                          final content = ref.read(testModeProvider.notifier).getBreakContent();
                          await TrayPillService.showPill(content);
                        },
                        button2Text: AppStrings.testHydration,
                        onButton2Pressed: () async {
                          final content = ref.read(testModeProvider.notifier).getHydrationContent();
                          await TrayPillService.showPill(content);
                        },
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
