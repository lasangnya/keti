import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/services/firebase/auth_service.dart';

part 'app_mode_provider.g.dart';

enum AppMode { participant, admin }

@riverpod
class AppModeState extends _$AppModeState {
  @override
  AppMode build() => AppMode.participant;

  Future<void> setMode(AppMode mode) async {
    state = mode;
    
    // When switching to participant mode, ensure we have an anonymous session.
    // This handles the case where an admin just signed out.
    if (mode == AppMode.participant) {
      try {
        await AuthService().signInAnonymouslyIfNeeded();
      } catch (e) {
        debugPrint('AppModeState: Failed to re-trigger anonymous auth: $e');
      }
    }
  }
}
