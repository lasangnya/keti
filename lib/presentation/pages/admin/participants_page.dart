import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/participants_provider.dart';
import '../../../application/admin/study_config_provider.dart';
import '../../../domain/study/condition_assignment.dart';
import '../../../domain/study/study_enums.dart';
import 'participant_detail_page.dart';

/// Participants list + creation form (plan §3.1).
class ParticipantsPage extends ConsumerStatefulWidget {
  const ParticipantsPage({super.key});

  @override
  ConsumerState<ParticipantsPage> createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends ConsumerState<ParticipantsPage> {
  final _serialController = TextEditingController();
  StyleOrder? _overrideOrder;
  String? _error;

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participants = ref.watch(adminParticipantsProvider);
    final export = ref.watch(adminExportProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Participants',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export all'),
                onPressed: export.busy
                    ? null
                    : () => ref.read(adminExportProvider.notifier).exportAll(),
              ),
              TextButton.icon(
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Reveal exports'),
                onPressed: () =>
                    ref.read(adminExportProvider.notifier).reveal(),
              ),
            ],
          ),
          if (export.lastMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child:
                  Text(export.lastMessage!, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 16),
          _buildCreateCard(theme),
          const SizedBox(height: 24),
          participants.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Failed to load participants: $e'),
            data: (list) => Column(
              children: [
                for (final p in list)
                  Card(
                    child: ListTile(
                      title: Text(p.participantCode),
                      subtitle: Text(
                        '${p.styleOrder.wireName} · active day ${p.activeDay}'
                        '${p.assignmentOverride ? ' · override' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParticipantDetailPage(
                              participantCode: p.participantCode),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCard(ThemeData theme) {
    final serial = int.tryParse(_serialController.text.trim());
    final computedOrder =
        serial != null && serial > 0 ? styleOrderForSerial(serial) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New participant',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _serialController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Serial',
                      hintText: 'e.g. 14',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(width: 16),
                if (serial != null && serial > 0)
                  Text(
                    'P${serial.toString().padLeft(3, '0')} → '
                    '${computedOrder!.wireName}',
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<StyleOrder?>(
                  value: _overrideOrder,
                  hint: const Text('Order override (optional)'),
                  items: [
                    const DropdownMenuItem<StyleOrder?>(
                      value: null,
                      child: Text('Use parity (no override)'),
                    ),
                    ...StyleOrder.values.map(
                      (order) => DropdownMenuItem<StyleOrder?>(
                        value: order,
                        child: Text(order.wireName),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _overrideOrder = value),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: (serial == null || serial <= 0) ? null : _create,
                  child: const Text('Create participant'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final serial = int.parse(_serialController.text.trim());
    final order = _overrideOrder ?? styleOrderForSerial(serial);
    try {
      await ref.read(adminParticipantsProvider.notifier).createParticipant(
            serial: serial,
            styleOrder: order,
            assignmentOverride: _overrideOrder != null,
          );
      setState(() {
        _serialController.clear();
        _overrideOrder = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }
}
