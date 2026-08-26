// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_launcher_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(linkLauncherService)
final linkLauncherServiceProvider = LinkLauncherServiceProvider._();

final class LinkLauncherServiceProvider
    extends
        $FunctionalProvider<
          LinkLauncherService,
          LinkLauncherService,
          LinkLauncherService
        >
    with $Provider<LinkLauncherService> {
  LinkLauncherServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkLauncherServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkLauncherServiceHash();

  @$internal
  @override
  $ProviderElement<LinkLauncherService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LinkLauncherService create(Ref ref) {
    return linkLauncherService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkLauncherService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkLauncherService>(value),
    );
  }
}

String _$linkLauncherServiceHash() =>
    r'd9bd342b2c9338b9b43f404ec02df4db9d7c2dcb';
