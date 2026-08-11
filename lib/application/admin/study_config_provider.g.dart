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
///
/// Watched by the Links page, so the notifier stays alive and
/// [AdminLinkTemplates.save] can safely invalidate itself after the await.

@ProviderFor(AdminLinkTemplates)
final adminLinkTemplatesProvider = AdminLinkTemplatesProvider._();

/// The global questionnaire link templates (`links/templates`).
///
/// Watched by the Links page, so the notifier stays alive and
/// [AdminLinkTemplates.save] can safely invalidate itself after the await.
final class AdminLinkTemplatesProvider
    extends $AsyncNotifierProvider<AdminLinkTemplates, StudyLinkTemplates> {
  /// The global questionnaire link templates (`links/templates`).
  ///
  /// Watched by the Links page, so the notifier stays alive and
  /// [AdminLinkTemplates.save] can safely invalidate itself after the await.
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
  AdminLinkTemplates create() => AdminLinkTemplates();
}

String _$adminLinkTemplatesHash() =>
    r'a27cf668ccd667ebb083a6a871b63ec8fb174ec2';

/// The global questionnaire link templates (`links/templates`).
///
/// Watched by the Links page, so the notifier stays alive and
/// [AdminLinkTemplates.save] can safely invalidate itself after the await.

abstract class _$AdminLinkTemplates extends $AsyncNotifier<StudyLinkTemplates> {
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
