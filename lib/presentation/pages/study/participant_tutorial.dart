import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/study/participant_entry_provider.dart';
import '../../../application/study/participant_providers.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/link_launcher_service.dart';
import '../../../domain/study/study_config.dart';

/// The 8-step in-app participant tutorial (design/in_app_participant_tutorial_v2.md).
///
/// Owns the Participant-ID entry (step 2) and gates the session start:
/// the final step calls [onStartSession] (the StudyPage's startDay).
/// Shown once per participant — StudyPage skips it once
/// `LocalStore.isTutorialSeen(code)` is true.
class ParticipantTutorial extends ConsumerStatefulWidget {
  const ParticipantTutorial({super.key, required this.onStartSession});

  final Future<void> Function() onStartSession;

  @override
  ConsumerState<ParticipantTutorial> createState() => _ParticipantTutorialState();
}

enum _Step {
  welcome,
  idEntry,
  prepare,
  during,
  dismiss,
  safety,
  finish,
}

class _ParticipantTutorialState extends ConsumerState<ParticipantTutorial> {
  final _idController = TextEditingController();
  _Step _step = _Step.welcome;
  bool _submitted = false;
  bool _blankError = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  /// The wizard shows the step that was last navigated to. Advancing past
  /// the ID screen happens explicitly in [_submitId] once the participant
  /// loaded, so Back can always return to step 2 to edit the ID.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _step;
    final entry = ref.watch(participantEntryProvider);
    _prefillIdIfNeeded(step);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgressHeader(step: step),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleFor(step),
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ..._bodyFor(step, theme, entry),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _footer(step, entry),
      ],
    );
  }

  String _titleFor(_Step step) => switch (step) {
        _Step.welcome => AppStrings.tutorialWelcomeTitle,
        _Step.idEntry => AppStrings.tutorialIdTitle,
        _Step.prepare => AppStrings.tutorialPrepareTitle,
        _Step.during => AppStrings.tutorialDuringTitle,
        _Step.dismiss => AppStrings.tutorialDismissTitle,
        _Step.safety => AppStrings.tutorialSafetyTitle,
        _Step.finish => AppStrings.tutorialFinishTitle,
      };

  List<Widget> _bodyFor(
    _Step step,
    ThemeData theme,
    ParticipantEntryState entry,
  ) {
    switch (step) {
      case _Step.welcome:
        return [
          Text(AppStrings.tutorialWelcomeBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          const _AboutNameCard(),
        ];

      case _Step.idEntry:
        return [
          Text(AppStrings.tutorialIdBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              labelText: AppStrings.tutorialIdFieldLabel,
              hintText: AppStrings.tutorialIdFieldHint,
              border: const OutlineInputBorder(),
              errorText: _blankError
                  ? AppStrings.tutorialIdBlankError
                  : _submitted
                      ? entry.errorMessage
                      : null,
            ),
            onSubmitted: (_) => _submitId(entry),
          ),
        ];

      case _Step.prepare:
        return [
          Text(AppStrings.tutorialPrepareBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (entry.links?.start != null) ...[
            FilledButton.tonalIcon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text(AppStrings.tutorialOpenPreStudy),
              onPressed: () => ref.read(linkLauncherServiceProvider).open(
                QuestionnaireLinks.fill(
                  entry.links!.start!,
                  participantId: entry.participant!.participantCode,
                ),
              ),
            ),
          ],
        ];

      case _Step.during:
        return [
          Text(AppStrings.tutorialDuringBody, style: theme.textTheme.bodyMedium),
        ];

      case _Step.dismiss:
        return [
          Text(AppStrings.tutorialDismissBody, style: theme.textTheme.bodyMedium),
        ];

      case _Step.safety:
        return [
          Text(AppStrings.tutorialSafetyBody, style: theme.textTheme.bodyMedium),
        ];

      case _Step.finish:
        return [
          Text(AppStrings.tutorialFinishBody, style: theme.textTheme.bodyMedium),
        ];
    }
  }

  /// Bottom action row: Back at the start (omitted on the first step) and
  /// the step's primary button at the end.
  Widget _stepButtons({
    required String nextLabel,
    required VoidCallback onNext,
    _Step? backTo,
  }) {
    return Row(
      mainAxisAlignment: backTo == null
          ? MainAxisAlignment.end
          : MainAxisAlignment.spaceBetween,
      children: [
        if (backTo != null)
          OutlinedButton.icon(
            onPressed: () => setState(() => _step = backTo),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(AppStrings.backLabel),
          ),
        // Flexible so a long primary label (e.g. the pre-study questionnaire
        // confirmation) wraps instead of overflowing next to the Back button.
        Flexible(
          child: FilledButton(
            onPressed: onNext,
            child: Text(nextLabel, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  /// The step's primary/back action row, rendered in the fixed footer.
  Widget _actionButtons(_Step step, ParticipantEntryState entry) {
    switch (step) {
      case _Step.welcome:
        return _stepButtons(
          nextLabel: AppStrings.tutorialBeginLabel,
          onNext: () => setState(() => _step = _Step.idEntry),
        );
      case _Step.idEntry:
        return _stepButtons(
          nextLabel: AppStrings.nextLabel,
          onNext: () => _submitId(entry),
          backTo: _Step.welcome,
        );
      case _Step.prepare:
        return _stepButtons(
          nextLabel: AppStrings.tutorialPreStudyDone,
          onNext: () => setState(() => _step = _Step.during),
          backTo: _Step.idEntry,
        );
      case _Step.during:
        return _stepButtons(
          nextLabel: AppStrings.nextLabel,
          onNext: () => setState(() => _step = _Step.dismiss),
          backTo: _Step.prepare,
        );
      case _Step.dismiss:
        return _stepButtons(
          nextLabel: AppStrings.nextLabel,
          onNext: () => setState(() => _step = _Step.safety),
          backTo: _Step.during,
        );
      case _Step.safety:
        return _stepButtons(
          nextLabel: AppStrings.nextLabel,
          onNext: () => setState(() => _step = _Step.finish),
          backTo: _Step.dismiss,
        );
      case _Step.finish:
        return _stepButtons(
          nextLabel: AppStrings.startSession,
          onNext: _startSession,
          backTo: _Step.safety,
        );
    }
  }

  /// Fixed bottom action bar — kept outside the scroll view so the primary
  /// action stays visible regardless of window size or content length.
  Widget _footer(_Step step, ParticipantEntryState entry) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: _actionButtons(step, entry),
      ),
    );
  }

  /// Pre-fills the Participant-ID field with the last used code (dev/study
  /// convenience — same behavior the old entry form had).
  void _prefillIdIfNeeded(_Step step) {
    if (_prefilled || step != _Step.idEntry) return;
    final store = ref.read(localStoreProvider).asData?.value;
    final last = store?.lastParticipantCode;
    if (last != null) {
      _idController.text = last;
    }
    _prefilled = true;
  }

  Future<void> _submitId(ParticipantEntryState entry) async {
    if (_idController.text.trim().isEmpty) {
      setState(() {
        _submitted = true;
        _blankError = true;
      });
      return;
    }
    setState(() => _submitted = true);
    await ref
        .read(participantEntryProvider.notifier)
        .enterCode(_idController.text);
    // Advance past the ID screen once the participant loaded. Explicit here
    // (rather than a derived step) so Back can return to this screen and a
    // changed ID is re-submitted the same way.
    if (mounted && ref.read(participantEntryProvider).isReady) {
      setState(() => _step = _Step.prepare);
    }
  }

  Future<void> _startSession() async {
    final entry = ref.read(participantEntryProvider);
    if (entry.participant == null) return;
    final store = await ref.read(localStoreProvider.future);
    await store.setTutorialSeen(entry.participant!.participantCode);
    await widget.onStartSession();
  }
}

/// "About the name" callout shown on the welcome step — explains the Sinhala
/// origin of "keti" (කෙටි, "short"/"brief"). Tinted with the seed color so it
/// reads as a supplementary note rather than primary tutorial content.
class _AboutNameCard extends StatelessWidget {
  const _AboutNameCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                AppStrings.aboutNameTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.aboutNameWord,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.aboutNamePronunciation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.aboutNameBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(AppStrings.aboutNamePurpose, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(
            AppStrings.aboutNameExamples,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• ${AppStrings.aboutNameExample1}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '• ${AppStrings.aboutNameExample2}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});

  final _Step step;

  static const _total = 7;
  static const _labels = [
    'Welcome',
    'Your Participant ID',
    'Before you begin',
    'During the session',
    'Dismiss a reminder',
    'Safety and comfort',
    'Finishing the session',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = step.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${index + 1} of $_total — ${_labels[index]}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (index + 1) / _total,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
