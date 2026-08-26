// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_orchestrator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reminderOrchestrator)
final reminderOrchestratorProvider = ReminderOrchestratorProvider._();

final class ReminderOrchestratorProvider
    extends
        $FunctionalProvider<
          ReminderOrchestrator,
          ReminderOrchestrator,
          ReminderOrchestrator
        >
    with $Provider<ReminderOrchestrator> {
  ReminderOrchestratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderOrchestratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderOrchestratorHash();

  @$internal
  @override
  $ProviderElement<ReminderOrchestrator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReminderOrchestrator create(Ref ref) {
    return reminderOrchestrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderOrchestrator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderOrchestrator>(value),
    );
  }
}

String _$reminderOrchestratorHash() =>
    r'bdbddf38210b1091b596054ef464555507294153';
