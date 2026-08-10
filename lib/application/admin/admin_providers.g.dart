// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminAuthService)
final adminAuthServiceProvider = AdminAuthServiceProvider._();

final class AdminAuthServiceProvider
    extends
        $FunctionalProvider<
          AdminAuthService,
          AdminAuthService,
          AdminAuthService
        >
    with $Provider<AdminAuthService> {
  AdminAuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAuthServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAuthServiceHash();

  @$internal
  @override
  $ProviderElement<AdminAuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminAuthService create(Ref ref) {
    return adminAuthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminAuthService>(value),
    );
  }
}

String _$adminAuthServiceHash() => r'b93251f5d2423131e74df462ddad756d86c9283a';

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'342e0e3a0e35c4e6f80a0ac639c351223fa3d6ca';

@ProviderFor(adminExportService)
final adminExportServiceProvider = AdminExportServiceProvider._();

final class AdminExportServiceProvider
    extends
        $FunctionalProvider<
          AdminExportService,
          AdminExportService,
          AdminExportService
        >
    with $Provider<AdminExportService> {
  AdminExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminExportServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminExportServiceHash();

  @$internal
  @override
  $ProviderElement<AdminExportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminExportService create(Ref ref) {
    return adminExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminExportService>(value),
    );
  }
}

String _$adminExportServiceHash() =>
    r'2feebadbf583ba1db2c41855d39459e58f6c4a8a';
