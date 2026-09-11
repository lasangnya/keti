import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/study/scheduled_reminder.dart';
import '../../domain/study/study_enums.dart';

/// Sentinel value in the variant dropdown that triggers "+ Add version".
const int _addVersionSentinel = -1;

/// Per-kind variant ceilings for one schedule editor session. Seeded from the
/// reminders being edited so versions added in a previous save stay
/// selectable after a reload.
class VariantCeilings {
  final Map<ReminderKind, int> _byKind = {};

  void seed(Iterable<ScheduledReminder> reminders) {
    final highest = highestVariantByKind(reminders);
    _byKind
      ..clear()
      ..addEntries([
        for (final k in ReminderKind.values)
          MapEntry(k, variantCeilingFor(k, highestUsed: highest[k] ?? 0)),
      ]);
  }

  int ceilingFor(ReminderKind kind) =>
      _byKind[kind] ?? baseVariantCountFor(kind);

  /// Extends [kind]'s version list by one and returns the new ceiling.
  int addVersion(ReminderKind kind) {
    final next = ceilingFor(kind) + 1;
    _byKind[kind] = next;
    return next;
  }
}

/// One editable schedule row shared by the admin schedule editors. The parent
/// owns the list of drafts and rebuilds via [ScheduleRowEditor.onChanged].
class ScheduleDraft {
  ScheduleDraft({
    required this.offsetController,
    required this.placement,
    required this.kind,
    required this.variantNumber,
  });

  factory ScheduleDraft.fromReminder(ScheduledReminder reminder) =>
      ScheduleDraft(
        offsetController:
            TextEditingController(text: '${reminder.offset.inMinutes}'),
        placement: reminder.placement,
        kind: reminder.kind,
        variantNumber: reminder.variantNumber,
      );

  final TextEditingController offsetController;
  Placement placement;
  ReminderKind kind;
  int variantNumber;

  int? get minutes => int.tryParse(offsetController.text.trim());

  void dispose() => offsetController.dispose();
}

/// Renders one editable schedule row: minute offset, placement, kind, variant
/// and a remove button. Stateless — it mutates the passed [draft] and calls
/// [onChanged] so the owning page can `setState`.
class ScheduleRowEditor extends StatelessWidget {
  const ScheduleRowEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.ceilingFor,
    required this.onAddVersion,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final ScheduleDraft draft;

  /// Current max selectable version for a kind (see [VariantCeilings]).
  final int Function(ReminderKind kind) ceilingFor;

  /// Extends [kind]'s version list and returns the new max version.
  final int Function(ReminderKind kind) onAddVersion;

  final VoidCallback onChanged;

  /// Null disables the remove button (e.g. the last remaining row).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    // Wrap (not Row): fixed-width controls must be allowed to flow onto a
    // second line on narrow admin panes instead of overflowing.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 90, child: Text('No. ${index + 1}')),
          SizedBox(
            width: 110,
            child: TextField(
              controller: draft.offsetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Minute',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          DropdownButton<Placement>(
            value: draft.placement,
            items: [
              for (final p in Placement.values)
                DropdownMenuItem(value: p, child: Text(p.wireName)),
            ],
            onChanged: (p) {
              if (p == null) return;
              draft.placement = p;
              onChanged();
            },
          ),
          DropdownButton<ReminderKind>(
            value: draft.kind,
            items: [
              for (final k in ReminderKind.values)
                DropdownMenuItem(value: k, child: Text(k.wireName)),
            ],
            onChanged: (k) {
              if (k == null) return;
              draft.kind = k;
              draft.variantNumber =
                  draft.variantNumber.clamp(1, ceilingFor(k)).toInt();
              onChanged();
            },
          ),
          DropdownButton<int>(
            value: draft.variantNumber,
            items: [
              for (var v = 1; v <= ceilingFor(draft.kind); v++)
                DropdownMenuItem(value: v, child: Text('v$v')),
              const DropdownMenuItem(
                value: _addVersionSentinel,
                child: Text('+ Add version'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              if (v == _addVersionSentinel) {
                draft.variantNumber = onAddVersion(draft.kind);
              } else {
                draft.variantNumber = v;
              }
              onChanged();
            },
          ),
          IconButton(
            tooltip: 'Remove entry',
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
