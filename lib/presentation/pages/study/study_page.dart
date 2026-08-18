import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/study/participant_entry_provider.dart';
import '../../../application/study/participant_providers.dart';
import '../../../application/study/session_controller.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/link_launcher_service.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_session.dart';
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
  bool _autoCheckedDay2 = false;

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(participantEntryProvider);
    final session = ref.watch(sessionControllerProvider);
    final store = ref.watch(localStoreProvider).asData?.value;

    final tutorialSeen = entry.participant != null &&
        (store?.isTutorialSeen(entry.participant!.participantCode) ?? false);

    // The tutorial wizard gets the "Guidelines" title; the day overview and
    // completion screens keep the "Study" heading.
    final showingTutorial = !entry.isReady ||
        (!tutorialSeen && !session.active && !session.completed);

    // Reset the auto-check flag whenever a new participant is entered, so
    // each day-1 completion screen triggers a fresh activation check.
    if (entry.participant == null) {
      _autoCheckedDay2 = false;
    }

    // When the day-1 completion screen shows, refresh the participant once
    // so the Start Day 2 button reflects a fresh researcher activation
    // without requiring a manual "Check again" tap. Manual re-checks are
    // still available via the "Check again" button.
    if (entry.dayAlreadyCompleted &&
        entry.daySchedule?.dayNumber == 1 &&
        !session.active &&
        !_autoCheckedDay2) {
      _autoCheckedDay2 = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(participantEntryProvider.notifier).refreshParticipant();
        }
      });
    }

    // The active-session screen is a standalone full-window layout (centered
    // status + Exit button), so it renders outside the shared page scaffold.
    if (session.active) return _buildSessionView(context, session);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(title: showingTutorial ? AppStrings.guidelines : AppStrings.study),
          if (!entry.isReady)
            ParticipantTutorial(onStartSession: _startSession)
          else if (!tutorialSeen && !session.active && !session.completed)
            ParticipantTutorial(onStartSession: _startSession)
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
            // No "Start" button while an unfinished session exists: starting
            // again would reuse the same event doc IDs in Firestore, which
            // the rules treat as an update and reject — leaving the old
            // session's data in Firestore mixed with the new one's. A
            // restart is only legitimate via a researcher reset.
          ] else
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

  /// Session-active screen: status, remaining-time countdown and the
  /// participant support route, centered in the window. The Exit button sits
  /// at the bottom-left; it records the exit request and terminates the app.
  Widget _buildSessionView(BuildContext context, StudySessionState session) {
    final theme = Theme.of(context);
    final s = session.session!;
    final end = _sessionEndTime(s);

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SESSION ${s.dayNumber} ACTIVE',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.sessionParticipantIdLabel}${s.participantCode}',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Please continue with your usual work.\n'
                  'Health reminders may appear occasionally.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text(AppStrings.tutorialReportProblem),
                  onPressed: () => showTechnicalProblemDialog(context),
                ),
                const SizedBox(height: 40),
                Text(
                  AppStrings.sessionActiveFor,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                if (end != null) _SessionCountdown(end: end),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: TextButton.icon(
            icon: const Icon(Icons.logout, size: 16),
            label: const Text(AppStrings.exitSession),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).requestExit(),
          ),
        ),
      ],
    );
  }

  /// When the session is expected to finish: the last reminder's fire time
  /// plus the full reminder → compliance-card sequence duration.
  DateTime? _sessionEndTime(StudySession s) {
    final reminders = s.schedule.reminders;
    if (reminders.isEmpty) return null;
    var lastOffset = reminders.first.offset;
    for (final r in reminders) {
      if (r.offset > lastOffset) lastOffset = r.offset;
    }
    return s.startedAtLocal.add(
      lastOffset +
          const Duration(
            milliseconds: AppConfig.reminderVisibilityMs +
                AppConfig.complianceCardDelayMs +
                AppConfig.complianceCardTimeoutMs,
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
    final links = s?.links ?? entry.links;
    final endLink = links?.endLinkForDay(dayNumber);
    final finalLink = dayNumber == 2 ? links?.finalLink : null;

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
          if (endLink != null) ...[
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(
                  'Open Session $dayNumber End-of-Session Questionnaire'),
              onPressed: () => LinkLauncherService.open(
                QuestionnaireLinks.fill(
                  endLink,
                  participantId: code,
                  day: dayNumber,
                ),
              ),
            ),
          ],
          if (endLink == null)
            Text(
              'No questionnaire links are configured yet.',
              style: theme.textTheme.bodySmall,
            ),
          if (dayNumber == 1) ...[
            const SizedBox(height: 16),
            _buildStartDay2(theme, code),
          ],
          if (dayNumber == 2 && finalLink != null) ...[
            const SizedBox(height: 16),
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
          // Always tappable: clicking re-checks activation and always gives
          // visible feedback (snackbar) instead of a silent no-op.
          onPressed: () async {
            debugPrint('Start Day 2 tapped');
            // Check activation FIRST. The finished day-1 session must not be
            // cleared unless day 2 actually loads — otherwise a not-activated
            // press wipes the only "day 1 completed" flag (session state) and
            // the page falls back to the day-1 overview/start flow.
            await ref
                .read(participantEntryProvider.notifier)
                .loadDay2();
            if (!mounted) return;
            // If loadDay2 could not proceed, tell the researcher why and
            // stay on the day-1 completion screen.
            final msg = ref.read(participantEntryProvider).errorMessage;
            debugPrint('Start Day 2 after load: errorMessage=$msg');
            if (msg != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
              return;
            }
            // Day 2 is loaded and ready: start it in one step — the session
            // controller's own guards (active session / resumable day) hold
            // at this point, so the intermediate day-2 overview is skipped.
            await ref.read(sessionControllerProvider.notifier).startDay();
          },
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

/// Live countdown of the remaining session time, in HH:MM:SS.
class _SessionCountdown extends StatefulWidget {
  const _SessionCountdown({required this.end});

  final DateTime end;

  @override
  State<_SessionCountdown> createState() => _SessionCountdownState();
}

class _SessionCountdownState extends State<_SessionCountdown> {
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
    final theme = Theme.of(context);
    final remaining = widget.end.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final h = clamped.inHours.toString().padLeft(2, '0');
    final m = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '$h:$m:$sec',
      style: theme.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: theme.colorScheme.primary,
      ),
    );
  }
}
