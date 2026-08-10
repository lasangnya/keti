import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'admin_providers.dart';

part 'admin_auth_provider.g.dart';

enum AdminAuthStatus { signedOut, signingIn, signedIn, failed }

class AdminAuthState {
  const AdminAuthState({
    this.status = AdminAuthStatus.signedOut,
    this.email,
    this.errorMessage,
  });

  final AdminAuthStatus status;
  final String? email;
  final String? errorMessage;
}

@Riverpod(keepAlive: true)
class AdminAuth extends _$AdminAuth {
  @override
  AdminAuthState build() => const AdminAuthState();

  Future<void> signIn(String email, String password) async {
    state = const AdminAuthState(status: AdminAuthStatus.signingIn);
    try {
      final result =
          await ref.read(adminAuthServiceProvider).signIn(email, password);
      if (result.isAdmin) {
        state = AdminAuthState(
            status: AdminAuthStatus.signedIn, email: result.email);
      } else {
        await ref.read(adminAuthServiceProvider).signOut();
        state = const AdminAuthState(
          status: AdminAuthStatus.failed,
          errorMessage:
              'This account is not a study administrator (missing admin claim).',
        );
      }
    } catch (e) {
      state = AdminAuthState(
        status: AdminAuthStatus.failed,
        errorMessage: 'Sign-in failed. Check email and password. ($e)',
      );
    }
  }

  Future<void> signOut() async {
    await ref.read(adminAuthServiceProvider).signOut();
    state = const AdminAuthState();
  }
}
