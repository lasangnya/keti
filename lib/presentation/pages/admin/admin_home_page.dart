import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/admin_auth_provider.dart';
import '../../../application/app_mode_provider.dart';
import 'links_settings_page.dart';
import 'participants_page.dart';

/// Admin shell: participants management and questionnaire-link settings.
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _index = 0;

  static const _pages = [ParticipantsPage(), LinksSettingsPage()];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group),
                  label: Text('Participants'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.link_outlined),
                  selectedIcon: Icon(Icons.link),
                  label: Text('Links'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextButton.icon(
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(auth.email ?? 'Sign out',
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () async {
                        await ref.read(adminAuthProvider.notifier).signOut();
                        await ref
                            .read(appModeStateProvider.notifier)
                            .setMode(AppMode.participant);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      ),
    );
  }
}
