// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participants_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Participant list with admin actions. Refresh after each mutation.

@ProviderFor(AdminParticipants)
final adminParticipantsProvider = AdminParticipantsProvider._();

/// Participant list with admin actions. Refresh after each mutation.
final class AdminParticipantsProvider
    extends $AsyncNotifierProvider<AdminParticipants, List<Participant>> {
  /// Participant list with admin actions. Refresh after each mutation.
  AdminParticipantsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminParticipantsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminParticipantsHash();

  @$internal
  @override
  AdminParticipants create() => AdminParticipants();
}

String _$adminParticipantsHash() => r'00884553053dd25c99fa0f92b2ed355a8dbd234a';

/// Participant list with admin actions. Refresh after each mutation.

abstract class _$AdminParticipants extends $AsyncNotifier<List<Participant>> {
  FutureOr<List<Participant>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Participant>>, List<Participant>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Participant>>, List<Participant>>,
              AsyncValue<List<Participant>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(participantDetail)
final participantDetailProvider = ParticipantDetailFamily._();

final class ParticipantDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ParticipantDetail>,
          ParticipantDetail,
          FutureOr<ParticipantDetail>
        >
    with
        $FutureModifier<ParticipantDetail>,
        $FutureProvider<ParticipantDetail> {
  ParticipantDetailProvider._({
    required ParticipantDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'participantDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$participantDetailHash();

  @override
  String toString() {
    return r'participantDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ParticipantDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ParticipantDetail> create(Ref ref) {
    final argument = this.argument as String;
    return participantDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ParticipantDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$participantDetailHash() => r'8eed44b2e3fb29ad0b896451c23c8e0e18837457';

final class ParticipantDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ParticipantDetail>, String> {
  ParticipantDetailFamily._()
    : super(
        retry: null,
        name: r'participantDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ParticipantDetailProvider call(String code) =>
      ParticipantDetailProvider._(argument: code, from: this);

  @override
  String toString() => r'participantDetailProvider';
}
