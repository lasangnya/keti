// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_entry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive: this controller performs async work (fetch + cache) on behalf
/// of the whole page; autoDispose could tear it down mid-flight and strand
/// the UI in its loading state.

@ProviderFor(ParticipantEntry)
final participantEntryProvider = ParticipantEntryProvider._();

/// Keep-alive: this controller performs async work (fetch + cache) on behalf
/// of the whole page; autoDispose could tear it down mid-flight and strand
/// the UI in its loading state.
final class ParticipantEntryProvider
    extends $NotifierProvider<ParticipantEntry, ParticipantEntryState> {
  /// Keep-alive: this controller performs async work (fetch + cache) on behalf
  /// of the whole page; autoDispose could tear it down mid-flight and strand
  /// the UI in its loading state.
  ParticipantEntryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'participantEntryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$participantEntryHash();

  @$internal
  @override
  ParticipantEntry create() => ParticipantEntry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ParticipantEntryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ParticipantEntryState>(value),
    );
  }
}

String _$participantEntryHash() => r'367ee19205f2a6de5ad26c45755899f867397226';

/// Keep-alive: this controller performs async work (fetch + cache) on behalf
/// of the whole page; autoDispose could tear it down mid-flight and strand
/// the UI in its loading state.

abstract class _$ParticipantEntry extends $Notifier<ParticipantEntryState> {
  ParticipantEntryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ParticipantEntryState, ParticipantEntryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ParticipantEntryState, ParticipantEntryState>,
              ParticipantEntryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
