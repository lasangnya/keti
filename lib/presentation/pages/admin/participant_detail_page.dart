import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/admin_providers.dart';
import '../../../application/admin/participants_provider.dart';
import '../../../application/admin/study_config_provider.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/scheduled_reminder.dart';
import '../../../domain/study/study_config.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_session.dart';

/// Per-participant admin: status per day, Activate Day 2, style-order edit
/// (soft-locked once Day 1 started), schedule editor, CSV download.
class ParticipantDetailPage extends ConsumerStatefulWidget {
  const ParticipantDetailPage({super.key, required this.participantCode});

  final String participantCode;

  @override
  ConsumerState<ParticipantDetailPage> createState() =>
      _ParticipantDetailPageState();
}

class _ParticipantDetailPageState
    extends ConsumerState<ParticipantDetailPage> {
  late List<TextEditingController> _offsetControllers;
  late List<Placement> _placements;
  int _scheduleDay = 1;
  bool _scheduleLoaded = false;
  String? _message;

  // Links editor state.
  final _startController = TextEditingController();
  final _day1EndController = TextEditingController();
  final _day2EndController = TextEditingController();
  final _finalController = TextEditingController();
  bool _linksLoaded = false;

  @override
  void initState() {
    super.initState();
    _offsetControllers = [
      for (var i = 0; i < 8; i++) TextEditingController(),
    ];
    _placements = [for (final r in kDefaultScheduleTemplate) r.placement];
  }

  @override
  void dispose() {
    for (final c in _offsetControllers) {
      c.dispose();
    }
    _startController.dispose();
    _day1EndController.dispose();
    _day2EndController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(participantDetailProvider(widget.participantCode));
    final participants = ref.watch(adminParticipantsProvider);
    final export = ref.watch(adminExportProvider);
    final theme = Theme.of(context);

    final participant = (participants.asData?.value ?? <Participant>[])
        .where((p) => p.participantCode == widget.participantCode)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(widget.participantCode)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (participant != null)
              _buildStatusCard(theme, participant, detail),
            const SizedBox(height: 16),
            if (participant != null)
              _buildOrderCard(theme, participant, detail),
            const SizedBox(height: 16),
            if (participant != null) _buildLinksCard(theme, participant),
            const SizedBox(height: 16),
            _buildScheduleCard(theme),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download CSV'),
                  onPressed: export.busy
                      ? null
                      : () => ref
                          .read(adminExportProvider.notifier)
                          .exportParticipant(widget.participantCode),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(adminExportProvider.notifier).reveal(),
                  child: const Text('Reveal exports'),
                ),
              ],
            ),
            if (export.lastMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(export.lastMessage!,
                    style: theme.textTheme.bodySmall),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message!, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, Participant participant,
      AsyncValue<ParticipantDetail> detail) {
    final safe = detail.asData?.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Style order: ${participant.styleOrder.wireName}'
                '${participant.assignmentOverride ? ' (override)' : ''}'),
            Text('Active day: ${participant.activeDay}'),
            const SizedBox(height: 8),
            detail.when(
              loading: () => const Text('Loading sessions…'),
              error: (e, _) => Text('Sessions failed to load: $e'),
              data: (d) {
                final day1 = d.sessions[0];
                final day2 = d.sessions[1];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, session) in [day1, day2].indexed)
                      Text(
                        'Day ${i + 1}: ${session?.status.wireName ?? 'NOT STARTED'}'
                        '${session == null ? '' : ' · ${d.eventCounts['day${i + 1}']!['total']} events'
                            ' · ${d.eventCounts['day${i + 1}']!['completedOutcome']} completed'}',
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed:                       participant.activeDay == 1 &&
                      safe?.sessions[0]?.status ==
                          StudySessionStatus.completed
                  ? () async {
                      await ref
                          .read(adminParticipantsProvider.notifier)
                          .setActiveDay(widget.participantCode, 2);
                      ref.invalidate(
                          participantDetailProvider(widget.participantCode));
                      setState(() => _message = 'Day 2 activated.');
                    }
                  : null,
              child: const Text('Activate Day 2'),
            ),
            const SizedBox(height: 12),
            if (safe?.sessions[0] != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Day 1'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                onPressed: () => _confirmReset(context),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Day 1?'),
        content: const Text(
            'This will delete Day 1 from Firestore and trigger a local wipe '
            'on the participant\'s device next time they enter their code. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(adminParticipantsProvider.notifier)
          .resetDay1(widget.participantCode);
      ref.invalidate(participantDetailProvider(widget.participantCode));
      setState(() => _message = 'Day 1 reset signal sent.');
    }
  }

  Widget _buildOrderCard(ThemeData theme, Participant participant,
      AsyncValue<ParticipantDetail> detail) {
    final safeDetail = detail.asData?.value;
    final day1Started = safeDetail != null && safeDetail.sessions[0] != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Style order',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<StyleOrder>(
                  value: participant.styleOrder,
                  items: [
                    for (final order in StyleOrder.values)
                      DropdownMenuItem(
                          value: order, child: Text(order.wireName)),
                  ],
                  onChanged: day1Started
                      ? null
                      : (order) async {
                          if (order == null) return;
                          await ref
                              .read(adminParticipantsProvider.notifier)
                              .setStyleOrder(widget.participantCode, order,
                                  assignmentOverride: true);
                          setState(() =>
                              _message = 'Style order updated (override).');
                        },
                ),
                const SizedBox(width: 12),
                if (day1Started)
                  Text('Locked — Day 1 already started',
                      style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksCard(ThemeData theme, Participant participant) {
    final config = ref.watch(adminStudyConfigProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Questionnaire links',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Override shared config links for this participant. '
              'Leave empty to fall back to shared config.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            config.when(
              loading: () => const Text('Loading shared config…'),
              error: (e, _) => Text('Failed to load config: $e'),
              data: (c) {
                if (!_linksLoaded) {
                  _loadLinks(participant.questionnaireLinks);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _linkField(theme, 'Pre-study (start)', _startController,
                        c.links.start, 1),
                    _linkField(theme, 'End of Day 1', _day1EndController,
                        c.links.day1End, 1),
                    _linkField(theme, 'End of Day 2', _day2EndController,
                        c.links.day2End, 2),
                    _linkField(theme, 'Final', _finalController,
                        c.links.finalLink, 2),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () =>
                              _saveLinks(participant.participantCode),
                          child: const Text('Save links'),
                        ),
                        const SizedBox(width: 8),
                        if (participant.questionnaireLinks != null)
                          OutlinedButton(
                            onPressed: () => _clearLinks(
                                participant.participantCode),
                            child: const Text('Clear custom links'),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    String? sharedValue,
    int day,
  ) {
    final helperText = controller.text.isEmpty && sharedValue != null
        ? 'Falls back to shared: $sharedValue'
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _loadLinks(QuestionnaireLinks? override) {
    _startController.text = override?.start ?? '';
    _day1EndController.text = override?.day1End ?? '';
    _day2EndController.text = override?.day2End ?? '';
    _finalController.text = override?.finalLink ?? '';
    _linksLoaded = true;
  }

  Future<void> _saveLinks(String participantCode) async {
    for (final (label, controller) in [
      ('start', _startController),
      ('day 1 end', _day1EndController),
      ('day 2 end', _day2EndController),
      ('final', _finalController),
    ]) {
      final value = controller.text.trim();
      if (value.isNotEmpty && !value.contains('{participantId}')) {
        setState(() {
          _message = 'The $label link is missing {participantId}.';
        });
        return;
      }
    }
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    await ref.read(adminParticipantsProvider.notifier).saveParticipantQuestionnaireLinks(
          participantCode,
          QuestionnaireLinks(
            start: orNull(_startController),
            day1End: orNull(_day1EndController),
            day2End: orNull(_day2EndController),
            finalLink: orNull(_finalController),
          ),
        );
    ref.invalidate(participantDetailProvider(participantCode));
    setState(() {
      _message = 'Links saved.';
    });
  }

  Future<void> _clearLinks(String participantCode) async {
    await ref
        .read(adminParticipantsProvider.notifier)
        .saveParticipantQuestionnaireLinks(participantCode, null);
    ref.invalidate(participantDetailProvider(participantCode));
    setState(() {
      _linksLoaded = false;
      _message = 'Custom links cleared — falls back to shared config.';
    });
  }

  Widget _buildScheduleCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Schedule',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Day 1')),
                    ButtonSegment(value: 2, label: Text('Day 2')),
                  ],
                  selected: {_scheduleDay},
                  onSelectionChanged: (s) =>
                      setState(() => _scheduleDay = s.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ScheduledReminder>>(
              future: ref
                  .read(adminRepositoryProvider)
                  .getSchedule(widget.participantCode, _scheduleDay),
              builder: (context, snapshot) {
                final reminders = snapshot.data;
                if (reminders == null) {
                  return const Text('Loading schedule…');
                }
                if (!_scheduleLoaded ||
                    _loadedDay != _scheduleDay ||
                    _loadedCode != widget.participantCode) {
                  _loadRows(reminders);
                }
                return Column(
                  children: [
                    for (var i = 0; i < reminders.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 90,
                                child: Text('No. ${reminders[i].reminderNumber}')),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _offsetControllers[i],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Minute',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<Placement>(
                              value: _placements[i],
                              items: [
                                for (final p in Placement.values)
                                  DropdownMenuItem(
                                      value: p, child: Text(p.wireName)),
                              ],
                              onChanged: (p) =>
                                  setState(() => _placements[i] = p!),
                            ),
                            const SizedBox(width: 12),
                            Text(reminders[i].contentVariantId,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => _saveSchedule(reminders),
                          child: const Text('Save schedule'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              _loadRows(kDefaultScheduleTemplate),
                          child: const Text('Reset to template'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int? _loadedDay;
  String? _loadedCode;

  void _loadRows(List<ScheduledReminder> reminders) {
    for (var i = 0; i < reminders.length; i++) {
      _offsetControllers[i].text = '${reminders[i].offset.inMinutes}';
      _placements[i] = reminders[i].placement;
    }
    _scheduleLoaded = true;
    _loadedDay = _scheduleDay;
    _loadedCode = widget.participantCode;
  }

  Future<void> _saveSchedule(List<ScheduledReminder> current) async {
    final updated = <ScheduledReminder>[];
    for (var i = 0; i < current.length; i++) {
      final minutes = int.tryParse(_offsetControllers[i].text.trim());
      if (minutes == null || minutes < 0) {
        setState(() => _message = 'Invalid minute in row ${i + 1}.');
        return;
      }
      updated.add(ScheduledReminder(
        reminderNumber: current[i].reminderNumber,
        offset: Duration(minutes: minutes),
        placement: _placements[i],
        kind: current[i].kind,
        variantNumber: current[i].variantNumber,
      ));
    }
    await ref.read(adminParticipantsProvider.notifier).saveSchedule(
        widget.participantCode, _scheduleDay, updated);
    ref.invalidate(participantDetailProvider(widget.participantCode));
    setState(() => _message = 'Schedule saved for day $_scheduleDay.');
  }
}
