import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/link_launcher_service.dart';

/// "Report a technical problem" dialog (design doc: Screen 7 + in-session).
///
/// Per the researcher's instruction this is contact-only: it shows who to
/// write to, with a button that opens the participant's mail client. No
/// report payload is collected in the app.
Future<void> showTechnicalProblemDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.technicalProblemTitle),
      content: const Text(AppStrings.technicalProblemBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.mail_outline, size: 16),
          label: const Text(AppStrings.technicalProblemMailto),
          onPressed: () {
            ProviderScope.containerOf(context)
                .read(linkLauncherServiceProvider)
                .open('mailto:lasan@uni-bremen.de');
          },
        ),
      ],
    ),
  );
}
