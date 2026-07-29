// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Orchestrates a participant-day session (plan §5.2/§6.5):
/// session + event creation (CSV-first, then Firestore), the tick
/// scheduler, delivery, catch-up and resume after an app quit, and
/// day completion.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// Orchestrates a participant-day session (plan §5.2/§6.5):
/// session + event creation (CSV-first, then Firestore), the tick
/// scheduler, delivery, catch-up and resume after an app quit, and
/// day completion.
final class SessionControllerProvider
    extends $NotifierProvider<SessionController, StudySessionState> {
  /// Orchestrates a participant-day session (plan §5.2/§6.5):
  /// session + event creation (CSV-first, then Firestore), the tick
  /// scheduler, delivery, catch-up and resume after an app quit, and
  /// day completion.
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudySessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudySessionState>(value),
    );
  }
}

String _$sessionControllerHash() => r'145a0380cff73d8d83bdb99b63d0abce26d148aa';

/// Orchestrates a participant-day session (plan §5.2/§6.5):
/// session + event creation (CSV-first, then Firestore), the tick
/// scheduler, delivery, catch-up and resume after an app quit, and
/// day completion.

abstract class _$SessionController extends $Notifier<StudySessionState> {
  StudySessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StudySessionState, StudySessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StudySessionState, StudySessionState>,
              StudySessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
