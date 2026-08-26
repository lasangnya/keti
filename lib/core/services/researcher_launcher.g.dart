// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'researcher_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(researcherLauncher)
final researcherLauncherProvider = ResearcherLauncherProvider._();

final class ResearcherLauncherProvider
    extends
        $FunctionalProvider<
          ResearcherLauncher,
          ResearcherLauncher,
          ResearcherLauncher
        >
    with $Provider<ResearcherLauncher> {
  ResearcherLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'researcherLauncherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$researcherLauncherHash();

  @$internal
  @override
  $ProviderElement<ResearcherLauncher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResearcherLauncher create(Ref ref) {
    return researcherLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResearcherLauncher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResearcherLauncher>(value),
    );
  }
}

String _$researcherLauncherHash() =>
    r'5320aab2f08171eb6c8dceb10a1a59f9087d4334';
