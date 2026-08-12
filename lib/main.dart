import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/theme/theme_provider.dart';
import 'package:keti/core/constants/app_config.dart';
import 'package:keti/core/services/firebase/auth_service.dart';
import 'package:keti/core/services/researcher_launcher.dart';
import 'package:keti/firebase_options.dart';
import 'package:keti/presentation/pages/admin/admin_root_page.dart';
import 'package:keti/presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (AppConfig.useFirebaseEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
  // Silent anonymous sign-in — participants never see a login screen.
  try {
    await AuthService().signInAnonymouslyIfNeeded();
  } catch (e) {
    debugPrint('Firebase Auth Error: $e');
    // We continue so the app still launches, but Firestore may fail if rules require auth.
  }
  // Log what this process received, so the researcher-launch path is
  // diagnosable without guessing.
  _logLaunchMode();
  runApp(const ProviderScope(child: KetiApp()));
}

void _logLaunchMode() {
  final env = Platform.environment['KETI_RESEARCHER'];
  final args = Platform.executableArguments;
  debugPrint('[launch-mode] executableArguments=$args');
  debugPrint('[launch-mode] KETI_RESEARCHER env=$env');
  debugPrint('[launch-mode] markerPath=${ResearcherLauncher.markerPath}');
  debugPrint('[launch-mode] isResearcherWindow='
      '${ResearcherLauncher.isResearcherWindow}');
}

class KetiApp extends ConsumerWidget {
  const KetiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      // A second instance launched with the KETI_RESEARCHER flag (from the
      // participant app's "Researcher Access" button) boots straight into
      // the admin console — participant and researcher run in parallel.
      home: ResearcherLauncher.isResearcherWindow
          ? const AdminRootPage()
          : const KetiHomePage(),
    );
  }
}
