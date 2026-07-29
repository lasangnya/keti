// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_environment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active build environment (`dev` | `pilot` | `study`). Wrapped in a
/// provider so tests can override the `--dart-define` constant.

@ProviderFor(appEnvironment)
final appEnvironmentProvider = AppEnvironmentProvider._();

/// The active build environment (`dev` | `pilot` | `study`). Wrapped in a
/// provider so tests can override the `--dart-define` constant.

final class AppEnvironmentProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The active build environment (`dev` | `pilot` | `study`). Wrapped in a
  /// provider so tests can override the `--dart-define` constant.
  AppEnvironmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appEnvironmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appEnvironmentHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appEnvironment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appEnvironmentHash() => r'0791f87027204bd6a0ef187b6f51418a6b1d74ae';
