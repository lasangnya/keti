import 'package:firebase_auth/firebase_auth.dart';

class AdminSignInResult {
  const AdminSignInResult({required this.email, required this.isAdmin});

  final String email;
  final bool isAdmin;
}

/// Researcher authentication for the admin backend (plan §8): one
/// email/password account carrying the custom claim `admin: true`. The
/// participant app never touches this.
abstract class AdminAuthService {
  Future<AdminSignInResult> signIn(String email, String password);
  Future<void> signOut();
}

class FirebaseAdminAuthService implements AdminAuthService {
  FirebaseAdminAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<AdminSignInResult> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = credential.user!;
    // Force-refresh so a newly granted claim shows up immediately.
    final token = await user.getIdTokenResult(true);
    final isAdmin = token.claims?['admin'] == true;
    return AdminSignInResult(email: user.email ?? email.trim(), isAdmin: isAdmin);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
