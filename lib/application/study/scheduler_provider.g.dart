// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injectable wall clock — overridden with a fake in tests.

@ProviderFor(studyClock)
final studyClockProvider = StudyClockProvider._();

/// Injectable wall clock — overridden with a fake in tests.

final class StudyClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Injectable wall clock — overridden with a fake in tests.
  StudyClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studyClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studyClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return studyClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$studyClockHash() => r'f7fb6b48d713c2074388a2e8bc2ed4ab195b019a';

/// How often the scheduler evaluates. Overridden in tests so the real timer
/// never fires; tests drive [StudyScheduler.tickOnce] manually.

@ProviderFor(schedulerTickInterval)
final schedulerTickIntervalProvider = SchedulerTickIntervalProvider._();

/// How often the scheduler evaluates. Overridden in tests so the real timer
/// never fires; tests drive [StudyScheduler.tickOnce] manually.

final class SchedulerTickIntervalProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How often the scheduler evaluates. Overridden in tests so the real timer
  /// never fires; tests drive [StudyScheduler.tickOnce] manually.
  SchedulerTickIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schedulerTickIntervalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schedulerTickIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return schedulerTickInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$schedulerTickIntervalHash() =>
    r'9f8f34c7ce36c66631c54cb572a3fdfa3ff5d192';

/// Factory provider — each consumer gets a fresh scheduler instance.

@ProviderFor(studyScheduler)
final studySchedulerProvider = StudySchedulerFamily._();

/// Factory provider — each consumer gets a fresh scheduler instance.

final class StudySchedulerProvider
    extends $FunctionalProvider<StudyScheduler, StudyScheduler, StudyScheduler>
    with $Provider<StudyScheduler> {
  /// Factory provider — each consumer gets a fresh scheduler instance.
  StudySchedulerProvider._({
    required StudySchedulerFamily super.from,
    required Future<void> Function(List<ScheduleDecision> decisions)
    super.argument,
  }) : super(
         retry: null,
         name: r'studySchedulerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studySchedulerHash();

  @override
  String toString() {
    return r'studySchedulerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<StudyScheduler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StudyScheduler create(Ref ref) {
    final argument =
        this.argument
            as Future<void> Function(List<ScheduleDecision> decisions);
    return studyScheduler(ref, onDecisions: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudyScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudyScheduler>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudySchedulerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studySchedulerHash() => r'dc443c05380fb5eb43ed3d5793648b1a37ed597d';

/// Factory provider — each consumer gets a fresh scheduler instance.

final class StudySchedulerFamily extends $Family
    with
        $FunctionalFamilyOverride<
          StudyScheduler,
          Future<void> Function(List<ScheduleDecision> decisions)
        > {
  StudySchedulerFamily._()
    : super(
        retry: null,
        name: r'studySchedulerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Factory provider — each consumer gets a fresh scheduler instance.

  StudySchedulerProvider call({
    required Future<void> Function(List<ScheduleDecision> decisions)
    onDecisions,
  }) => StudySchedulerProvider._(argument: onDecisions, from: this);

  @override
  String toString() => r'studySchedulerProvider';
}
