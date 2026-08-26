// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default [CsvStore] instance. Lives here in the data layer so core services
/// (e.g. [SyncService]) can depend on it without reaching up into application.

@ProviderFor(csvStore)
final csvStoreProvider = CsvStoreProvider._();

/// Default [CsvStore] instance. Lives here in the data layer so core services
/// (e.g. [SyncService]) can depend on it without reaching up into application.

final class CsvStoreProvider
    extends $FunctionalProvider<CsvStore, CsvStore, CsvStore>
    with $Provider<CsvStore> {
  /// Default [CsvStore] instance. Lives here in the data layer so core services
  /// (e.g. [SyncService]) can depend on it without reaching up into application.
  CsvStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$csvStoreHash();

  @$internal
  @override
  $ProviderElement<CsvStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CsvStore create(Ref ref) {
    return csvStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CsvStore>(value),
    );
  }
}

String _$csvStoreHash() => r'6e5bd585eb4832200cc23fad95da0f3f530f4914';
