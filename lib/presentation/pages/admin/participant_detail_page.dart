import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/admin_providers.dart';
import '../../../application/admin/participants_provider.dart';
import '../../../application/admin/study_config_provider.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/scheduled_reminder.dart';
import '../../../domain/study/study_enums.dart';
import '../../../domain/study/study_links.dart';
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
  /// Editable schedule rows, seeded from the fetched schedule (or the
  /// 8-entry template when none exists). Rows can be added/removed freely;
  /// [ScheduledReminder.reminderNumber] is renumbered 1..N on save.
  final List<_ScheduleRow> _rows = [];
  bool _scheduleWasSaved = false;
  int _scheduleDay = 1;
  String? _message;

  // Links editor state (per-participant on/off switches).
  late bool _preStudyOn;
  late bool _endOfDay1On;
  late bool _endOfDay2On;
  late bool _finalOn;
  bool _linksLoaded = false;
  bool _linksSaving = false;
  String? _linksDoneMessage;

  @override
  void dispose() {
    for (final r in _rows) {
      r.offsetController.dispose();
    }
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
            // Reset buttons are always available — even when a day has no
            // session yet (e.g. after a previous reset), so the researcher
            // can always re-align the active-day gate.
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Day 1'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
              onPressed: () => _confirmReset(context, 1),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Day 2'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
              onPressed: () => _confirmReset(context, 2),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Reset participant'),
              style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError),
              onPressed: () => _confirmResetParticipant(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmResetParticipant(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset participant?'),
        content: const Text(
            'This deletes BOTH days from Firestore and wipes ALL data for '
            'this participant on the device: sessions, reminders, the '
            'tutorial flag and cached documents. The same participant code '
            'will start over as a completely fresh participant. This cannot '
            'be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset everything',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(adminParticipantsProvider.notifier)
          .resetParticipant(widget.participantCode);
      // Stale exports must not outlive the reset.
      await ref
          .read(adminExportServiceProvider)
          .deleteParticipantExports(widget.participantCode);
      ref.invalidate(participantDetailProvider(widget.participantCode));
      if (!mounted) return;
      setState(() => _message = 'Participant reset — starts fresh on next '
          'code entry.');
    }
  }

  Future<void> _confirmReset(BuildContext context, int day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Day $day?'),
        content: Text(
            'This will delete Day $day from Firestore and trigger a local '
            'wipe on the participant\'s device next time they enter their '
            'code. This cannot be undone.'),
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
          .resetDay(widget.participantCode, day);
      ref.invalidate(participantDetailProvider(widget.participantCode));
      setState(() => _message = 'Day $day reset signal sent.');
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
    if (!_linksLoaded) _loadLinks(participant.linkFlags);
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
              'Choose which questionnaires this participant is offered. '
              'End-of-day type follows the day\'s presentation style '
              '(ambient → type 1, character → type 2) and therefore '
              'alternates between the two days automatically.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Pre-study questionnaire'),
              value: _preStudyOn,
              onChanged: _linksSaving
                  ? null
                  : (v) => setState(() => _preStudyOn = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: const Text('End-of-day questionnaire — Day 1'),
              subtitle: Text(
                  '${participant.styleOrder == StyleOrder.ambientFirst ? 'Ambient (type 1)' : 'Character (type 2)'} day'),
              value: _endOfDay1On,
              onChanged: _linksSaving
                  ? null
                  : (v) => setState(() => _endOfDay1On = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: const Text('End-of-day questionnaire — Day 2'),
              subtitle: Text(
                  '${participant.styleOrder == StyleOrder.ambientFirst ? 'Character (type 2)' : 'Ambient (type 1)'} day'),
              value: _endOfDay2On,
              onChanged: _linksSaving
                  ? null
                  : (v) => setState(() => _endOfDay2On = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Final questionnaire'),
              value: _finalOn,
              onChanged: _linksSaving
                  ? null
                  : (v) => setState(() => _finalOn = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _linksSaving
                      ? null
                      : () => _saveLinks(participant.participantCode),
                  child: _linksSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save links'),
                ),
              ],
            ),
            if (_linksDoneMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _linksDoneMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _loadLinks(ParticipantLinkFlags flags) {
    _preStudyOn = flags.preStudy;
    _endOfDay1On = flags.endOfDay1;
    _endOfDay2On = flags.endOfDay2;
    _finalOn = flags.finalQuestionnaire;
    _linksLoaded = true;
  }

  Future<void> _saveLinks(String participantCode) async {
    setState(() {
      _linksSaving = true;
      _linksDoneMessage = null;
    });
    try {
      await ref.read(adminParticipantsProvider.notifier).saveParticipantLinkFlags(
            participantCode,
            ParticipantLinkFlags(
              preStudy: _preStudyOn,
              endOfDay1: _endOfDay1On,
              endOfDay2: _endOfDay2On,
              finalQuestionnaire: _finalOn,
            ),
          );
      if (!mounted) return;
      ref.invalidate(participantDetailProvider(participantCode));
      setState(() {
        _linksDoneMessage = 'Done — links saved for $participantCode.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _linksDoneMessage = 'Failed to save links: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _linksSaving = false);
      }
    }
  }

  Widget _buildScheduleCard(ThemeData theme) {
    final scheduleAsync = ref.watch(
        participantScheduleProvider(widget.participantCode, _scheduleDay));

    // Seed/refresh the editable rows and saved flag once the schedule for the
    // current (participant, day) resolves. Guarded so a template reset or an
    // in-progress edit is not clobbered by a late value for a stale day.
    ref.listen(
        participantScheduleProvider(widget.participantCode, _scheduleDay),
        (previous, next) {
      final data = next.value;
      if (data == null) return;
      if (_loadedDay == _scheduleDay &&
          _loadedCode == widget.participantCode) {
        return;
      }
      _loadRows(data.reminders);
      _scheduleWasSaved = data.saved;
    });

    final data = scheduleAsync.value;
    final showLoading = data == null &&
        (_rows.isEmpty ||
            _loadedDay != _scheduleDay ||
            _loadedCode != widget.participantCode);

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
            if (showLoading)
              const Text('Loading schedule…')
            else ...[
              if (scheduleAsync.hasError)
                Text('Failed to load schedule: ${scheduleAsync.error}',
                    style: theme.textTheme.bodySmall),
              if (!_scheduleWasSaved) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No saved schedule for Day $_scheduleDay yet — '
                    'this participant cannot start it. '
                    'Press "Save schedule" to create it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              for (var i = 0; i < _rows.length; i++)
                _buildScheduleRow(theme, i),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => _saveSchedule(),
                    child: const Text('Save schedule'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add entry'),
                    onPressed: _addRow,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _loadRows(kDefaultScheduleTemplate),
                    child: const Text('Reset to template'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(ThemeData theme, int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('No. ${index + 1}')),
          SizedBox(
            width: 110,
            child: TextField(
              controller: row.offsetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Minute',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<Placement>(
            value: row.placement,
            items: [
              for (final p in Placement.values)
                DropdownMenuItem(value: p, child: Text(p.wireName)),
            ],
            onChanged: (p) => setState(() => row.placement = p!),
          ),
          const SizedBox(width: 12),
          DropdownButton<ReminderKind>(
            value: row.kind,
            items: [
              for (final k in ReminderKind.values)
                DropdownMenuItem(value: k, child: Text(k.wireName)),
            ],
            onChanged: (k) {
              setState(() {
                row.kind = k!;
                row.variantNumber = row.variantNumber.clamp(
                    1, maxVariantFor(k)).toInt();
              });
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: row.variantNumber,
            items: [
              for (var v = 1; v <= maxVariantFor(row.kind); v++)
                DropdownMenuItem(value: v, child: Text('v$v')),
            ],
            onChanged: (v) => setState(() => row.variantNumber = v!),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remove entry',
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            onPressed: _rows.length <= 1
                ? null
                : () => setState(() {
                      row.offsetController.dispose();
                      _rows.removeAt(index);
                    }),
          ),
        ],
      ),
    );
  }

  int? _loadedDay;
  String? _loadedCode;

  void _loadRows(List<ScheduledReminder> reminders) {
    for (final r in _rows) {
      r.offsetController.dispose();
    }
    _rows
      ..clear()
      ..addAll([
        for (final r in reminders)
          _ScheduleRow(
            offsetController:
                TextEditingController(text: '${r.offset.inMinutes}'),
            placement: r.placement,
            kind: r.kind,
            variantNumber: r.variantNumber,
          ),
      ]);
    _loadedDay = _scheduleDay;
    _loadedCode = widget.participantCode;
  }

  void _addRow() {
    final lastMinutes = _rows.isEmpty
        ? 0
        : int.tryParse(_rows.last.offsetController.text.trim()) ?? 0;
    setState(() {
      _rows.add(_ScheduleRow(
        offsetController:
            TextEditingController(text: '${lastMinutes + 10}'),
        placement: Placement.cursorProximate,
        kind: ReminderKind.hydration,
        variantNumber: 1,
      ));
    });
  }

  Future<void> _saveSchedule() async {
    if (_rows.isEmpty) {
      setState(() => _message = 'Add at least one schedule entry.');
      return;
    }
    final updated = <ScheduledReminder>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final minutes = int.tryParse(row.offsetController.text.trim());
      if (minutes == null || minutes < 0) {
        setState(() => _message = 'Invalid minute in row ${i + 1}.');
        return;
      }
      updated.add(ScheduledReminder(
        reminderNumber: i + 1,
        offset: Duration(minutes: minutes),
        placement: row.placement,
        kind: row.kind,
        variantNumber: row.variantNumber,
      ));
    }
    await ref.read(adminParticipantsProvider.notifier).saveSchedule(
        widget.participantCode, _scheduleDay, updated);
    ref.invalidate(participantDetailProvider(widget.participantCode));
    ref.invalidate(
        participantScheduleProvider(widget.participantCode, _scheduleDay));
    setState(() {
      _scheduleWasSaved = true;
      _message =
          'Schedule saved for day $_scheduleDay (${updated.length} entries).';
    });
  }
}

/// Max content-variant counter per kind (hydration 1–5, micro break 1–3).
int maxVariantFor(ReminderKind kind) =>
    kind == ReminderKind.hydration ? 5 : 3;

/// One editable schedule row in the admin editor.
class _ScheduleRow {
  _ScheduleRow({
    required this.offsetController,
    required this.placement,
    required this.kind,
    required this.variantNumber,
  });

  final TextEditingController offsetController;
  Placement placement;
  ReminderKind kind;
  int variantNumber;
}
