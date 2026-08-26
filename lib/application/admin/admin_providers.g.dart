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

@ProviderFor(participantSchedule)
final participantScheduleProvider = ParticipantScheduleFamily._();

final class ParticipantScheduleProvider
    extends
        $FunctionalProvider<
          AsyncValue<({List<ScheduledReminder> reminders, bool saved})>,
          ({List<ScheduledReminder> reminders, bool saved}),
          FutureOr<({List<ScheduledReminder> reminders, bool saved})>
        >
    with
        $FutureModifier<({List<ScheduledReminder> reminders, bool saved})>,
        $FutureProvider<({List<ScheduledReminder> reminders, bool saved})> {
  ParticipantScheduleProvider._({
    required ParticipantScheduleFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'participantScheduleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$participantScheduleHash();

  @override
  String toString() {
    return r'participantScheduleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<({List<ScheduledReminder> reminders, bool saved})>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({List<ScheduledReminder> reminders, bool saved})> create(Ref ref) {
    final argument = this.argument as (String, int);
    return participantSchedule(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ParticipantScheduleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$participantScheduleHash() =>
    r'dfba7b7e6653075b6deb8c9540d60a9f8f94fbc6';

final class ParticipantScheduleFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<({List<ScheduledReminder> reminders, bool saved})>,
          (String, int)
        > {
  ParticipantScheduleFamily._()
    : super(
        retry: null,
        name: r'participantScheduleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ParticipantScheduleProvider call(String participantCode, int dayNumber) =>
      ParticipantScheduleProvider._(
        argument: (participantCode, dayNumber),
        from: this,
      );

  @override
  String toString() => r'participantScheduleProvider';
}
