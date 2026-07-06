// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Navigation)
final navigationProvider = NavigationProvider._();

final class NavigationProvider extends $NotifierProvider<Navigation, int> {
  NavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationHash();

  @$internal
  @override
  Navigation create() => Navigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$navigationHash() => r'7be2554c21232507e9375980737504ab3d9f5a07';

abstract class _$Navigation extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
