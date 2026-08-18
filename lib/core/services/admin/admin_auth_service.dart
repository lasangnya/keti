import 'dart:convert';

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
    final isAdmin = _isAdmin(token);
    return AdminSignInResult(email: user.email ?? email.trim(), isAdmin: isAdmin);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Reads the `admin` custom claim from the ID token.
  ///
  /// On Windows the Firebase C++ SDK's `getIdTokenResult` does not populate
  /// `IdTokenResult.claims` (it only returns the raw token), so fall back to
  /// decoding the JWT payload — the custom claim is embedded there.
  static bool _isAdmin(IdTokenResult result) {
    final claims = result.claims;
    if (claims != null && claims.isNotEmpty) {
      return claims['admin'] == true;
    }
    final token = result.token;
    if (token == null || token.isEmpty) return false;
    return _decodeJwtClaims(token)['admin'] == true;
  }

  /// Decodes the payload of a JWT (base64url) without verifying the signature.
  /// Used only to read custom claims client-side; trust comes from the token
  /// having been issued by Firebase Auth.
  static Map<String, dynamic> _decodeJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const {};
      final payload = parts[1];
      final padded = payload.padRight(((payload.length + 3) ~/ 4) * 4, '=');
      final bytes = base64Url.decode(padded);
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}
