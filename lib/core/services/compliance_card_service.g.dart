// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compliance_card_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(complianceCardService)
final complianceCardServiceProvider = ComplianceCardServiceProvider._();

final class ComplianceCardServiceProvider
    extends
        $FunctionalProvider<
          ComplianceCardService,
          ComplianceCardService,
          ComplianceCardService
        >
    with $Provider<ComplianceCardService> {
  ComplianceCardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'complianceCardServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$complianceCardServiceHash();

  @$internal
  @override
  $ProviderElement<ComplianceCardService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ComplianceCardService create(Ref ref) {
    return complianceCardService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComplianceCardService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComplianceCardService>(value),
    );
  }
}

String _$complianceCardServiceHash() =>
    r'd33b72060fed771d2a51358a6c25fbefbda8d534';
