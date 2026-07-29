// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminAuth)
final adminAuthProvider = AdminAuthProvider._();

final class AdminAuthProvider
    extends $NotifierProvider<AdminAuth, AdminAuthState> {
  AdminAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAuthHash();

  @$internal
  @override
  AdminAuth create() => AdminAuth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminAuthState>(value),
    );
  }
}

String _$adminAuthHash() => r'19e1724a568de4e973734796e23863b0e2f7e99b';

abstract class _$AdminAuth extends $Notifier<AdminAuthState> {
  AdminAuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminAuthState, AdminAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminAuthState, AdminAuthState>,
              AdminAuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
