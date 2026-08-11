// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminStudyConfig)
final adminStudyConfigProvider = AdminStudyConfigProvider._();

final class AdminStudyConfigProvider
    extends $AsyncNotifierProvider<AdminStudyConfig, StudyConfig> {
  AdminStudyConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminStudyConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminStudyConfigHash();

  @$internal
  @override
  AdminStudyConfig create() => AdminStudyConfig();
}

String _$adminStudyConfigHash() => r'428969f3e9467d66a53953625b000d9804f37d26';

abstract class _$AdminStudyConfig extends $AsyncNotifier<StudyConfig> {
  FutureOr<StudyConfig> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StudyConfig>, StudyConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StudyConfig>, StudyConfig>,
              AsyncValue<StudyConfig>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The global questionnaire link templates (`links/templates`).

@ProviderFor(adminLinkTemplates)
final adminLinkTemplatesProvider = AdminLinkTemplatesProvider._();

/// The global questionnaire link templates (`links/templates`).

final class AdminLinkTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<StudyLinkTemplates>,
          StudyLinkTemplates,
          FutureOr<StudyLinkTemplates>
        >
    with
        $FutureModifier<StudyLinkTemplates>,
        $FutureProvider<StudyLinkTemplates> {
  /// The global questionnaire link templates (`links/templates`).
  AdminLinkTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminLinkTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminLinkTemplatesHash();

  @$internal
  @override
  $FutureProviderElement<StudyLinkTemplates> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StudyLinkTemplates> create(Ref ref) {
    return adminLinkTemplates(ref);
  }
}

String _$adminLinkTemplatesHash() =>
    r'fe08a3e4793f9b95be914961f48dd2d1cc1514a3';

@ProviderFor(AdminLinkTemplatesEditor)
final adminLinkTemplatesEditorProvider = AdminLinkTemplatesEditorProvider._();

final class AdminLinkTemplatesEditorProvider
    extends
        $AsyncNotifierProvider<AdminLinkTemplatesEditor, StudyLinkTemplates> {
  AdminLinkTemplatesEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminLinkTemplatesEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminLinkTemplatesEditorHash();

  @$internal
  @override
  AdminLinkTemplatesEditor create() => AdminLinkTemplatesEditor();
}

String _$adminLinkTemplatesEditorHash() =>
    r'64dd23af613cc966610a56987e8f2a57af5aeb6b';

abstract class _$AdminLinkTemplatesEditor
    extends $AsyncNotifier<StudyLinkTemplates> {
  FutureOr<StudyLinkTemplates> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<StudyLinkTemplates>, StudyLinkTemplates>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StudyLinkTemplates>, StudyLinkTemplates>,
              AsyncValue<StudyLinkTemplates>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AdminExport)
final adminExportProvider = AdminExportProvider._();

final class AdminExportProvider
    extends $NotifierProvider<AdminExport, AdminExportState> {
  AdminExportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminExportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminExportHash();

  @$internal
  @override
  AdminExport create() => AdminExport();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminExportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminExportState>(value),
    );
  }
}

String _$adminExportHash() => r'a5a1a01cfde4428726499b878c4ff32d718bb658';

abstract class _$AdminExport extends $Notifier<AdminExportState> {
  AdminExportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminExportState, AdminExportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminExportState, AdminExportState>,
              AdminExportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
