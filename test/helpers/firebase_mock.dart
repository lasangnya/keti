import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart' as core_test;
import 'package:flutter_test/flutter_test.dart';

/// Boots the Firebase platform-interface mocks so widget/provider tests that
/// touch `FirebaseAuth.instance` or `FirebaseFirestore.instance` don't crash
/// with `[core/no-app]` (no platform app exists in the test harness).
///
/// The official `setupFirebaseCoreMocks()` registers a `[DEFAULT]` app with
/// placeholder options; `Firebase.initializeApp()` then resolves the same app
/// the production code receives via `Firebase.app()`. Auth is faked at the
/// platform-interface level (a signed-in anonymous user) so the Pigeon channel
/// is never invoked — under the widget-test FakeAsync clock an unhandled
/// channel call would hang forever. All Firestore data access in these tests
/// flows through faked repositories, so no real channel calls happen.
Future<void> initFirebaseForTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  core_test.setupFirebaseCoreMocks();
  await Firebase.initializeApp();
  FirebaseAuthPlatform.instance = _FakeFirebaseAuthPlatform();
}

class _FakeFirebaseAuthPlatform extends FirebaseAuthPlatform {
  _FakeFirebaseAuthPlatform() : super(appInstance: null);

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) =>
      this;

  @override
  UserPlatform? get currentUser => _fakeUser;

  @override
  set currentUser(UserPlatform? userPlatform) {}

  @override
  Future<UserCredentialPlatform> signInAnonymously() async =>
      _FakeUserCredentialPlatform(this, _fakeUser);

  @override
  Future<void> signOut() async {}

  @override
  Stream<UserPlatform?> authStateChanges() => const Stream.empty();
}

final _fakeUser = _FakeUserPlatform();

class _FakeUserCredentialPlatform extends UserCredentialPlatform {
  _FakeUserCredentialPlatform(FirebaseAuthPlatform auth, UserPlatform user)
      : super(auth: auth, user: user);
}

class _FakeUserPlatform extends UserPlatform {
  _FakeUserPlatform()
      : super(
          _FakeFirebaseAuthPlatform(),
          _FakeMultiFactorPlatform(),
          InternalUserDetails(
            userInfo: InternalUserInfo(
              uid: 'anonymous-test-uid',
              isAnonymous: true,
              isEmailVerified: false,
            ),
            providerData: const [],
          ),
        );
}

class _FakeMultiFactorPlatform extends MultiFactorPlatform {
  _FakeMultiFactorPlatform() : super(_FakeFirebaseAuthPlatform());
}
