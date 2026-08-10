import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/study/participant_entry_provider.dart';
import '../../../application/study/participant_providers.dart';
import '../../../application/study/session_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/link_launcher_service.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../widgets/page_title.dart';
import '../../widgets/technical_problem_dialog.dart';
import 'participant_tutorial.dart';

/// Participant study flow (plan §3.2 + design/in_app_participant_tutorial_v2.md):
///
/// 1. No participant yet, or tutorial not seen → [ParticipantTutorial]
///    (Welcome → Participant ID → prepare → info steps → Start session).
/// 2. Tutorial seen, day not started → day overview (resume/start).
/// 3. Session running → live status with countdown.
/// 4. Day complete → end-of-session questionnaire; Day 1 additionally offers
///    Start Day 2 once the researcher activates it; Day 2 reveals the
///    end-of-study questionnaire.
class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(participantEntryProvider);
    final session = ref.watch(sessionControllerProvider);
    final store = ref.watch(localStoreProvider).asData?.value;

    final tutorialSeen = entry.participant != null &&
        (store?.isTutorialSeen(entry.participant!.participantCode) ?? false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(title: AppStrings.study),
          if (!entry.isReady)
            ParticipantTutorial(onStartSession: _startSession)
          else if (!tutorialSeen && !session.active && !session.completed)
            ParticipantTutorial(onStartSession: _startSession)
          else if (session.active)
            _buildSessionView(context, session)
          else if (session.completed || entry.dayAlreadyCompleted)
            _buildCompletedView(context, entry, session)
          else
            _buildDayOverview(context, entry, session),
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    await ref.read(sessionControllerProvider.notifier).startDay();
  }

  Widget _buildDayOverview(
    BuildContext context,
    ParticipantEntryState entry,
    StudySessionState session,
  ) {
    final theme = Theme.of(context);
    final participant = entry.participant!;
    final schedule = entry.daySchedule!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(participant.participantCode,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${AppStrings.day} ${schedule.dayNumber}',
                      style: theme.textTheme.titleMedium),
                  if (entry.fromCache) ...[
                    const SizedBox(height: 8),
                    Text(AppStrings.offlineCacheNote,
                        style: theme.textTheme.bodySmall),
                  ],
                  if (entry.resumableDayId != null) ...[
                    const SizedBox(height: 8),
                    Text(AppStrings.resumeAvailable,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (entry.resumableDayId != null) ...[
            FilledButton(
              onPressed: () => ref
                  .read(sessionControllerProvider.notifier)
                  .resumeActiveSession(),
              child: Text('Resume Day ${schedule.dayNumber}'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.tonal(
            onPressed: entry.dayAlreadyCompleted
                ? null
                : () =>
                    ref.read(sessionControllerProvider.notifier).startDay(),
            child: Text('${AppStrings.startDay} ${schedule.dayNumber}'),
          ),
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              entry.errorMessage!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(participantEntryProvider.notifier).reset();
            },
            child: const Text(AppStrings.changeParticipant),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionView(BuildContext context, StudySessionState session) {
    final theme = Theme.of(context);
    final s = session.session!;
    final next = session.nextFireTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session active — Day ${s.dayNumber}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(s.participantCode, style: theme.textTheme.bodyMedium),
                  if (next != null) ...[
                    const SizedBox(height: 4),
                    _CountdownText(target: next),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please continue with your usual work. '
            'Health reminders may appear occasionally.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text(AppStrings.tutorialReportProblem),
            onPressed: () => showTechnicalProblemDialog(context),
          ),
          const SizedBox(height: 16),
          for (final event in session.events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('Reminder ${event.reminderNumber}',
                        style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    event.deliveryStatus.wireName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: event.deliveryStatus == DeliveryStatus.delivered
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    ParticipantEntryState entry,
    StudySessionState session,
  ) {
    final theme = Theme.of(context);
    final s = session.session;
    final dayNumber = s?.dayNumber ?? entry.daySchedule?.dayNumber ?? 1;
    final code = s?.participantCode ?? entry.participant?.participantCode ?? '';
    final links = s?.links ??
        entry.config?.links.resolvedWith(entry.participant!.questionnaireLinks);
    final store = ref.watch(localStoreProvider).asData?.value;
    final endLink = links?.endLinkForDay(dayNumber);
    final finalLink = dayNumber == 2 ? links?.finalLink : null;

    final dayId = 'day$dayNumber';
    final questionnaireDone =
        store?.isQuestionnaireCompleted(code, dayId) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayNumber == 1
                        ? AppStrings.sessionCompleteTitle
                        : AppStrings.studyCompleteTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber == 1
                        ? AppStrings.sessionCompleteBody
                        : AppStrings.studyCompleteBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${AppStrings.yourParticipantId} $code',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (endLink != null)
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text(AppStrings.openEndOfSessionQuestionnaire),
              onPressed: () => LinkLauncherService.open(
                QuestionnaireLinks.fill(
                  endLink,
                  participantId: code,
                  day: dayNumber,
                ),
              ),
            ),
          if (endLink == null)
            Text(
              'No questionnaire links are configured yet.',
              style: theme.textTheme.bodySmall,
            ),
          if (!questionnaireDone) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () async {
                final store = await ref.read(localStoreProvider.future);
                await store.setQuestionnaireCompleted(code, dayId);
                setState(() {});
              },
              child: const Text(AppStrings.endOfSessionDone),
            ),
          ],
          if (questionnaireDone && dayNumber == 1) ...[
            const SizedBox(height: 16),
            _buildStartDay2(theme, code),
          ],
          if (questionnaireDone && dayNumber == 2) ...[
            const SizedBox(height: 16),
            if (finalLink != null)
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text(AppStrings.openEndOfStudyQuestionnaire),
                onPressed: () => LinkLauncherService.open(
                  QuestionnaireLinks.fill(
                    finalLink,
                    participantId: code,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(participantEntryProvider.notifier).reset();
            },
            child: const Text(AppStrings.changeParticipant),
          ),
        ],
      ),
    );
  }

  Widget _buildStartDay2(ThemeData theme, String code) {
    final day2Activated = ref
            .watch(participantEntryProvider)
            .participant
            ?.activeDay ==
        2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text(AppStrings.startDay2),
          onPressed: day2Activated
              ? () async {
                  // Re-runs the entry flow: refetches the participant
                  // (now activeDay 2) and its day-2 schedule, landing on
                  // the Day 2 overview.
                  await ref
                      .read(participantEntryProvider.notifier)
                      .enterCode(code);
                }
              : null,
        ),
        if (!day2Activated) ...[
          const SizedBox(height: 8),
          Text(AppStrings.day2NotActivated, style: theme.textTheme.bodySmall),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Check again'),
            onPressed: () =>
                ref.read(participantEntryProvider.notifier).refreshParticipant(),
          ),
        ],
      ],
    );
  }
}

/// Self-contained per-second countdown to the next reminder.
class _CountdownText extends StatefulWidget {
  const _CountdownText({required this.target});

  final DateTime target;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.target.difference(DateTime.now());
    final theme = Theme.of(context);
    if (remaining.isNegative) {
      return Text('Reminder arriving…', style: theme.textTheme.bodySmall);
    }
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      'Next reminder in $minutes:$seconds',
      style: theme.textTheme.bodySmall,
    );
  }
}
