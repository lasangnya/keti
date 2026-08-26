import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/researcher_launcher.dart';
import '../study/study_page.dart';

/// Participant shell (study build): the Study flow is the only content —
/// no side panel. The Researcher Access entry stays pinned bottom-right and
/// opens the admin console in a SEPARATE app window/process so participant
/// and researcher run in parallel.
class KetiHomePage extends ConsumerStatefulWidget {
  const KetiHomePage({super.key});

  @override
  ConsumerState<KetiHomePage> createState() => _KetiHomePageState();
}

class _KetiHomePageState extends ConsumerState<KetiHomePage> {
  bool _launching = false;

  Future<void> _openResearcherWindow() async {
    if (_launching) return;
    setState(() => _launching = true);
    final ok = await ref.read(researcherLauncherProvider).launch();
    if (!mounted) return;
    setState(() => _launching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Researcher window opened.'
              : 'Could not open the researcher window.',
        ),
      ),
    );
  }

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
                  onPressed: _launching ? null : _openResearcherWindow,
                  child: Text(
                    _launching ? 'Opening…' : 'Researcher Access',
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
