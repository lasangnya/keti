// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Belt-and-braces CSV→Firestore reconciliation (plan §6.4).
///
/// When a session was started entirely offline the Firestore docs don't exist
/// — every event write went to the CSVs and the *remote* operations were
/// silently dropped. This runs on participant-code entry (and can run at any
/// time, since all writes are idempotent) to backfill missing Firestore
/// documents and push lifecycle updates.

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

/// Belt-and-braces CSV→Firestore reconciliation (plan §6.4).
///
/// When a session was started entirely offline the Firestore docs don't exist
/// — every event write went to the CSVs and the *remote* operations were
/// silently dropped. This runs on participant-code entry (and can run at any
/// time, since all writes are idempotent) to backfill missing Firestore
/// documents and push lifecycle updates.

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  /// Belt-and-braces CSV→Firestore reconciliation (plan §6.4).
  ///
  /// When a session was started entirely offline the Firestore docs don't exist
  /// — every event write went to the CSVs and the *remote* operations were
  /// silently dropped. This runs on participant-code entry (and can run at any
  /// time, since all writes are idempotent) to backfill missing Firestore
  /// documents and push lifecycle updates.
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'158cccd2958e1e8a126becf13c709d77f710a5dd';
