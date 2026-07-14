// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReminderManager)
final reminderManagerProvider = ReminderManagerProvider._();

final class ReminderManagerProvider
    extends $NotifierProvider<ReminderManager, void> {
  ReminderManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderManagerHash();

  @$internal
  @override
  ReminderManager create() => ReminderManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderManagerHash() => r'1683f774d85aef55385a4d6be815c08d3d9592d1';

abstract class _$ReminderManager extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
