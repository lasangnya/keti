import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/study_config_provider.dart';
import '../../../core/services/link_launcher_service.dart';
import '../../../domain/study/study_config.dart';

/// Questionnaire link templates (plan §3.1/§3.5): start, end-of-day-1,
/// end-of-day-2, final. Templates must contain `{participantId}`; `{day}` is
/// substituted where present.
class LinksSettingsPage extends ConsumerStatefulWidget {
  const LinksSettingsPage({super.key});

  @override
  ConsumerState<LinksSettingsPage> createState() => _LinksSettingsPageState();
}

class _LinksSettingsPageState extends ConsumerState<LinksSettingsPage> {
  final _start = TextEditingController();
  final _day1End = TextEditingController();
  final _day2End = TextEditingController();
  final _final = TextEditingController();
  bool _loaded = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    for (final c in [_start, _day1End, _day2End, _final]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(adminStudyConfigProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Questionnaire links',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Google Forms templates. {participantId} and {day} are substituted when opened.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          config.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Failed to load config: $e'),
            data: (c) {
              if (!_loaded) _load(c.links);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _linkField(theme, 'Pre-study questionnaire (start)', _start, 1),
                  _linkField(theme, 'End of Day 1 questionnaire', _day1End, 1),
                  _linkField(theme, 'End of Day 2 questionnaire', _day2End, 2),
                  _linkField(theme, 'Final questionnaire', _final, 2),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save links'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _messageIsError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
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

  Widget _linkField(
      ThemeData theme, String label, TextEditingController controller, int day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Open test link',
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: () {
              final template = controller.text.trim();
              if (template.isEmpty) return;
              LinkLauncherService.open(QuestionnaireLinks.fill(
                template,
                participantId: 'P000',
                day: day,
              ));
            },
          ),
        ],
      ),
    );
  }

  void _load(QuestionnaireLinks links) {
    _start.text = links.start ?? '';
    _day1End.text = links.day1End ?? '';
    _day2End.text = links.day2End ?? '';
    _final.text = links.finalLink ?? '';
    _loaded = true;
  }

  Future<void> _save() async {
    for (final (label, controller) in [
      ('start', _start),
      ('day 1 end', _day1End),
      ('day 2 end', _day2End),
      ('final', _final),
    ]) {
      final value = controller.text.trim();
      if (value.isNotEmpty && !value.contains('{participantId}')) {
        setState(() {
          _message = 'The $label link is missing {participantId}.';
          _messageIsError = true;
        });
        return;
      }
    }
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    await ref.read(adminStudyConfigProvider.notifier).saveLinks(
          QuestionnaireLinks(
            start: orNull(_start),
            day1End: orNull(_day1End),
            day2End: orNull(_day2End),
            finalLink: orNull(_final),
          ),
        );
    setState(() {
      _message = 'Links saved.';
      _messageIsError = false;
    });
  }
}
