import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/admin/admin_auth_provider.dart';
import 'admin_home_page.dart';
import 'admin_login_page.dart';

/// Entry point of the admin build: gates the backend behind researcher auth.
class AdminRootPage extends ConsumerWidget {
  const AdminRootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    return auth.status == AdminAuthStatus.signedIn
        ? const AdminHomePage()
        : const AdminLoginPage();
  }
}
