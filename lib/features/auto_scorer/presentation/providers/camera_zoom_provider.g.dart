// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_zoom_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted camera zoom for the auto-scorer aim preview (#393 setup flow). A
/// higher zoom enlarges the board in the letterboxed model input → finer cal /
/// tip localisation. Persisted so the user doesn't re-zoom every game; the aim
/// view writes back here via [set] on slider release. Mirrors
/// [AutoScorerCalConfidence].

@ProviderFor(AutoScorerCameraZoom)
final autoScorerCameraZoomProvider = AutoScorerCameraZoomProvider._();

/// Persisted camera zoom for the auto-scorer aim preview (#393 setup flow). A
/// higher zoom enlarges the board in the letterboxed model input → finer cal /
/// tip localisation. Persisted so the user doesn't re-zoom every game; the aim
/// view writes back here via [set] on slider release. Mirrors
/// [AutoScorerCalConfidence].
final class AutoScorerCameraZoomProvider
    extends $AsyncNotifierProvider<AutoScorerCameraZoom, double> {
  /// Persisted camera zoom for the auto-scorer aim preview (#393 setup flow). A
  /// higher zoom enlarges the board in the letterboxed model input → finer cal /
  /// tip localisation. Persisted so the user doesn't re-zoom every game; the aim
  /// view writes back here via [set] on slider release. Mirrors
  /// [AutoScorerCalConfidence].
  AutoScorerCameraZoomProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerCameraZoomProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerCameraZoomHash();

  @$internal
  @override
  AutoScorerCameraZoom create() => AutoScorerCameraZoom();
}

String _$autoScorerCameraZoomHash() =>
    r'e8b1788c11c1df2954be85cd4219e83abdb3dea9';

/// Persisted camera zoom for the auto-scorer aim preview (#393 setup flow). A
/// higher zoom enlarges the board in the letterboxed model input → finer cal /
/// tip localisation. Persisted so the user doesn't re-zoom every game; the aim
/// view writes back here via [set] on slider release. Mirrors
/// [AutoScorerCalConfidence].

abstract class _$AutoScorerCameraZoom extends $AsyncNotifier<double> {
  FutureOr<double> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double>, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double>, double>,
              AsyncValue<double>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
