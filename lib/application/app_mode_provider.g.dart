// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppModeState)
final appModeStateProvider = AppModeStateProvider._();

final class AppModeStateProvider
    extends $NotifierProvider<AppModeState, AppMode> {
  AppModeStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appModeStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appModeStateHash();

  @$internal
  @override
  AppModeState create() => AppModeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMode>(value),
    );
  }
}

String _$appModeStateHash() => r'79d05e594ada0e50263bdfc11f803bcb3bfc4ea5';

abstract class _$AppModeState extends $Notifier<AppMode> {
  AppMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppMode, AppMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppMode, AppMode>,
              AppMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
