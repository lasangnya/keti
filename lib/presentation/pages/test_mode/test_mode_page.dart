import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/reminders/reminder_manager.dart';
import 'package:keti/application/test_mode/test_mode_provider.dart';
import 'package:keti/domain/reminders/reminder_content.dart';
import 'package:keti/core/services/compliance_card_service.dart';
import '../../../core/constants/app_strings.dart';
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
                'Compliance Card',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KetiCard(
                title: 'Test Compliance Dropdown',
                subtitle: 'A dropdown card with interactive buttons from the system tray',
                showButtons: true,
                showRadio: false,
                button1Text: 'Trigger Card',
                onButton1Pressed: () {
                  ComplianceCardService.show(
                    title: 'Take a break with Keti?',
                    button1Text: 'Sure!',
                    button2Text: 'Not now',
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                        onButton1Pressed: () {
                          final content = notifier.getBreakContent();
                          ref.read(reminderManagerProvider.notifier).enqueue(
                                ReminderRequest(
                                  content: content,
                                  location: ReminderLocation.cursor,
                                ),
                              );
                        },
                        button2Text: AppStrings.testHydration,
                        onButton2Pressed: () {
                          final content = notifier.getHydrationContent();
                          ref.read(reminderManagerProvider.notifier).enqueue(
                                ReminderRequest(
                                  content: content,
                                  location: ReminderLocation.cursor,
                                ),
                              );
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
                        onButton1Pressed: () {
                          final content = notifier.getBreakContent();
                          ref.read(reminderManagerProvider.notifier).enqueue(
                                ReminderRequest(
                                  content: content,
                                  location: ReminderLocation.island,
                                ),
                              );
                        },
                        button2Text: AppStrings.testHydration,
                        onButton2Pressed: () {
                          final content = notifier.getHydrationContent();
                          ref.read(reminderManagerProvider.notifier).enqueue(
                                ReminderRequest(
                                  content: content,
                                  location: ReminderLocation.island,
                                ),
                              );
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
                        onButton1Pressed: () {
                          final content = notifier.getBreakContent();
                          ref.read(reminderManagerProvider.notifier).enqueue(
                                ReminderRequest(
                                  content: content,
                                  location: ReminderLocation.tray,
                                ),
                              );
                        },
                        button2Text: AppStrings.testHydration,
                        onButton2Pressed: () {
                          final content = notifier.getHydrationContent();
                          ref.read(reminderManagerProvider.notifier).enqueue(
                                ReminderRequest(
                                  content: content,
                                  location: ReminderLocation.tray,
                                ),
                              );
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
