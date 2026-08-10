import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/app_mode_provider.dart';
import '../study/study_page.dart';

/// Participant shell (study build): the Study flow is the only content —
/// no side panel. The Researcher Access entry stays pinned bottom-right.
class KetiHomePage extends ConsumerStatefulWidget {
  const KetiHomePage({super.key});

  @override
  ConsumerState<KetiHomePage> createState() => _KetiHomePageState();
}

class _KetiHomePageState extends ConsumerState<KetiHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: StudyPage()),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(appModeStateProvider.notifier)
                        .setMode(AppMode.admin);
                  },
                  child: Text(
                    'Researcher Access',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
