// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sidebar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Sidebar)
final sidebarProvider = SidebarProvider._();

final class SidebarProvider extends $NotifierProvider<Sidebar, bool> {
  SidebarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarHash();

  @$internal
  @override
  Sidebar create() => Sidebar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sidebarHash() => r'e4a4a27d1c489c6eb3e898153debc05fb2b07ead';

abstract class _$Sidebar extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
