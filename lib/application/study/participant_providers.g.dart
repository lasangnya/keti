// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-side repository for participant/config/schedule documents.
///
/// Defaults to Firestore (real project or emulator, depending on
/// `USE_FIRESTORE_EMULATOR`); tests override with the in-memory mock.

@ProviderFor(participantRepository)
final participantRepositoryProvider = ParticipantRepositoryProvider._();

/// Read-side repository for participant/config/schedule documents.
///
/// Defaults to Firestore (real project or emulator, depending on
/// `USE_FIRESTORE_EMULATOR`); tests override with the in-memory mock.

final class ParticipantRepositoryProvider
    extends
        $FunctionalProvider<
          ParticipantRepository,
          ParticipantRepository,
          ParticipantRepository
        >
    with $Provider<ParticipantRepository> {
  /// Read-side repository for participant/config/schedule documents.
  ///
  /// Defaults to Firestore (real project or emulator, depending on
  /// `USE_FIRESTORE_EMULATOR`); tests override with the in-memory mock.
  ParticipantRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'participantRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$participantRepositoryHash();

  @$internal
  @override
  $ProviderElement<ParticipantRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ParticipantRepository create(Ref ref) {
    return participantRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ParticipantRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ParticipantRepository>(value),
    );
  }
}

String _$participantRepositoryHash() =>
    r'd3b0df6c1686e00f4190a3640ebddcd660647678';

@ProviderFor(localStore)
final localStoreProvider = LocalStoreProvider._();

final class LocalStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalStore>,
          LocalStore,
          FutureOr<LocalStore>
        >
    with $FutureModifier<LocalStore>, $FutureProvider<LocalStore> {
  LocalStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localStoreHash();

  @$internal
  @override
  $FutureProviderElement<LocalStore> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalStore> create(Ref ref) {
    return localStore(ref);
  }
}

String _$localStoreHash() => r'a2d740730a7796063ed188cffa3d689931d2e7ef';
