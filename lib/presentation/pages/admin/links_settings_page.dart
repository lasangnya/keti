import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/study_config_provider.dart';
import '../../../core/services/link_launcher_service.dart';
import '../../../domain/study/study_links.dart';

/// Questionnaire link templates (plan §3.1/§3.5), stored globally in
/// `links/templates`: pre-study, end-of-day type 1 (ambient days),
/// end-of-day type 2 (character days), final. Templates must contain
/// `{participantId}`; `{day}` is substituted where present.
class LinksSettingsPage extends ConsumerStatefulWidget {
  const LinksSettingsPage({super.key});

  @override
  ConsumerState<LinksSettingsPage> createState() => _LinksSettingsPageState();
}

class _LinksSettingsPageState extends ConsumerState<LinksSettingsPage> {
  final _preStudy = TextEditingController();
  final _endOfDayType1 = TextEditingController();
  final _endOfDayType2 = TextEditingController();
  final _final = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    for (final c in [_preStudy, _endOfDayType1, _endOfDayType2, _final]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(adminLinkTemplatesProvider);
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
            'Google Forms templates. {participantId} and {day} are substituted when opened. '
            'End-of-day type 1 is used on ambient days, type 2 on character days.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          templates.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Failed to load templates: $e'),
            data: (t) {
              if (!_loaded) _load(t);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _linkField(theme, 'Pre-study questionnaire', _preStudy),
                  _linkField(
                      theme, 'End-of-day questionnaire (Ambient days)', _endOfDayType1),
                  _linkField(theme,
                      'End-of-day questionnaire (Character days)', _endOfDayType2),
                  _linkField(theme, 'Final questionnaire', _final),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save links'),
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

  Widget _linkField(
      ThemeData theme, String label, TextEditingController controller) {
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
              ref.read(linkLauncherServiceProvider).open(StudyLinkTemplates.fill(
                template,
                participantId: 'P000',
              ));
            },
          ),
        ],
      ),
    );
  }

  void _load(StudyLinkTemplates templates) {
    _preStudy.text = templates.preStudy ?? '';
    _endOfDayType1.text = templates.endOfDayType1 ?? '';
    _endOfDayType2.text = templates.endOfDayType2 ?? '';
    _final.text = templates.finalLink ?? '';
    _loaded = true;
  }

  Future<void> _save() async {
    for (final (label, controller) in [
      ('pre-study', _preStudy),
      ('end-of-day type 1', _endOfDayType1),
      ('end-of-day type 2', _endOfDayType2),
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

    setState(() {
      _saving = true;
      _message = null;
      _messageIsError = false;
    });
    try {
      await ref.read(adminLinkTemplatesProvider.notifier).save(
            StudyLinkTemplates(
              preStudy: orNull(_preStudy),
              endOfDayType1: orNull(_endOfDayType1),
              endOfDayType2: orNull(_endOfDayType2),
              finalLink: orNull(_final),
            ),
          );
      if (!mounted) return;
      setState(() {
        _message = 'Done — link templates saved.';
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to save links: $e';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
