// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TestMode)
final testModeProvider = TestModeProvider._();

final class TestModeProvider
    extends $NotifierProvider<TestMode, TestModeState> {
  TestModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testModeHash();

  @$internal
  @override
  TestMode create() => TestMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TestModeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TestModeState>(value),
    );
  }
}

String _$testModeHash() => r'26c50c202efffc33b7e908bef5001b905b6e4313';

abstract class _$TestMode extends $Notifier<TestModeState> {
  TestModeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TestModeState, TestModeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TestModeState, TestModeState>,
              TestModeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
