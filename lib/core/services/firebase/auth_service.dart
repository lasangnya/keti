import 'package:firebase_auth/firebase_auth.dart';

/// Silent anonymous authentication for the participant app (plan §8).
///
/// The participant never sees a login screen: the app signs in anonymously
/// at launch so Firestore rules have a real principal. No identity is
/// collected — the uid is never linked to a person.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The current anonymous uid, or null before sign-in completes.
  String? get uid => _auth.currentUser?.uid;

  /// Signs in anonymously unless a session already exists. Idempotent and
  /// safe to call on every launch. The app uses in-memory persistence so
  /// macOS sandbox never touches the Keychain (plan §8: auth is disposable
  /// — participants sign in fresh every launch).
  Future<void> signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser != null) return;
    await _auth.setPersistence(Persistence.NONE);
    await _auth.signInAnonymously();
  }
}
