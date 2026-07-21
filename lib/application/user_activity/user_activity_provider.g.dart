// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserActivity)
final userActivityProvider = UserActivityProvider._();

final class UserActivityProvider
    extends $NotifierProvider<UserActivity, UserActivityState> {
  UserActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userActivityHash();

  @$internal
  @override
  UserActivity create() => UserActivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserActivityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserActivityState>(value),
    );
  }
}

String _$userActivityHash() => r'f8ead262b32e8ed951b317617eacf7e7a452030a';

abstract class _$UserActivity extends $Notifier<UserActivityState> {
  UserActivityState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserActivityState, UserActivityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserActivityState, UserActivityState>,
              UserActivityState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
