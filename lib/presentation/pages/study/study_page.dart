import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/study/participant_entry_provider.dart';
import '../../../application/study/participant_providers.dart';
import '../../../application/study/session_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/study/study_enums.dart';
import '../../widgets/page_title.dart';

/// Home of the participant build (plan §3.2): enter the participant code,
/// load the day's schedule from the (currently mocked) backend, and land on
/// the day-start overview. Session start and questionnaire buttons are wired
/// in later milestones.
class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  final _codeController = TextEditingController();
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _prefillLastCode();
  }

  Future<void> _prefillLastCode() async {
    final store = await ref.read(localStoreProvider.future);
    final last = store.lastParticipantCode;
    if (!mounted || _prefilled || last == null) return;
    setState(() {
      _codeController.text = last;
      _prefilled = true;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(participantEntryProvider);
    final session = ref.watch(sessionControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(title: AppStrings.study),
          if (!entry.isReady) _buildEntryForm(context, entry),
          if (entry.isReady && !session.active && !session.completed)
            _buildDayOverview(context, entry, session),
          if (session.active) _buildSessionView(context, session),
          if (session.completed) _buildCompletedView(context, session),
        ],
      ),
    );
  }

  Widget _buildEntryForm(BuildContext context, ParticipantEntryState entry) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.startStudySession,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.participantCode,
                hintText: AppStrings.participantCodeHint,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: entry.isLoading ? null : _submit,
            child: entry.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.continueLabel),
          ),
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              entry.errorMessage!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
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
                    Text(
                      'Next reminder at ${TimeOfDay.fromDateTime(next).format(context)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _buildCompletedView(BuildContext context, StudySessionState session) {
    final theme = Theme.of(context);
    final s = session.session!;
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
                  Text('Day ${s.dayNumber} complete',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Thank you! The questionnaire link appears here in a '
                      'later milestone (M6).'),
                ],
              ),
            ),
          ),
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

  void _submit() {
    ref.read(participantEntryProvider.notifier).enterCode(_codeController.text);
  }
}
