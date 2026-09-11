import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/study_config_provider.dart';
import '../../../domain/study/scheduled_reminder.dart';
import '../../../domain/study/study_enums.dart';
import '../../../presentation/widgets/schedule_editor.dart';

/// Edits the global default schedule template (`config/study/defaultSchedule`).
/// The rows here are copied into every newly created participant's Day 1 and
/// Day 2 schedule documents via [AdminRepository.createParticipant].
class DefaultSchedulePage extends ConsumerStatefulWidget {
  const DefaultSchedulePage({super.key});

  @override
  ConsumerState<DefaultSchedulePage> createState() =>
      _DefaultSchedulePageState();
}

class _DefaultSchedulePageState extends ConsumerState<DefaultSchedulePage> {
  final List<ScheduleDraft> _rows = [];
  final VariantCeilings _ceilings = VariantCeilings();
  bool _loaded = false;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(adminStudyConfigProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Default schedule',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'These rows are copied into every new participant\'s Day 1 and '
            'Day 2 schedules when their record is created.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          configAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Failed to load schedule: $e'),
            data: (config) {
              if (!_loaded) {
                _load(config.defaultSchedule);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _rows.length; i++)
                    ScheduleRowEditor(
                      index: i,
                      draft: _rows[i],
                      ceilingFor: _ceilings.ceilingFor,
                      onAddVersion: _ceilings.addVersion,
                      onChanged: () => setState(() {}),
                      onRemove: _rows.length <= 1
                          ? null
                          : () => setState(() {
                                _rows[i].dispose();
                                _rows.removeAt(i);
                              }),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save default schedule'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add entry'),
                        onPressed: _addRow,
                      ),
                      TextButton(
                        onPressed: () => _load(kDefaultScheduleTemplate),
                        child: const Text('Reset to default template'),
                      ),
                    ],
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!_messageIsError) ...[
                          Icon(Icons.check_circle,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            _message!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _messageIsError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _load(List<ScheduledReminder> reminders) {
    for (final r in _rows) {
      r.dispose();
    }
    _rows
      ..clear()
      ..addAll([
        for (final r in reminders) ScheduleDraft.fromReminder(r),
      ]);
    _ceilings.seed(reminders);
    _loaded = true;
  }

  void _addRow() {
    final lastMinutes =
        _rows.isEmpty ? 0 : _rows.last.minutes ?? 0;
    setState(() {
      _rows.add(ScheduleDraft(
        offsetController:
            TextEditingController(text: '${lastMinutes + 10}'),
        placement: Placement.cursorProximate,
        kind: ReminderKind.hydration,
        variantNumber: 1,
      ));
    });
  }

  Future<void> _save() async {
    if (_rows.isEmpty) {
      setState(() {
        _message = 'Add at least one schedule entry.';
        _messageIsError = true;
      });
      return;
    }

    final updated = <ScheduledReminder>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final minutes = row.minutes;
      if (minutes == null || minutes < 0) {
        setState(() {
          _message = 'Invalid minute in row ${i + 1}.';
          _messageIsError = true;
        });
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

    setState(() {
      _saving = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await ref
          .read(adminStudyConfigProvider.notifier)
          .saveDefaultSchedule(updated);
      if (!mounted) return;
      setState(() {
        _message = 'Done — default schedule saved.';
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to save schedule: $e';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
